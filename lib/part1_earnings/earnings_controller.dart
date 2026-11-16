import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'fake_earnings_api.dart';
import 'earnings_state.dart';
import 'models.dart';

/// Controller owning earnings state, network calls, and real-time wallet stream.
/// Kept separate from UI to guarantee testability and lifecycle safety.
class EarningsController extends ChangeNotifier {
  final FakeEarningsApi _api;

  EarningsState _state = const EarningsInitial();
  EarningsState get state => _state;

  StreamSubscription<Earning>? _walletSubscription;
  bool _forceNextError = false;
  bool _isFetchingDetail = false;

  /// Cached currency formatter: created once to avoid repeated 3ms locale parsing per item.
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  EarningsController({FakeEarningsApi? api}) : _api = api ?? FakeEarningsApi();

  /// Format an amount using the pre-cached NumberFormat instance.
  String formatAmount(double amount) => _currencyFormatter.format(amount);

  /// Toggle flag for deterministic testing of the error state.
  void toggleForceError(bool value) {
    _forceNextError = value;
    notifyListeners();
  }

  bool get forceNextError => _forceNextError;
  bool get isFetchingDetail => _isFetchingDetail;

  /// Initial load triggered once from initState.
  Future<void> loadEarnings() async {
    _state = const EarningsLoading();
    notifyListeners();

    try {
      final items = await _api.fetchEarnings(forceError: _forceNextError);
      _forceNextError = false; // Reset toggle once used

      if (items.isEmpty) {
        _state = const EarningsEmpty();
      } else {
        _state = EarningsData(items);
      }
      notifyListeners();

      // Subscribe to live wallet stream only after initial load finishes to avoid race conditions.
      _subscribeToWalletUpdates();
    } catch (e) {
      _forceNextError = false;
      _state = EarningsError(e.toString().replaceAll('Exception: ', ''));
      notifyListeners();
    }
  }

  /// Pull-to-refresh: keeps existing list visible while fetching fresh data.
  Future<void> refresh() async {
    if (_state is! EarningsData) {
      await loadEarnings();
      return;
    }

    final currentItems = (_state as EarningsData).items;
    _state = EarningsData(currentItems, isRefreshing: true);
    notifyListeners();

    try {
      final freshItems = await _api.fetchEarnings(forceError: _forceNextError);
      _forceNextError = false;

      if (freshItems.isEmpty) {
        _state = const EarningsEmpty();
      } else {
        _state = EarningsData(freshItems);
      }
    } catch (e) {
      _forceNextError = false;
      // On refresh error, keep existing data intact and notify UI
      _state = EarningsData(currentItems, isRefreshing: false);
    }
    notifyListeners();
  }

  /// Subscribes to periodic live wallet updates, merging by ID and prepending.
  void _subscribeToWalletUpdates() {
    _walletSubscription?.cancel();
    _walletSubscription = _api.walletUpdates().listen(
      (newEarning) {
        if (_state is! EarningsData) return;
        final currentItems = (_state as EarningsData).items;

        // De-duplicate: ignore if earning id already exists
        final alreadyExists = currentItems.any((e) => e.id == newEarning.id);
        if (alreadyExists) return;

        // Prepend new live earning to top of list
        final updatedList = [newEarning, ...currentItems];
        _state = EarningsData(updatedList);
        notifyListeners();
      },
      onError: (err) {
        // Stream errors should not crash the app or wipe visible list
        debugPrint('Wallet stream error: $err');
      },
      cancelOnError: false,
    );
  }

  /// Guards against rapid double-taps and fetches transaction detail safely.
  Future<String?> fetchItemDetail(String earningId) async {
    if (_isFetchingDetail) return null; // In-flight tap guard
    _isFetchingDetail = true;
    notifyListeners();

    try {
      final detail = await _api.fetchDetail(earningId);
      return detail;
    } catch (e) {
      rethrow;
    } finally {
      _isFetchingDetail = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Explicitly cancel stream subscription to prevent memory leaks and setState after dispose
    _walletSubscription?.cancel();
    _walletSubscription = null;
    super.dispose();
  }
}
