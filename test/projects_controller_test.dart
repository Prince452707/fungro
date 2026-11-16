import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fungro/part2_projects/projects_api.dart';
import 'package:fungro/part2_projects/projects_controller.dart';
import 'package:fungro/part2_projects/projects_state.dart';

/// Scriptable mock for ProjectsApi enabling deterministic unit testing of all 8 acceptance criteria.
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

    // Default fast mock generation
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

      // Now retry
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

      // Fail page 1
      api.failNextCall = true;
      await controller.loadMore();

      // Items MUST remain visible and untouched
      expect(controller.state.items.length, 20);
      expect(controller.state.isLoadingMore, isFalse);
      expect(controller.state.loadMoreError, isNotNull);
      expect(controller.state.nextPage, 1); // nextPage not skipped

      // Retry loads the same page 1 successfully
      await controller.retryLoadMore();

      expect(controller.state.items.length, 40);
      expect(controller.state.loadMoreError, isNull);
      expect(controller.state.nextPage, 2);
    });

    test('5. Race condition on pull-to-refresh: stale in-flight response is discarded', () async {
      await controller.loadInitial();
      expect(controller.state.items.length, 20);

      // Script page 1 with a manual completer to hold it in flight
      final page1Completer = Completer<List<Project>>();
      api.scriptPage(1, page1Completer);

      // Start loading page 1
      final loadMoreFuture = controller.loadMore();
      expect(controller.state.isLoadingMore, isTrue);

      // User pulls to refresh while page 1 is still in flight!
      final refreshFuture = controller.refresh();

      // Now complete page 1 after refresh was triggered
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

      // The stale items from page 1 must NOT be appended to the fresh list!
      expect(controller.state.items.any((p) => p.id.startsWith('stale_')), isFalse);
      expect(controller.state.items.length, 20);
      expect(controller.state.nextPage, 1);
    });

    test('6. End-of-list: returns empty or fewer than 20 items sets hasReachedEnd', () async {
      await controller.loadInitial(); // Page 0: 20 items

      // Load pages 1 to 7
      for (int i = 1; i <= 7; i++) {
        await controller.loadMore();
      }

      expect(controller.state.items.length, 160); // 8 pages * 20 = 160 items
      expect(controller.state.nextPage, 8);

      // Page 8 returns empty list
      await controller.loadMore();

      expect(controller.state.hasReachedEnd, isTrue);
      final prevCount = controller.state.items.length;

      // Additional calls are guarded and do nothing
      await controller.loadMore();
      expect(controller.state.items.length, prevCount);
    });

    test('7. Rapid duplicate calls are guarded (no duplicate requests)', () async {
      await controller.loadInitial();

      // Call loadMore twice concurrently
      final f1 = controller.loadMore();
      final f2 = controller.loadMore();
      await Future.wait([f1, f2]);

      // Only one page request should have executed
      expect(controller.state.items.length, 40);
      expect(controller.state.nextPage, 2);
    });
  });
}
