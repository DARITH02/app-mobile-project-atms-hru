import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/home/data/teacher_dashboard_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/teacher_bottom_navigation.dart';

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  late final TeacherDashboardRepository _repository;
  late Future<List<TeacherClass>> _future;

  @override
  void initState() {
    super.initState();
    _repository = TeacherDashboardRepository();
    _future = _repository.fetchClasses();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchClasses();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('My classes')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh classes'),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<TeacherClass>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingScreen();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _ErrorState(onRetry: _refresh);
            }

            final classes = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
              children: [
                _SummaryBand(classes: classes),
                const SizedBox(height: 16),
                if (classes.isEmpty)
                  const _EmptyState()
                else
                  for (final item in classes) ...[
                    _ClassCard(item: item),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const TeacherBottomNavigation(
        current: TeacherNavDestination.classes,
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.classes});

  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    final students = classes.fold<int>(
      0,
      (total, item) => total + item.totalStudents,
    );
    final average = classes.isEmpty
        ? 0
        : (classes.fold<int>(0, (total, item) => total + item.efficacy) /
                  classes.length)
              .round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.school_outlined,
              color: AppColors.surface,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.format('{count} classes', {
                    'count': '${classes.length}',
                  }),
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.format(
                    '{students} students - {average}% average attendance',
                    {'students': '$students', 'average': '$average'},
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.item});

  final TeacherClass item;

  @override
  Widget build(BuildContext context) {
    final status = _classStatus(item);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(status.icon, color: status.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.code} - ${item.groupName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (item.efficacy.clamp(0, 100)) / 100,
              minHeight: 9,
              color: status.color,
              backgroundColor: const Color(0xFFE7ECF3),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.groups_outlined,
                  label: context.tr('Students'),
                  value: '${item.totalStudents}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  icon: Icons.event_available_outlined,
                  label: context.tr('Sessions'),
                  value: '${item.sessionsCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  icon: Icons.how_to_reg_outlined,
                  label: context.tr('Present'),
                  value: '${item.presenceCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.meeting_room_outlined,
                size: 17,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.format('Room {room} - {schedule}', {
                    'room': item.room,
                    'schedule': item.schedule,
                  }),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brandBlue),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _ClassStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr(status.label),
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(Icons.school_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('No classes assigned yet.'),
              style: TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              context.tr('Could not load classes'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassStatus {
  const _ClassStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_ClassStatus _classStatus(TeacherClass item) {
  if (item.totalStudents == 0 || item.sessionsCount == 0) {
    return const _ClassStatus(
      label: 'Pending',
      color: AppColors.mutedText,
      icon: Icons.hourglass_empty_rounded,
    );
  }
  if (item.efficacy >= 85) {
    return const _ClassStatus(
      label: 'Excellent',
      color: AppColors.green,
      icon: Icons.trending_up_rounded,
    );
  }
  if (item.efficacy >= 70) {
    return const _ClassStatus(
      label: 'Stable',
      color: AppColors.orange,
      icon: Icons.insights_rounded,
    );
  }
  return const _ClassStatus(
    label: 'Attention',
    color: AppColors.rose,
    icon: Icons.priority_high_rounded,
  );
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x0F172033), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );
}
