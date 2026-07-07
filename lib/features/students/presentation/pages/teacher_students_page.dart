import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/students/data/teacher_students_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/teacher_bottom_navigation.dart';

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key});

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  late final TeacherStudentsRepository _repository;
  late Future<List<TeacherClassStudents>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = TeacherStudentsRepository();
    _future = _repository.fetchClassStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchClassStudents();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Class students')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: FutureBuilder<List<TeacherClassStudents>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: _refresh);
              }

              final groups = snapshot.data!;
              final filteredGroups = _filterGroups(groups, _query);
              final totalStudents = filteredGroups.fold<int>(
                0,
                (total, group) => total + group.students.length,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  _SummaryBand(
                    classCount: filteredGroups.length,
                    studentCount: totalStudents,
                  ),
                  const SizedBox(height: 12),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  if (filteredGroups.isEmpty)
                    _EmptyState(hasQuery: _query.trim().isNotEmpty)
                  else
                    for (final group in filteredGroups) ...[
                      _ClassStudentsCard(
                        group: group,
                        onStudentTap: _showStudentDetail,
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const TeacherBottomNavigation(
        current: TeacherNavDestination.classes,
      ),
    );
  }

  List<TeacherClassStudents> _filterGroups(
    List<TeacherClassStudents> groups,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return groups;

    return groups
        .map((group) {
          final classMatches = [
            group.classRoom.name,
            group.classRoom.code,
            group.classRoom.groupName,
            group.classRoom.room,
          ].any((value) => value.toLowerCase().contains(normalized));

          final students = group.students
              .where(
                (student) =>
                    classMatches || _studentMatches(student, normalized),
              )
              .toList();

          return TeacherClassStudents(
            classRoom: group.classRoom,
            students: students,
          );
        })
        .where((group) => group.students.isNotEmpty)
        .toList();
  }

  bool _studentMatches(TeacherClassStudent student, String query) {
    return [
      student.name,
      student.studentCode,
      student.groupName,
      student.majorName,
      student.departmentName,
      student.status,
      '${student.attendancePercentage}',
    ].any((value) => value.toLowerCase().contains(query));
  }

  Future<void> _showStudentDetail(TeacherClassStudent student) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _StudentDetailSheet(
        student: student,
        future: _repository.fetchStudentDetail(student.id),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr('Search students'),
        prefixIcon: Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: Icon(Icons.close_rounded),
                tooltip: context.tr('Clear search'),
              ),
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.classCount, required this.studentCount});

  final int classCount;
  final int studentCount;

  @override
  Widget build(BuildContext context) {
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
              Icons.groups_2_outlined,
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
                  context.tr('Class students'),
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.format(
                    '{classes} classes - {students} students',
                    {'classes': '$classCount', 'students': '$studentCount'},
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

class _ClassStudentsCard extends StatelessWidget {
  const _ClassStudentsCard({required this.group, required this.onStudentTap});

  final TeacherClassStudents group;
  final ValueChanged<TeacherClassStudent> onStudentTap;

  @override
  Widget build(BuildContext context) {
    final classRoom = group.classRoom;

    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.school_outlined, color: AppColors.brandBlue),
        ),
        title: Text(
          classRoom.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${classRoom.code} - ${classRoom.groupName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        trailing: _CountPill(count: group.students.length),
        children: [
          if (group.students.isEmpty)
            _EmptyClassStudents()
          else
            for (final student in group.students) ...[
              _StudentRow(student: student, onTap: () => onStudentTap(student)),
              if (student != group.students.last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.onTap});

  final TeacherClassStudent student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(student.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                _initials(student.name),
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${student.studentCode} - ${student.groupName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    student.majorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AttendancePill(
              value: student.attendancePercentage,
              status: student.status,
              color: color,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendancePill extends StatelessWidget {
  const _AttendancePill({
    required this.value,
    required this.status,
    required this.color,
  });

  final int value;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$value%',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            context.tr(status),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.format('{count} students', {'count': '$count'}),
        style: TextStyle(
          color: AppColors.brandBlue,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  const _StudentDetailSheet({required this.student, required this.future});

  final TeacherClassStudent student;
  final Future<TeacherStudentDetail> future;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return FutureBuilder<TeacherStudentDetail>(
          future: future,
          builder: (context, snapshot) {
            final detail = snapshot.data;
            final displayStudent = detail?.student ?? student;
            final color = _statusColor(
              displayStudent.status.isEmpty
                  ? student.status
                  : displayStudent.status,
            );

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DEE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Text(
                        _initials(displayStudent.name),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayStudent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${displayStudent.studentCode} - ${displayStudent.groupName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded),
                      tooltip: context.tr('Close'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError || detail == null)
                  _DetailError()
                else ...[
                  _DetailInfoPanel(student: displayStudent),
                  const SizedBox(height: 14),
                  _StatsGrid(stats: detail.stats),
                  const SizedBox(height: 16),
                  _HistorySection(history: detail.history),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _DetailInfoPanel extends StatelessWidget {
  const _DetailInfoPanel({required this.student});

  final TeacherClassStudent student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _DetailLine(label: context.tr('Student ID'), value: '${student.id}'),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Student code'),
            value: student.studentCode,
          ),
          const Divider(height: 18),
          _DetailLine(label: context.tr('Email'), value: student.email),
          const Divider(height: 18),
          _DetailLine(label: context.tr('Phone'), value: student.phone),
          const Divider(height: 18),
          _DetailLine(label: context.tr('Group'), value: student.groupName),
          const Divider(height: 18),
          _DetailLine(label: context.tr('Major'), value: student.majorName),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Department'),
            value: student.departmentName,
          ),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Year level'),
            value: student.yearLevel,
          ),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Student status'),
            value: context.tr(student.studentStatus),
          ),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Account status'),
            value: context.tr(student.accountStatus),
          ),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Blacklist semesters'),
            value: student.blacklistSemesters,
          ),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Created at'),
            value: student.createdAt,
          ),
          const Divider(height: 18),
          _DetailLine(
            label: context.tr('Updated at'),
            value: student.updatedAt,
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final TeacherStudentStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(context.tr('Sessions'), '${stats.totalSessions}'),
      _StatItem(context.tr('Present'), '${stats.attendedCount}'),
      _StatItem(context.tr('Permission'), '${stats.excusedCount}'),
      _StatItem(context.tr('Absent'), '${stats.absentCount}'),
      _StatItem(context.tr('Attendance'), '${stats.attendanceRate}%'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.15,
      ),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              items[index].value,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              items[index].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final List<TeacherStudentHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.brandBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('Attendance history'),
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                context.tr('No attendance history yet.'),
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (final item in history.take(12)) ...[
              const Divider(height: 1),
              _HistoryRow(item: item),
            ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final TeacherStudentHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.date} - ${item.scanTime} - ${item.method}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _SmallStatusPill(label: item.status, color: color),
        ],
      ),
    );
  }
}

class _SmallStatusPill extends StatelessWidget {
  const _SmallStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr(label),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Text(
        context.tr('Could not load student detail'),
        style: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value);

  final String label;
  final String value;
}

class _EmptyClassStudents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        context.tr('No students in this class.'),
        style: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(Icons.groups_2_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(
                hasQuery
                    ? 'No students match your search.'
                    : 'No class students found.',
              ),
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
              context.tr('Could not load class students'),
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

Color _statusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('excellent')) return AppColors.green;
  if (lower.contains('good') || lower.contains('stable')) {
    return AppColors.orange;
  }
  if (lower.contains('warning') || lower.contains('attention')) {
    return AppColors.rose;
  }
  if (lower.contains('active') || lower.contains('present')) {
    return AppColors.green;
  }
  if (lower.contains('blacklist') || lower.contains('absent')) {
    return AppColors.rose;
  }
  return AppColors.brandBlue;
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p.characters.first).join();
  return letters.isEmpty ? 'ST' : letters.toUpperCase();
}
