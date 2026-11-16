import 'dart:async';
import 'package:flutter/foundation.dart';
import 'projects_api.dart';
import 'projects_state.dart';

/// Controller encapsulating infinite-scroll pagination, race safety, error recovery,
/// and de-duplication. Pure Dart, decoupled from Flutter UI for fast unit tests.
class ProjectsController extends ChangeNotifier {
  final ProjectsApi _api;

  ProjectsState _state = const ProjectsState();
  ProjectsState get state => _state;

  int _generationToken = 0;
  bool _isDisposed = false;

  ProjectsController({ProjectsApi? api}) : _api = api ?? ProjectsApi();

  /// Deterministic error injection for reliable acceptance tests & Loom demo.
  void setForceFailNext(bool value) {
    _api.forceFailNext = value;
    notifyListeners();
  }

  bool? get forceFailNext => _api.forceFailNext;

  /// Loads page 0. Used on first screen open or after initial error retry.
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

      // Discard if a newer request (e.g., refresh) superseded this in-flight call
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

  /// Triggered when the user scrolls near the bottom of the list.
  Future<void> loadMore() async {
    // Guards: prevent duplicate or invalid calls
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

      // Discard stale response if user triggered refresh while this page was in flight
      if (token != _generationToken || _isDisposed) return;

      if (newItems.isEmpty || newItems.length < 20) {
        // De-duplicate by ID against existing items
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

      // Crucial: preserve already-loaded items untouched and present inline retry
      _state = _state.copyWith(
        isLoadingMore: false,
        loadMoreError: e,
      );
    }
    _safeNotify();
  }

  /// Retries loading the exact page that failed, without advancing or skipping items.
  Future<void> retryLoadMore() async {
    if (_state.loadMoreError == null) return;
    _state = _state.copyWith(clearLoadMoreError: true);
    _safeNotify();
    await loadMore();
  }

  /// Pull-to-refresh: increments generation token to invalidate in-flight calls.
  /// Keeps existing items visible until new page 0 arrives for graceful UX.
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
      // If refresh fails while items were present, retain current items or show error
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
