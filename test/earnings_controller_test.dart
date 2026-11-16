import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fungro/part1_earnings/earnings_controller.dart';
import 'package:fungro/part1_earnings/earnings_state.dart';
import 'package:fungro/part1_earnings/fake_earnings_api.dart';
import 'package:fungro/part1_earnings/models.dart';

class ScriptableEarningsApi extends FakeEarningsApi {
  final StreamController<Earning> _streamController =
      StreamController<Earning>.broadcast();
  bool shouldFail = false;

  @override
  Future<List<Earning>> fetchEarnings({bool forceError = false}) async {
    if (shouldFail || forceError) {
      throw Exception('Server error: Failed to fetch earnings');
    }
    return super.fetchEarnings(forceError: false);
  }

  @override
  Stream<Earning> walletUpdates({Duration period = const Duration(seconds: 8)}) {
    return _streamController.stream;
  }

  void emitWalletUpdate(Earning earning) {
    _streamController.add(earning);
  }

  void closeStream() {
    _streamController.close();
  }
}

void main() {
  group('EarningsController Unit Tests', () {
    late ScriptableEarningsApi api;
    late EarningsController controller;

    setUp(() {
      api = ScriptableEarningsApi();
      controller = EarningsController(api: api);
    });

    tearDown(() {
      controller.dispose();
      api.closeStream();
    });

    test('Initial load fetches 3,000 items and enters EarningsData state', () async {
      expect(controller.state, isA<EarningsInitial>());

      await controller.loadEarnings();

      expect(controller.state, isA<EarningsData>());
      final data = controller.state as EarningsData;
      expect(data.items.length, 3000);
      expect(data.isRefreshing, isFalse);
    });

    test('Initial load failure transitions to EarningsError and can be retried', () async {
      api.shouldFail = true;

      await controller.loadEarnings();

      expect(controller.state, isA<EarningsError>());
      final errorState = controller.state as EarningsError;
      expect(errorState.message, contains('Server error'));

      // Retry
      api.shouldFail = false;
      await controller.loadEarnings();

      expect(controller.state, isA<EarningsData>());
      expect((controller.state as EarningsData).items.length, 3000);
    });

    test('Live wallet updates prepend new earnings and de-duplicate by ID', () async {
      await controller.loadEarnings();
      final initialCount = (controller.state as EarningsData).items.length;

      // Emit new unique earning
      final newLiveEarning = Earning(
        id: 'new_unique_live_1',
        title: 'Instant Bonus',
        amount: 250,
        date: DateTime.now(),
      );
      api.emitWalletUpdate(newLiveEarning);

      // Wait a microtask turn for stream event processing
      await Future<void>.delayed(Duration.zero);

      final updatedData = controller.state as EarningsData;
      expect(updatedData.items.length, initialCount + 1);
      expect(updatedData.items.first.id, 'new_unique_live_1');

      // Emit the SAME earning again -> de-duplication must prevent duplicate entry
      api.emitWalletUpdate(newLiveEarning);
      await Future<void>.delayed(Duration.zero);

      final deduplicatedData = controller.state as EarningsData;
      expect(deduplicatedData.items.length, initialCount + 1);
    });

    test('Cached currency formatter formats Indian Rupee correctly without locale re-parsing', () {
      final formatted = controller.formatAmount(1250);
      expect(formatted, contains('1,250'));
    });
  });
}
