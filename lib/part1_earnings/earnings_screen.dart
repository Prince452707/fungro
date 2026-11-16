import 'package:flutter/material.dart';
import 'earnings_controller.dart';
import 'earnings_state.dart';
import 'models.dart';

/// Screen displaying a teen's earnings history.
/// Engineered for 60fps virtualization across 3,000+ items on low-end Android devices
/// with a modern, clean UI inspired by teen fintech & gig platforms.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late final EarningsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EarningsController();
    _controller.loadEarnings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('My Earnings'),
            actions: [
              // Deterministic error toggle for recording & live demo defense
              IconButton(
                icon: Icon(
                  _controller.forceNextError
                      ? Icons.bug_report_rounded
                      : Icons.bug_report_outlined,
                  color: _controller.forceNextError ? Colors.red : const Color(0xFF64748B),
                ),
                tooltip: 'Force Next Request to Fail (Debug Toggle)',
                onPressed: () {
                  final nextVal = !_controller.forceNextError;
                  _controller.toggleForceError(nextVal);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1500),
                      content: Text(
                        nextVal
                            ? 'Next fetch will simulate an error ⚠️'
                            : 'Error simulation disabled ✅',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _buildBody(context, _controller.state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, EarningsState state) {
    return switch (state) {
      EarningsInitial() || EarningsLoading() => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF00A896)),
              SizedBox(height: 16),
              Text(
                'Loading your earnings history...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      EarningsError(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE11D48)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Failed to Load Earnings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _controller.loadEarnings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      EarningsEmpty(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F7F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: Color(0xFF00A896),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No Earnings Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _controller.loadEarnings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      EarningsData(:final items) => Column(
          children: [
            // Top Balance Snapshot Card
            _buildBalanceHeroCard(context, items.length),

            // Virtualized 3,000 items list
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF00A896),
                onRefresh: () => _controller.refresh(),
                child: ListView.builder(
                  // itemExtent guarantees O(1) viewport layout calculations for 3,000 items.
                  itemExtent: 84.0,
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemBuilder: (context, index) {
                    final earning = items[index];
                    return _EarningListTile(
                      key: ValueKey(earning.id),
                      earning: earning,
                      formattedAmount: _controller.formatAmount(earning.amount),
                      onTap: () => _handleItemTap(earning),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
    };
  }

  Widget _buildBalanceHeroCard(BuildContext context, int totalCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'TOTAL WALLET BALANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.shield_outlined, size: 13, color: Color(0xFF00A896)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '₹42,850',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '$totalCount transactions • Live sync active',
                style: const TextStyle(fontSize: 11, color: Color(0xFF00A896), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB2EBE4)),
            ),
            child: const Column(
              children: [
                Icon(Icons.account_balance_rounded, color: Color(0xFF00A896), size: 20),
                SizedBox(height: 4),
                Text(
                  'UPI Linked',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00A896)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Safe tap handler with in-flight guard, mounted checks, and snackbar error feedback.
  Future<void> _handleItemTap(Earning earning) async {
    if (_controller.isFetchingDetail) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 600),
        content: Text('Fetching transaction details...'),
      ),
    );

    try {
      final detail = await _controller.fetchItemDetail(earning.id);
      if (!mounted || detail == null) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (bottomSheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF00A896), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          earning.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'ID: ${earning.id}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _controller.formatAmount(earning.amount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A896),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  detail,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to load transaction details: $e'),
        ),
      );
    }
  }
}

/// Extracted, const-capable tile widget to isolate rebuild boundaries.
/// Uses Material widget directly to ensure proper ink splashes and zero framework warnings.
class _EarningListTile extends StatelessWidget {
  final Earning earning;
  final String formattedAmount;
  final VoidCallback onTap;

  const _EarningListTile({
    super.key,
    required this.earning,
    required this.formattedAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLiveBonus = earning.id.startsWith('live_earn');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isLiveBonus ? const Color(0xFFFFFBEB) : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLiveBonus ? const Color(0xFFFDE68A) : const Color(0xFFEDF2F7),
            width: 1.2,
          ),
        ),
        elevation: 0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLiveBonus ? const Color(0xFFFEF3C7) : const Color(0xFFE8F8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLiveBonus ? Icons.bolt_rounded : Icons.currency_rupee_rounded,
              color: isLiveBonus ? const Color(0xFFD97706) : const Color(0xFF00A896),
              size: 20,
            ),
          ),
          title: Text(
            earning.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          subtitle: Text(
            '${earning.date.day}/${earning.date.month}/${earning.date.year} • ${earning.id}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isLiveBonus ? const Color(0xFFD97706) : const Color(0xFF00A896),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLiveBonus ? 'Instant' : 'Settled',
                style: TextStyle(
                  fontSize: 10,
                  color: isLiveBonus ? const Color(0xFFD97706) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
