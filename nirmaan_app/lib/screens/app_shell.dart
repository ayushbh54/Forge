import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/screens/dashboard/dashboard_screen.dart';
import 'package:nirmaan_app/screens/schedule/schedule_screen.dart';
import 'package:nirmaan_app/screens/conflicts/conflicts_screen.dart';
import 'package:nirmaan_app/screens/dpr/dpr_screen.dart';
import 'package:nirmaan_app/screens/more/more_screen.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ScheduleScreen(),
    ConflictsScreen(),
    DprScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadInitialData();
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final conflictCount = provider.conflicts.where((c) => c['status'] == 'Open').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E172E),
          border: const Border(
            top: BorderSide(color: Color(0xFF1E2E5C), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.explore_rounded,
                  activeIcon: Icons.explore,
                  label: 'Explore',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_today_rounded,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.verified_user_outlined,
                  activeIcon: Icons.verified_user_rounded,
                  label: 'Truth Hub',
                  badgeCount: conflictCount > 0 ? conflictCount : null,
                  badgeColor: const Color(0xFFEF4444),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: 'Execution',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.grid_view_rounded,
                  activeIcon: Icons.apps_rounded,
                  label: 'All Hubs',
                  badgeCount: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badgeCount,
    Color? badgeColor,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      splashColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7).withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                  size: isSelected ? 24 : 22,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0E172E), width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
