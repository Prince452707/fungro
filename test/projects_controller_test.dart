import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fungro/part2_projects/projects_api.dart';
import 'package:fungro/part2_projects/projects_controller.dart';
import 'package:fungro/part2_projects/projects_state.dart';

class ScriptableProjectsApi extends ProjectsApi {
  final Map<int, Completer<List<Project>>> _scriptedCompleters = {};
  final List<int> requestedPages = [];
  bool failNextCall = false;

  @override
  Future<List<Project>> fetchProjects(int page) async {
    requestedPages.add(page);

    if (failNextCall) {
      failNextCall = false;
      throw const ApiException('Simulated network error');
    }

    if (_scriptedCompleters.containsKey(page)) {
      return _scriptedCompleters[page]!.future;
    }

    if (page > 7) return const [];
    return List.generate(
      20,
      (i) => Project(
        id: 'proj_${page * 20 + i}',
        title: 'Project ${page * 20 + i}',
        company: 'Company ${page * 20 + i}',
        payout: 500,
      ),
    );
  }

  void scriptPage(int page, Completer<List<Project>> completer) {
    _scriptedCompleters[page] = completer;
  }
}

void main() {
  group('ProjectsController Unit Tests', () {
    late ScriptableProjectsApi api;
    late ProjectsController controller;

    setUp(() {
      api = ScriptableProjectsApi();
      controller = ProjectsController(api: api);
    });

    tearDown(() {
      controller.dispose();
    });

    test('1. First-load success transitions from initialLoading to ready with 20 items', () async {
      expect(controller.state.status, ListStatus.initialLoading);
      expect(controller.state.items, isEmpty);

      await controller.loadInitial();

      expect(controller.state.status, ListStatus.ready);
      expect(controller.state.items.length, 20);
      expect(controller.state.nextPage, 1);
      expect(controller.state.hasReachedEnd, isFalse);
    });

    test('2. First-load failure sets initialError and allows Retry', () async {
      api.failNextCall = true;

      await controller.loadInitial();

      expect(controller.state.status, ListStatus.initialError);
      expect(controller.state.items, isEmpty);

      await controller.loadInitial();

      expect(controller.state.status, ListStatus.ready);
      expect(controller.state.items.length, 20);
      expect(controller.state.nextPage, 1);
    });

    test('3. Infinite scroll: loadMore fetches page 1 and appends 20 items (total 40)', () async {
      await controller.loadInitial();
      expect(controller.state.items.length, 20);

      await controller.loadMore();

      expect(controller.state.items.length, 40);
      expect(controller.state.nextPage, 2);
      expect(controller.state.isLoadingMore, isFalse);
      expect(controller.state.loadMoreError, isNull);
    });

    test('4. Page-load error keeps existing items intact and retries same page', () async {
      await controller.loadInitial();
      expect(controller.state.items.length, 20);

      api.failNextCall = true;
      await controller.loadMore();

      expect(controller.state.items.length, 20);
      expect(controller.state.isLoadingMore, isFalse);
      expect(controller.state.loadMoreError, isNotNull);
      expect(controller.state.nextPage, 1);

      await controller.retryLoadMore();

      expect(controller.state.items.length, 40);
      expect(controller.state.loadMoreError, isNull);
      expect(controller.state.nextPage, 2);
    });

    test('5. Race condition on pull-to-refresh: stale in-flight response is discarded', () async {
      await controller.loadInitial();
      expect(controller.state.items.length, 20);

      final page1Completer = Completer<List<Project>>();
      api.scriptPage(1, page1Completer);

      final loadMoreFuture = controller.loadMore();
      expect(controller.state.isLoadingMore, isTrue);

      final refreshFuture = controller.refresh();

      page1Completer.complete(
        List.generate(
          20,
          (i) => Project(
            id: 'stale_$i',
            title: 'Stale Project $i',
            company: 'Stale Co',
            payout: 100,
          ),
        ),
      );

      await loadMoreFuture;
      await refreshFuture;

      expect(controller.state.items.any((p) => p.id.startsWith('stale_')), isFalse);
      expect(controller.state.items.length, 20);
      expect(controller.state.nextPage, 1);
    });

    test('6. End-of-list: returns empty or fewer than 20 items sets hasReachedEnd', () async {
      await controller.loadInitial();

      for (int i = 1; i <= 7; i++) {
        await controller.loadMore();
      }

      expect(controller.state.items.length, 160);
      expect(controller.state.nextPage, 8);

      await controller.loadMore();

      expect(controller.state.hasReachedEnd, isTrue);
      final prevCount = controller.state.items.length;

      await controller.loadMore();
      expect(controller.state.items.length, prevCount);
    });

    test('7. Rapid duplicate calls are guarded (no duplicate requests)', () async {
      await controller.loadInitial();

      final f1 = controller.loadMore();
      final f2 = controller.loadMore();
      await Future.wait([f1, f2]);

      expect(controller.state.items.length, 40);
      expect(controller.state.nextPage, 2);
    });
  });
}
