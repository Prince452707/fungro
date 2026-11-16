import 'package:flutter/material.dart';
import 'projects_api.dart';
import 'projects_controller.dart';
import 'projects_state.dart';

/// Screen displaying paginated projects with infinite scrolling, inline error recovery,
/// pull-to-refresh race safety, and full lifecycle cleanup.
/// UI styled with clean teen gig cards inspired by modern service marketplaces.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late final ProjectsController _controller;
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Beta Testing',
    'Design',
    'Content',
    'Coding',
    'Surveys',
  ];

  @override
  void initState() {
    super.initState();
    _controller = ProjectsController();
    _controller.loadInitial();

    _scrollController.addListener(_onScroll);

    // Edge case check: on very tall screens/tablets, 20 items might not exceed viewport height.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedMoreContent();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger next page when user scrolls within 200px of bottom
    if (maxScroll - currentScroll <= 200.0) {
      _controller.loadMore();
    }
  }

  void _checkIfNeedMoreContent() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent == 0 &&
        _controller.state.status == ListStatus.ready &&
        !_controller.state.hasReachedEnd) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              state.status == ListStatus.ready
                  ? 'Explore Projects (${state.items.length})'
                  : 'Explore Projects',
            ),
            actions: [
              // Deterministic debug toggle for 5-minute screen recording
              IconButton(
                icon: Icon(
                  _controller.forceFailNext == true
                      ? Icons.bug_report_rounded
                      : Icons.bug_report_outlined,
                  color: _controller.forceFailNext == true ? Colors.red : const Color(0xFF64748B),
                ),
                tooltip: 'Force Next Request to Fail (Debug Toggle)',
                onPressed: () {
                  final willFail = _controller.forceFailNext != true;
                  _controller.setForceFailNext(willFail);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1400),
                      content: Text(
                        willFail
                            ? 'Next API call will fail on purpose ⚠️'
                            : 'Normal API behavior restored ✅',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Category Filter Pills
              _buildCategorySelector(),

              // Main List Content
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF00A896) : const Color(0xFF64748B),
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFE8F8F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00A896) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              onSelected: (val) {
                setState(() => _selectedCategory = cat);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProjectsState state) {
    return switch (state.status) {
      // F2: First-load state
      ListStatus.initialLoading => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF00A896)),
              SizedBox(height: 16),
              Text(
                'Fetching live projects for teenagers...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),

      // F3: First-load error with full-screen retry
      ListStatus.initialError => Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFE11D48)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Failed to Load Projects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your network connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _controller.loadInitial(),
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

      // F8: Empty state
      ListStatus.empty => Center(
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
                  child: const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF00A896)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No Projects Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check back later for fresh gigs and micro-internships.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _controller.loadInitial(),
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

      // Ready state: Single ListView.builder with infinite scroll and dynamic footer
      ListStatus.ready => RefreshIndicator(
          color: const Color(0xFF00A896),
          onRefresh: () async {
            await _controller.refresh();
            _checkIfNeedMoreContent();
          },
          child: _buildProjectsList(context, state),
        ),
    };
  }

  Widget _buildProjectsList(BuildContext context, ProjectsState state) {
    final showFooter = state.isLoadingMore ||
        state.loadMoreError != null ||
        state.hasReachedEnd;

    final itemCount = state.items.length + (showFooter ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Footer index
        if (index == state.items.length) {
          return _buildFooter(context, state);
        }

        final project = state.items[index];
        return _ProjectTile(
          key: ValueKey(project.id),
          project: project,
          index: index + 1,
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, ProjectsState state) {
    // F4: Page-load spinner
    if (state.isLoadingMore) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF00A896)),
            ),
            SizedBox(width: 12),
            Text(
              'Loading next page of gigs...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // F5: Page-load inline error row with retry button
    if (state.loadMoreError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network error loading page',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9F1239)),
                  ),
                  Text(
                    'Your loaded projects are safe.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _controller.retryLoadMore(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // F6: End-of-list distinct footer
    if (state.hasReachedEnd) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB2EBE4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF00A896)),
            SizedBox(width: 10),
            Text(
              "You've reached the end! (All 160 projects loaded)",
              style: TextStyle(
                color: Color(0xFF00897B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final int index;

  const _ProjectTile({
    super.key,
    required this.project,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Generate soft pastel colors per item like Image 2
    final pastelColors = [
      const Color(0xFFE8F8F5), // Mint
      const Color(0xFFF3E8FF), // Lavender
      const Color(0xFFFFF7E6), // Peach
      const Color(0xFFE8F4FD), // Sky
      const Color(0xFFFFF0F3), // Rose
    ];
    final cardBg = pastelColors[index % pastelColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Rating chip & Index
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      '4.9 (verified)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '#$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Info: Company Avatar & Project Title
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    project.company.substring(0, project.company.length > 2 ? 2 : 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          project.company,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom Row: Payout & Apply Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STIPEND PAYOUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '₹${project.payout}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A896),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Applied to ${project.title}! 🎉'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A896),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                label: const Icon(Icons.arrow_forward_rounded, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
