import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';

enum TeacherNavDestination { home, classes, schedules, permissions, attendance }

class TeacherBottomNavigation extends StatelessWidget {
  const TeacherBottomNavigation({
    required this.current,
    this.onCurrentTap,
    this.replaceRoutes = true,
    super.key,
  });

  final TeacherNavDestination current;
  final VoidCallback? onCurrentTap;
  final bool replaceRoutes;

  static const _items = [
    _TeacherNavItem(
      destination: TeacherNavDestination.home,
      icon: Icons.dashboard_rounded,
      label: 'Home',
      route: AppRoutes.home,
    ),
    _TeacherNavItem(
      destination: TeacherNavDestination.classes,
      icon: Icons.school_outlined,
      label: 'My classes',
      route: AppRoutes.teacherClasses,
    ),
    _TeacherNavItem(
      destination: TeacherNavDestination.schedules,
      icon: Icons.calendar_month_rounded,
      label: 'Schedule',
      route: AppRoutes.teacherSchedules,
    ),
    _TeacherNavItem(
      destination: TeacherNavDestination.permissions,
      icon: Icons.approval_outlined,
      label: 'Request',
      route: AppRoutes.teacherPermissions,
    ),
    _TeacherNavItem(
      destination: TeacherNavDestination.attendance,
      icon: Icons.fact_check_outlined,
      label: 'My attendance',
      route: AppRoutes.teacherAttendance,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in _items)
            _TeacherNavButton(
              item: item,
              active: item.destination == current,
              onTap: () {
                if (item.destination == current) {
                  onCurrentTap?.call();
                  return;
                }
                final currentIndex = _items.indexWhere(
                  (navItem) => navItem.destination == current,
                );
                final targetIndex = _items.indexOf(item);
                final arguments = targetIndex < currentIndex
                    ? 'slide-left-to-right'
                    : 'slide-right-to-left';
                if (replaceRoutes) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(item.route, arguments: arguments);
                } else {
                  Navigator.of(
                    context,
                  ).pushNamed(item.route, arguments: arguments);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _TeacherNavButton extends StatelessWidget {
  const _TeacherNavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _TeacherNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 21,
              color: active ? AppColors.brandBlue : AppColors.mutedText,
            ),
            const SizedBox(height: 3),
            Text(
              context.tr(item.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: item.label.length > 10 ? 8 : 10,
                fontWeight: FontWeight.w900,
                color: active ? AppColors.brandBlue : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherNavItem {
  const _TeacherNavItem({
    required this.destination,
    required this.icon,
    required this.label,
    required this.route,
  });

  final TeacherNavDestination destination;
  final IconData icon;
  final String label;
  final String route;
}
