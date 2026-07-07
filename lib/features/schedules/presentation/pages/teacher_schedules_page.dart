import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/schedules/data/teacher_schedule_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/teacher_bottom_navigation.dart';

class TeacherSchedulesPage extends StatefulWidget {
  const TeacherSchedulesPage({super.key});

  @override
  State<TeacherSchedulesPage> createState() => _TeacherSchedulesPageState();
}

class _TeacherSchedulesPageState extends State<TeacherSchedulesPage> {
  static const _groupsPerPage = 5;

  late final TeacherScheduleRepository _repository;
  late Future<List<TeacherScheduleItem>> _future;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _repository = TeacherScheduleRepository();
    _future = _loadSchedules();
  }

  Future<List<TeacherScheduleItem>> _loadSchedules() {
    return _repository.fetchAllSchedules();
  }

  Future<void> _refresh() async {
    final future = _loadSchedules();
    setState(() {
      _page = 1;
      _future = future;
    });
    await future;
  }

  void _goToPage(int page) {
    if (page < 1 || page == _page) return;
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('All schedules')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh schedules'),
          ),
        ],
      ),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: FutureBuilder<List<TeacherScheduleItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: _refresh);
              }

              final items = snapshot.data!;
              final groups = _groupSchedulesByClassGroup(items);
              final lastPage = groups.isEmpty
                  ? 1
                  : ((groups.length + _groupsPerPage - 1) ~/ _groupsPerPage);
              final currentPage = _page.clamp(1, lastPage);
              if (currentPage != _page) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _page = currentPage);
                });
              }
              final visibleGroups = groups
                  .skip((currentPage - 1) * _groupsPerPage)
                  .take(_groupsPerPage)
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  _SummaryBand(
                    scheduleCount: items.length,
                    groupCount: groups.length,
                    currentPage: currentPage,
                    lastPage: lastPage,
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const _EmptyState()
                  else
                    for (final group in visibleGroups) ...[
                      _ClassGroupScheduleCard(group: group),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 4),
                  _PaginationBar(
                    currentPage: currentPage,
                    lastPage: lastPage,
                    totalItems: groups.length,
                    perPage: _groupsPerPage,
                    onPageChanged: _goToPage,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const TeacherBottomNavigation(
        current: TeacherNavDestination.schedules,
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({
    required this.scheduleCount,
    required this.groupCount,
    required this.currentPage,
    required this.lastPage,
  });

  final int scheduleCount;
  final int groupCount;
  final int currentPage;
  final int lastPage;

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
              Icons.calendar_month_rounded,
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
                  context.l10n.format('{count} groups', {
                    'count': '$groupCount',
                  }),
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n
                      .format('{count} schedules - Page {page} of {total}', {
                        'count': '$scheduleCount',
                        'page': '$currentPage',
                        'total': '$lastPage',
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
    );
  }
}

class _ClassGroupScheduleCard extends StatelessWidget {
  const _ClassGroupScheduleCard({required this.group});

  final _ClassGroupScheduleGroup group;

  @override
  Widget build(BuildContext context) {
    final activeCount = group.items
        .where((item) => item.status.toLowerCase().contains('active'))
        .length;
    final completedCount = group.items
        .where((item) => item.status.toLowerCase().contains('completed'))
        .length;

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
          child: Icon(Icons.groups_2_outlined, color: AppColors.brandBlue),
        ),
        title: Text(
          group.groupName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          context.l10n.format('{count} subjects - {sessions} sessions', {
            'count': '${group.subjectCount}',
            'sessions': '${group.items.length}',
          }),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: _GroupSummaryPill(
          activeCount: activeCount,
          completedCount: completedCount,
          totalCount: group.items.length,
        ),
        children: [
          for (final item in group.items) ...[
            _ScheduleSessionTile(item: item),
            if (item != group.items.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _GroupSummaryPill extends StatelessWidget {
  const _GroupSummaryPill({
    required this.activeCount,
    required this.completedCount,
    required this.totalCount,
  });

  final int activeCount;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final label = activeCount > 0
        ? context.l10n.format('{count} active', {'count': '$activeCount'})
        : context.l10n.format('{count}/{total} done', {
            'count': '$completedCount',
            'total': '$totalCount',
          });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.brandBlue,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ScheduleSessionTile extends StatelessWidget {
  const _ScheduleSessionTile({required this.item});

  final TeacherScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    final term = [
      if (item.academicYear.isNotEmpty) item.academicYear,
      if (item.semester.isNotEmpty) 'Semester ${item.semester}',
    ].join(' - ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.subjectCode} - ${_timeRange(item)}',
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
              _StatusChip(status: item.status, color: color),
            ],
          ),
          const SizedBox(height: 8),
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
                  context.l10n.format('Room {room} - Session {session}', {
                        'room': item.room,
                        'session': '${item.sessionNumber}',
                      }) +
                      (term.isEmpty ? '' : ' - $term'),
                  maxLines: 1,
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
    required this.perPage,
    required this.onPageChanged,
  });

  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int perPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : ((currentPage - 1) * perPage) + 1;
    final end = totalItems == 0
        ? 0
        : (currentPage * perPage).clamp(0, totalItems);
    final pages = _visiblePages(currentPage, lastPage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.format('Showing {start}-{end} of {total}', {
                    'start': '$start',
                    'end': '$end',
                    'total': '$totalItems',
                  }),
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                context.l10n.format('Page {page} of {total}', {
                  'page': '$currentPage',
                  'total': '$lastPage',
                }),
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageIconButton(
                  icon: Icons.first_page_rounded,
                  tooltip: context.tr('First page'),
                  enabled: currentPage > 1,
                  onTap: () => onPageChanged(1),
                ),
                _PageIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: context.tr('Previous page'),
                  enabled: currentPage > 1,
                  onTap: () => onPageChanged(currentPage - 1),
                ),
                for (final page in pages)
                  _PageNumberButton(
                    page: page,
                    active: page == currentPage,
                    onTap: () => onPageChanged(page),
                  ),
                _PageIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: context.tr('Next page'),
                  enabled: currentPage < lastPage,
                  onTap: () => onPageChanged(currentPage + 1),
                ),
                _PageIconButton(
                  icon: Icons.last_page_rounded,
                  tooltip: context.tr('Last page'),
                  enabled: currentPage < lastPage,
                  onTap: () => onPageChanged(lastPage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIconButton extends StatelessWidget {
  const _PageIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.active,
    required this.onTap,
  });

  final int page;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: active ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.brandBlue : const Color(0xFFF6F8FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.brandBlue : const Color(0xFFE6EBF2),
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              color: active ? Colors.white : AppColors.primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr(_statusLabel(status)),
        style: TextStyle(
          color: color,
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
          Icon(Icons.calendar_today_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('No schedules found.'),
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
              context.tr('Could not load schedules'),
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

List<_ClassGroupScheduleGroup> _groupSchedulesByClassGroup(
  List<TeacherScheduleItem> items,
) {
  final groups = <String, List<TeacherScheduleItem>>{};
  for (final item in items) {
    final key = item.groupName;
    groups.putIfAbsent(key, () => []).add(item);
  }

  final result = groups.entries.map((entry) {
    final first = entry.value.first;
    entry.value.sort((a, b) {
      final left = a.startTime ?? DateTime(1900);
      final right = b.startTime ?? DateTime(1900);
      return left.compareTo(right);
    });
    return _ClassGroupScheduleGroup(
      groupName: first.groupName,
      items: entry.value,
    );
  }).toList();

  result.sort((a, b) {
    return a.groupName.compareTo(b.groupName);
  });
  return result;
}

List<int> _visiblePages(int currentPage, int lastPage) {
  if (lastPage <= 5) return [for (var page = 1; page <= lastPage; page++) page];
  var start = currentPage - 2;
  var end = currentPage + 2;

  if (start < 1) {
    end += 1 - start;
    start = 1;
  }
  if (end > lastPage) {
    start -= end - lastPage;
    end = lastPage;
  }
  start = start.clamp(1, lastPage);

  return [for (var page = start; page <= end; page++) page];
}

class _ClassGroupScheduleGroup {
  const _ClassGroupScheduleGroup({
    required this.groupName,
    required this.items,
  });

  final String groupName;
  final List<TeacherScheduleItem> items;

  int get subjectCount => items
      .map((item) => '${item.subjectCode}|${item.subjectName}')
      .toSet()
      .length;
}

Color _statusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('skip')) return AppColors.rose;
  if (lower.contains('active') || lower.contains('approved')) {
    return AppColors.green;
  }
  if (lower.contains('completed')) return AppColors.brandBlue;
  if (lower.contains('cancel') || lower.contains('reject')) {
    return AppColors.rose;
  }
  return AppColors.orange;
}

String _statusLabel(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('skip')) return 'Skip';
  return status.toUpperCase();
}

String _timeRange(TeacherScheduleItem item) {
  final start = _formatDateTime(item.startTime);
  final end = _formatTime(item.endTime);
  if (start == 'TBD' && end == 'TBD') return 'TBD';
  if (end == 'TBD') return start;
  return '$start - $end';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'TBD';
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  return '$date ${_formatTime(value)}';
}

String _formatTime(DateTime? value) {
  if (value == null) return 'TBD';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
