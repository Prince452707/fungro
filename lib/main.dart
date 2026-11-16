import 'package:flutter/material.dart';
import 'part1_earnings/earnings_screen.dart';
import 'part2_projects/projects_screen.dart';

void main() {
  runApp(const FunngroAssessmentApp());
}

class FunngroAssessmentApp extends StatelessWidget {
  const FunngroAssessmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Funngro Take-Home Assessment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A896),
          primary: const Color(0xFF00A896),
          secondary: const Color(0xFF6366F1),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_currentIndex) {
        0 => HomeScreen(
            onNavigateToEarnings: () => setState(() => _currentIndex = 2),
            onNavigateToProjects: () => setState(() => _currentIndex = 1),
          ),
        1 => const ProjectsScreen(),
        2 => const EarningsScreen(),
        _ => const SizedBox.shrink(),
      },
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFFE6F7F5),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF00A896)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded, color: Color(0xFF00A896)),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF00A896)),
              label: 'Earnings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToEarnings;
  final VoidCallback onNavigateToProjects;

  const HomeScreen({
    super.key,
    required this.onNavigateToEarnings,
    required this.onNavigateToProjects,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Funngro Assessment'),
        actions: [
          GestureDetector(
            onTap: onNavigateToEarnings,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on_rounded, size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 4),
                  Text(
                    '2,450',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF92400E)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Badge(
              smallSize: 8,
              backgroundColor: Color(0xFFE11D48),
              child: Icon(Icons.notifications_outlined, color: Color(0xFF0F172A)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text('No unread notifications.'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          children: [
            _buildWelcomeHeader(context),
            const SizedBox(height: 16),
            _buildSearchBar(context),
            const SizedBox(height: 18),
            _buildHeroBanner(context),
            const SizedBox(height: 22),
            _buildCategoriesSection(context),
            const SizedBox(height: 24),
            _buildDeliverablesSection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00A896), width: 1.5),
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A896),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF00A896)),
                SizedBox(width: 4),
                Text(
                  'Funngro Teen Hub',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              'Welcome back, Alex! 👋',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onNavigateToProjects,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF00A896), size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Search gigs, projects or companies...',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A896), Color(0xFF028073)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A896).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TEEN FREELANCE PLATFORM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Earn, Learn & Build\nYour Dream Portfolio 🚀',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Live micro-internships with verified Indian brands. 100% instant UPI payouts directly to your wallet.',
            style: TextStyle(color: Color(0xFFE0F2F1), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onNavigateToProjects,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00897B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                icon: const Text('Explore Gigs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                label: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onNavigateToEarnings,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: const Text(
                  'My Wallet →',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {'title': 'Tech & Web', 'count': '24 gigs', 'icon': Icons.code_rounded, 'color': const Color(0xFFE8F8F5), 'iconColor': const Color(0xFF00A896)},
      {'title': 'Content & Reels', 'count': '18 gigs', 'icon': Icons.movie_creation_outlined, 'color': const Color(0xFFFFF0F3), 'iconColor': const Color(0xFFE11D48)},
      {'title': 'Design & UI', 'count': '15 gigs', 'icon': Icons.palette_outlined, 'color': const Color(0xFFFFF7E6), 'iconColor': const Color(0xFFD97706)},
      {'title': 'App Testing', 'count': '20 gigs', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFFE8F4FD), 'iconColor': const Color(0xFF0284C7)},
      {'title': 'Surveys & Voice', 'count': '12 gigs', 'icon': Icons.record_voice_over_outlined, 'color': const Color(0xFFF3E8FF), 'iconColor': const Color(0xFF7C3AED)},
      {'title': 'Explore All', 'count': '160 gigs', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFFFEF9C3), 'iconColor': const Color(0xFFB45309)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            GestureDetector(
              onTap: onNavigateToProjects,
              child: const Text(
                'See all →',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00A896)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Material(
              color: cat['color'] as Color,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: InkWell(
                onTap: onNavigateToProjects,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: cat['iconColor'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cat['count'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeliverablesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assessment Deliverables',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        _buildDeliverableCard(
          context,
          badge: 'PART 2',
          badgeColor: const Color(0xFF6366F1),
          badgeBg: const Color(0xFFEEF2FF),
          title: 'Paginated Projects List',
          subtitle: 'Infinite scroll with flaky API retry, generation tokens & pull-to-refresh.',
          statTitle: '160 PROJECTS',
          statSubtitle: '20 items / page',
          icon: Icons.work_rounded,
          onTap: onNavigateToProjects,
        ),
        const SizedBox(height: 12),
        _buildDeliverableCard(
          context,
          badge: 'PART 1',
          badgeColor: const Color(0xFF00A896),
          badgeBg: const Color(0xFFE8F8F5),
          title: 'Earnings History Screen',
          subtitle: 'Virtualized 3,000 items at 60fps with live wallet stream & cached formatter.',
          statTitle: '₹42,850 BALANCE',
          statSubtitle: '3,000 transactions',
          icon: Icons.account_balance_wallet_rounded,
          onTap: onNavigateToEarnings,
        ),
      ],
    );
  }

  Widget _buildDeliverableCard(
    BuildContext context, {
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required String title,
    required String subtitle,
    required String statTitle,
    required String statSubtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEDF2F7), width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(icon, color: badgeColor, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      Text(
                        statSubtitle,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Screen',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
