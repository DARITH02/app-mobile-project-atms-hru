import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';

enum StudentNavDestination {
  home,
  attendance,
  grades,
  gpa,
  documents,
  permissions,
  profile,
  about,
}

class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({required this.current, super.key});

  final StudentNavDestination current;

  static const _items = [
    _StudentNavItem(
      destination: StudentNavDestination.home,
      icon: Icons.home_rounded,
      label: 'Home',
      route: AppRoutes.home,
    ),
    _StudentNavItem(
      destination: StudentNavDestination.attendance,
      icon: Icons.fact_check_rounded,
      label: 'Attendance',
      route: AppRoutes.attendance,
    ),
    _StudentNavItem(
      destination: StudentNavDestination.grades,
      icon: Icons.bar_chart_rounded,
      label: 'Grades',
      route: AppRoutes.grades,
    ),
    _StudentNavItem(
      destination: StudentNavDestination.gpa,
      icon: Icons.school_rounded,
      label: 'GPA',
      route: AppRoutes.gpa,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final item in _items)
              Expanded(
                child: _StudentBottomNavButton(
                  item: item,
                  isActive: item.destination == current,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StudentBottomNavigationForRole extends StatelessWidget {
  const StudentBottomNavigationForRole({required this.current, super.key});

  final StudentNavDestination current;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthSessionStore().userRole(),
      builder: (context, snapshot) {
        if (snapshot.data != 'student') return const SizedBox.shrink();
        return StudentBottomNavigation(current: current);
      },
    );
  }
}

class _StudentBottomNavButton extends StatelessWidget {
  const _StudentBottomNavButton({required this.item, required this.isActive});

  final _StudentNavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isActive ? null : () => _goTo(context, item.route),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? AppColors.brandBlue : AppColors.mutedText,
            ),
            const SizedBox(height: 2),
            Text(
              context.tr(item.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w900,
                color: isActive ? AppColors.brandBlue : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(BuildContext context, String route) {
    if (route == AppRoutes.home) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }
}

class _StudentNavItem {
  const _StudentNavItem({
    required this.destination,
    required this.icon,
    required this.label,
    required this.route,
  });

  final StudentNavDestination destination;
  final IconData icon;
  final String label;
  final String route;
}
