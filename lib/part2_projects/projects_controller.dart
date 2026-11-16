import 'dart:async';
import 'package:flutter/foundation.dart';
import 'projects_api.dart';
import 'projects_state.dart';

class ProjectsController extends ChangeNotifier {
  final ProjectsApi _api;

  ProjectsState _state = const ProjectsState();
  ProjectsState get state => _state;

  int _generationToken = 0;
  bool _isDisposed = false;

  ProjectsController({ProjectsApi? api}) : _api = api ?? ProjectsApi();

  void setForceFailNext(bool value) {
    _api.forceFailNext = value;
    notifyListeners();
  }

  bool? get forceFailNext => _api.forceFailNext;

  Future<void> loadInitial() async {
    final token = ++_generationToken;
    _state = _state.copyWith(
      status: ListStatus.initialLoading,
      items: const [],
      clearLoadMoreError: true,
      hasReachedEnd: false,
      nextPage: 0,
      generationToken: token,
    );
    _safeNotify();

    try {
      final items = await _api.fetchProjects(0);

      if (token != _generationToken || _isDisposed) return;

      if (items.isEmpty) {
        _state = _state.copyWith(
          status: ListStatus.empty,
          items: const [],
          hasReachedEnd: true,
          nextPage: 1,
        );
      } else {
        final reachedEnd = items.length < 20;
        _state = _state.copyWith(
          status: ListStatus.ready,
          items: items,
          hasReachedEnd: reachedEnd,
          nextPage: 1,
        );
      }
    } catch (e) {
      if (token != _generationToken || _isDisposed) return;
      _state = _state.copyWith(
        status: ListStatus.initialError,
      );
    }
    _safeNotify();
  }

  Future<void> loadMore() async {
    if (_state.isLoadingMore ||
        _state.hasReachedEnd ||
        _state.status != ListStatus.ready ||
        _state.loadMoreError != null) {
      return;
    }

    final token = _generationToken;
    final pageToLoad = _state.nextPage;

    _state = _state.copyWith(
      isLoadingMore: true,
      clearLoadMoreError: true,
    );
    _safeNotify();

    try {
      final newItems = await _api.fetchProjects(pageToLoad);

      if (token != _generationToken || _isDisposed) return;

      if (newItems.isEmpty || newItems.length < 20) {
        final existingIds = _state.items.map((p) => p.id).toSet();
        final uniqueNew = newItems.where((p) => !existingIds.contains(p.id));

        _state = _state.copyWith(
          items: [..._state.items, ...uniqueNew],
          isLoadingMore: false,
          hasReachedEnd: true,
          nextPage: pageToLoad + 1,
        );
      } else {
        final existingIds = _state.items.map((p) => p.id).toSet();
        final uniqueNew = newItems.where((p) => !existingIds.contains(p.id));

        _state = _state.copyWith(
          items: [..._state.items, ...uniqueNew],
          isLoadingMore: false,
          hasReachedEnd: false,
          nextPage: pageToLoad + 1,
        );
      }
    } catch (e) {
      if (token != _generationToken || _isDisposed) return;

      _state = _state.copyWith(
        isLoadingMore: false,
        loadMoreError: e,
      );
    }
    _safeNotify();
  }

  Future<void> retryLoadMore() async {
    if (_state.loadMoreError == null) return;
    _state = _state.copyWith(clearLoadMoreError: true);
    _safeNotify();
    await loadMore();
  }

  Future<void> refresh() async {
    final token = ++_generationToken;

    try {
      final freshItems = await _api.fetchProjects(0);

      if (token != _generationToken || _isDisposed) return;

      if (freshItems.isEmpty) {
        _state = _state.copyWith(
          status: ListStatus.empty,
          items: const [],
          hasReachedEnd: true,
          nextPage: 1,
          clearLoadMoreError: true,
          generationToken: token,
        );
      } else {
        _state = _state.copyWith(
          status: ListStatus.ready,
          items: freshItems,
          hasReachedEnd: freshItems.length < 20,
          nextPage: 1,
          clearLoadMoreError: true,
          generationToken: token,
        );
      }
    } catch (e) {
      if (token != _generationToken || _isDisposed) return;
      if (_state.items.isEmpty) {
        _state = _state.copyWith(status: ListStatus.initialError);
      }
    }
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
