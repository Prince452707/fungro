import 'dart:async';
import 'models.dart';

class FakeEarningsApi {
  Future<List<Earning>> fetchEarnings({bool forceError = false}) async {
    await Future.delayed(const Duration(milliseconds: 650));
    if (forceError) {
      throw Exception('Failed to load earnings from server. Please retry.');
    }

    final now = DateTime.now();
    return List.generate(3000, (index) {
      final daysAgo = index ~/ 10;
      final amount = 50.0 + (index % 17) * 25.0;
      return Earning(
        id: 'earn_$index',
        title: _sampleTitles[index % _sampleTitles.length],
        amount: amount,
        date: now.subtract(Duration(days: daysAgo, hours: index % 24)),
      );
    });
  }

  /// Broadcast stream simulating real-time wallet credits (e.g., project approvals, referral bonuses).
  Stream<Earning> walletUpdates({Duration period = const Duration(seconds: 8)}) {
    var counter = 9000;
    return Stream.periodic(period, (i) {
      counter++;
      return Earning(
        id: 'live_earn_$counter',
        title: 'Instant Bonus: ${_bonusTitles[i % _bonusTitles.length]}',
        amount: (50 + (i % 5) * 50).toDouble(),
        date: DateTime.now(),
      );
    }).asBroadcastStream();
  }

  /// Fetches rich detail for an individual earning item when tapped.
  Future<String> fetchDetail(String earningId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return 'Transaction Verified ✅\nID: $earningId\nStatus: Settled to UPI Wallet\nProcessed via Funngro Teen Pay System.';
  }

  static const _sampleTitles = [
    'Content Writing for EcoClub',
    'Social Media Graphic Design',
    'Voiceover for EduTech Demo',
    'Bug Bounty Report: Auth Flow',
    'Survey Completion: Teen Trends',
    'Video Editing: 30s Reel',
    'Campus Ambassador Referral',
    'Translation: English to Hindi',
    'Data Cleaning Exercise',
    'Market Research Interview',
  ];

  static const _bonusTitles = [
    'Quick Delivery Perk',
    'Top Quality Rating',
    'Client Tip',
    'Referral Milestone',
  ];
}
