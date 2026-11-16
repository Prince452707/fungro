import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'fake_earnings_api.dart';
import 'earnings_state.dart';
import 'models.dart';

class EarningsController extends ChangeNotifier {
  final FakeEarningsApi _api;

  EarningsState _state = const EarningsInitial();
  EarningsState get state => _state;

  StreamSubscription<Earning>? _walletSubscription;
  bool _forceNextError = false;
  bool _isFetchingDetail = false;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  EarningsController({FakeEarningsApi? api}) : _api = api ?? FakeEarningsApi();

  String formatAmount(double amount) => _currencyFormatter.format(amount);

  void toggleForceError(bool value) {
    _forceNextError = value;
    notifyListeners();
  }

  bool get forceNextError => _forceNextError;
  bool get isFetchingDetail => _isFetchingDetail;

  Future<void> loadEarnings() async {
    _state = const EarningsLoading();
    notifyListeners();

    try {
      final items = await _api.fetchEarnings(forceError: _forceNextError);
      _forceNextError = false;

      if (items.isEmpty) {
        _state = const EarningsEmpty();
      } else {
        _state = EarningsData(items);
      }
      notifyListeners();

      _subscribeToWalletUpdates();
    } catch (e) {
      _forceNextError = false;
      _state = EarningsError(e.toString().replaceAll('Exception: ', ''));
      notifyListeners();
    }
  }

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
      _state = EarningsData(currentItems, isRefreshing: false);
    }
    notifyListeners();
  }

  void _subscribeToWalletUpdates() {
    _walletSubscription?.cancel();
    _walletSubscription = _api.walletUpdates().listen(
      (newEarning) {
        if (_state is! EarningsData) return;
        final currentItems = (_state as EarningsData).items;

        final alreadyExists = currentItems.any((e) => e.id == newEarning.id);
        if (alreadyExists) return;

        final updatedList = [newEarning, ...currentItems];
        _state = EarningsData(updatedList);
        notifyListeners();
      },
      onError: (err) {
        debugPrint('Wallet stream error: $err');
      },
      cancelOnError: false,
    );
  }

  Future<String?> fetchItemDetail(String earningId) async {
    if (_isFetchingDetail) return null;
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
    _walletSubscription?.cancel();
    _walletSubscription = null;
    super.dispose();
  }
}
