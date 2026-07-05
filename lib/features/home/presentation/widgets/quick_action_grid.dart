import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/home/domain/models/quick_action.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({required this.actions, super.key});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        return _QuickActionCard(action: actions[index]);
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(_routeFor(action.label)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: action.color, size: 23),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _routeFor(String label) {
  return switch (label.toLowerCase()) {
    'courses' => AppRoutes.courses,
    'attendance' => AppRoutes.attendance,
    'grades' => AppRoutes.grades,
    'payment' || 'payments' => AppRoutes.payments,
    'library' => AppRoutes.library,
    'support' => AppRoutes.support,
    _ => '/unavailable/${Uri.encodeComponent(label)}',
  };
}
