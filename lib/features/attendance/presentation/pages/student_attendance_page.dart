import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/attendance/data/student_attendance_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  late final StudentAttendanceRepository _repository;
  late Future<List<StudentAttendanceSubject>> _future;

  @override
  void initState() {
    super.initState();
    _repository = StudentAttendanceRepository();
    _future = _repository.fetchSubjects();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchSubjects();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Attendance')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: FutureBuilder<List<StudentAttendanceSubject>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: _refresh);
              }

              final subjects = snapshot.data!;
              final grouped = _groupByGroup(subjects);
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  _SummaryBand(subjects: subjects),
                  const SizedBox(height: 18),
                  if (grouped.isEmpty)
                    _EmptyState()
                  else
                    for (final entry in grouped.entries) ...[
                      _GroupHeader(
                        groupName: entry.key,
                        count: entry.value.length,
                      ),
                      const SizedBox(height: 10),
                      for (final subject in entry.value) ...[
                        _SubjectAttendanceCard(subject: subject),
                        const SizedBox(height: 12),
                      ],
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const StudentBottomNavigation(
        current: StudentNavDestination.attendance,
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.subjects});

  final List<StudentAttendanceSubject> subjects;

  @override
  Widget build(BuildContext context) {
    final sessions = subjects.fold<int>(
      0,
      (sum, item) => sum + item.sessionsCount,
    );
    final present = subjects.fold<int>(
      0,
      (sum, item) => sum + item.presentCount,
    );
    final absent = subjects.fold<int>(0, (sum, item) => sum + item.absentCount);
    final permission = subjects.fold<int>(
      0,
      (sum, item) => sum + item.permissionCount,
    );
    final late = subjects.fold<int>(0, (sum, item) => sum + item.lateCount);
    final rate = sessions > 0
        ? ((subjects.fold<int>(0, (sum, item) => sum + item.attendedCount) /
                      sessions) *
                  100)
              .round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24145DA0),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
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
                      context.l10n.format('{count} subjects', {
                        'count': '${subjects.length}',
                      }),
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.format('{rate}% attendance rate', {
                        'rate': '$rate',
                      }),
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
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.45,
            ),
            children: [
              _SummaryTile(label: context.tr('Present'), value: '$present'),
              _SummaryTile(label: context.tr('Absent'), value: '$absent'),
              _SummaryTile(
                label: context.tr('Permission'),
                value: '$permission',
              ),
              _SummaryTile(label: context.tr('Late'), value: '$late'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.groupName, required this.count});

  final String groupName;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          context.l10n.format('{count} subjects', {'count': '$count'}),
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SubjectAttendanceCard extends StatelessWidget {
  const _SubjectAttendanceCard({required this.subject});

  final StudentAttendanceSubject subject;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      collapsedShape: _shape,
      shape: _shape,
      backgroundColor: AppColors.surface,
      collapsedBackgroundColor: AppColors.surface,
      leading: CircleAvatar(
        backgroundColor: AppColors.brandTeal.withValues(alpha: 0.12),
        child: Icon(Icons.menu_book_outlined, color: AppColors.brandTeal),
      ),
      title: Text(
        subject.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${context.tr('Teacher')}: ${subject.teacher}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: _RateBadge(rate: subject.attendanceRate),
      children: [
        _SubjectStats(subject: subject),
        const SizedBox(height: 10),
        if (subject.history.isEmpty)
          _InlineEmpty(text: context.tr('No attendance history yet.'))
        else
          for (final record in subject.history)
            _AttendanceRecordRow(record: record),
      ],
    );
  }

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: AppColors.border),
  );
}

class _RateBadge extends StatelessWidget {
  const _RateBadge({required this.rate});

  final int rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$rate%',
        style: TextStyle(
          color: AppColors.brandBlue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SubjectStats extends StatelessWidget {
  const _SubjectStats({required this.subject});

  final StudentAttendanceSubject subject;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MiniStat(context.tr('Sessions'), '${subject.sessionsCount}'),
      _MiniStat(context.tr('Present'), '${subject.presentCount}'),
      _MiniStat(context.tr('Absent'), '${subject.absentCount}'),
      _MiniStat(context.tr('Remaining'), '${subject.remainingSessions}'),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.7,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(item.value, style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat {
  const _MiniStat(this.label, this.value);

  final String label;
  final String value;
}

class _AttendanceRecordRow extends StatelessWidget {
  const _AttendanceRecordRow({required this.record});

  final StudentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(record.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              _dateLabel(record.date),
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              record.scanTime.isEmpty
                  ? context.tr('No scan time')
                  : context.l10n.format('{time} - {method}', {
                      'time': record.scanTime,
                      'method': record.method,
                    }),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(status: record.status, color: color),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.tr(_statusLabel(status)),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _InlineEmpty(text: context.tr('No attendance history yet.'));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text(
              context.tr('Could not load student attendance'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('Check your backend API connection and try again.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<StudentAttendanceSubject>> _groupByGroup(
  List<StudentAttendanceSubject> subjects,
) {
  final groups = <String, List<StudentAttendanceSubject>>{};
  for (final subject in subjects) {
    groups.putIfAbsent(subject.group, () => []).add(subject);
  }
  return groups;
}

String _dateLabel(DateTime? value) {
  if (value == null) return 'TBD';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$month/$day';
}

String _statusLabel(String value) {
  final lower = value.toLowerCase();
  return switch (lower) {
    'present' => 'Present',
    'late' => 'Late',
    'absent' => 'Absent',
    'excused' || 'permission' => 'Permission',
    'scheduled' => 'Scheduled',
    _ => value,
  };
}

Color _statusColor(String value) {
  final lower = value.toLowerCase();
  return switch (lower) {
    'present' => AppColors.green,
    'late' => AppColors.orange,
    'absent' => AppColors.rose,
    'excused' || 'permission' => AppColors.brandBlue,
    'scheduled' => AppColors.purple,
    _ => AppColors.mutedText,
  };
}
