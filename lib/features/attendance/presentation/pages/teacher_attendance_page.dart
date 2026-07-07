import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/core/notifications/schedule_notification_service.dart';
import 'package:hru_atms/features/attendance/data/teacher_attendance_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/teacher_bottom_navigation.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  late final TeacherAttendanceRepository _repository;
  late Future<_TeacherAttendanceViewData> _future;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _repository = TeacherAttendanceRepository();
    _future = _loadAttendance();
  }

  Future<_TeacherAttendanceViewData> _loadAttendance() async {
    final results = await Future.wait([
      _repository.fetchAllSessions(),
      _repository.requiredCheckouts(),
    ]);
    final sessions = results[0];
    await ScheduleNotificationService.instance.scheduleTeacherCheckoutReminders(
      sessions,
    );

    return _TeacherAttendanceViewData(
      sessions: sessions,
      checkoutSessions: results[1],
    );
  }

  Future<void> _refresh() async {
    final future = _loadAttendance();
    setState(() => _future = future);
    await future;
  }

  Future<void> _openTeacherQrScanner() async {
    final didUpdate = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.teacherQrCheckIn);
    if (!mounted || didUpdate != true) return;
    await _refresh();
  }

  Future<void> _startCheckout(
    List<TeacherAttendanceSession> checkoutSessions,
  ) async {
    if (_isCheckingOut || checkoutSessions.isEmpty) return;

    final session = checkoutSessions.length == 1
        ? checkoutSessions.first
        : await _pickCheckoutSession(checkoutSessions);
    if (session == null || !mounted) return;

    setState(() => _isCheckingOut = true);
    try {
      final position = await _currentPosition(
        locationDisabledMessage: context.tr(
          'Phone location is required for checkout. Enable GPS and try again.',
        ),
        locationDeniedMessage: context.tr(
          'Phone location is required for checkout. Allow location access and try again.',
        ),
      );
      final checkedOut = await _repository.checkOut(
        session.id,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.format('{subject} checked out at {time}', {
              'subject': checkedOut.subjectName,
              'time': checkedOut.checkOutTime,
            }),
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? context.tr(error.message)
          : '$error'.replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  Future<TeacherAttendanceSession?> _pickCheckoutSession(
    List<TeacherAttendanceSession> sessions,
  ) {
    return showModalBottomSheet<TeacherAttendanceSession>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.tr('Choose session to check out'),
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            for (final session in sessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.orange.withValues(alpha: 0.12),
                  child: Icon(Icons.logout_rounded, color: AppColors.orange),
                ),
                title: Text(
                  session.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${session.startTime} - ${session.endTime} - ${context.tr('Room')} ${session.room}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(session),
              ),
          ],
        ),
      ),
    );
  }

  Future<Position> _currentPosition({
    required String locationDisabledMessage,
    required String locationDeniedMessage,
  }) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception(locationDisabledMessage);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(locationDeniedMessage);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('My attendance')),
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
          child: FutureBuilder<_TeacherAttendanceViewData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: _refresh);
              }

              final data = snapshot.data!;
              final sessions = data.sessions;
              final checkoutSessions = data.checkoutSessions;
              final now = DateTime.now();
              final monthSessions =
                  sessions
                      .where((item) => _isSameMonth(item.attendanceDate, now))
                      .toList()
                    ..sort((a, b) {
                      final left = a.attendanceDate ?? DateTime(1900);
                      final right = b.attendanceDate ?? DateTime(1900);
                      return right.compareTo(left);
                    });
              final subjectGroups = _groupBySubject(monthSessions);
              final monthLabel = _monthLabel(context, now);
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  _AttendanceActionPanel(
                    checkoutCount: checkoutSessions.length,
                    isCheckingOut: _isCheckingOut,
                    onCheckOut: checkoutSessions.isEmpty
                        ? null
                        : () => _startCheckout(checkoutSessions),
                    onScanQr: _openTeacherQrScanner,
                  ),
                  const SizedBox(height: 16),
                  _SummaryBand(sessions: monthSessions, monthLabel: monthLabel),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: context.tr('This month records'),
                    trailing: context.l10n.format('{count} items', {
                      'count': '${subjectGroups.length}',
                    }),
                  ),
                  if (subjectGroups.isEmpty)
                    _EmptyState(monthLabel: monthLabel)
                  else
                    for (final group in subjectGroups) ...[
                      _SubjectIssueCard(group: group, repository: _repository),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const TeacherBottomNavigation(
        current: TeacherNavDestination.attendance,
      ),
    );
  }
}

class _TeacherAttendanceViewData {
  const _TeacherAttendanceViewData({
    required this.sessions,
    required this.checkoutSessions,
  });

  final List<TeacherAttendanceSession> sessions;
  final List<TeacherAttendanceSession> checkoutSessions;
}

class _AttendanceActionPanel extends StatelessWidget {
  const _AttendanceActionPanel({
    required this.checkoutCount,
    required this.isCheckingOut,
    required this.onCheckOut,
    required this.onScanQr,
  });

  final int checkoutCount;
  final bool isCheckingOut;
  final VoidCallback? onCheckOut;
  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) {
    final hasCheckout = checkoutCount > 0;

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
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Teacher attendance'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCheckout
                          ? context.l10n.format(
                              '{count} sessions ready for check-out',
                              {'count': '$checkoutCount'},
                            )
                          : context.tr(
                              'Check-out opens 30 minutes before end time',
                            ),
                      maxLines: 2,
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
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isCheckingOut ? null : onCheckOut,
                  icon: isCheckingOut
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.logout_rounded, size: 18),
                  label: Text(context.tr('Check Out')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onScanQr,
                  icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: Text(context.tr('Scan QR')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.sessions, required this.monthLabel});

  final List<TeacherAttendanceSession> sessions;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final present = _countCategory(sessions, _AttendanceCategory.present);
    final late = _countCategory(sessions, _AttendanceCategory.late);
    final absent = _countCategory(sessions, _AttendanceCategory.absent);
    final permission = _countCategory(sessions, _AttendanceCategory.permission);
    final pending = _countCategory(sessions, _AttendanceCategory.pending);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
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
                      context.l10n.format('{count} records', {
                        'count': '${sessions.length}',
                      }),
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.format('Attendance summary for {month}', {
                        'month': monthLabel,
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
              childAspectRatio: 2.35,
            ),
            children: [
              _SummaryTile(
                label: context.tr('Present'),
                value: '$present',
                icon: Icons.how_to_reg_outlined,
              ),
              _SummaryTile(
                label: context.tr('Late'),
                value: '$late',
                icon: Icons.schedule_outlined,
              ),
              _SummaryTile(
                label: context.tr('Absent'),
                value: '$absent',
                icon: Icons.cancel_outlined,
              ),
              _SummaryTile(
                label: context.tr('Permission'),
                value: '$permission',
                icon: Icons.approval_outlined,
              ),
              _SummaryTile(
                label: context.tr('Pending'),
                value: '$pending',
                icon: Icons.hourglass_empty_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.surface, size: 18),
          const SizedBox(width: 8),
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
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xDDEAF4FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _SubjectIssueCard extends StatelessWidget {
  const _SubjectIssueCard({required this.group, required this.repository});

  final _SubjectIssueGroup group;
  final TeacherAttendanceRepository repository;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.menu_book_outlined, color: AppColors.brandBlue),
        ),
        title: Text(
          group.subjectName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${group.subjectCode} - ${group.groupName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        trailing: SizedBox(
          width: 78,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                context.l10n.format('{count} items', {
                  'count': '${group.sessions.length}',
                }),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        children: [
          _SubjectStatusStrip(group: group),
          for (final session in group.sessions) ...[
            _IssueSessionRow(session: session, repository: repository),
            if (session != group.sessions.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SubjectStatusStrip extends StatelessWidget {
  const _SubjectStatusStrip({required this.group});

  final _SubjectIssueGroup group;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_AttendanceCategory.present, context.tr('Present')),
      (_AttendanceCategory.late, context.tr('Late')),
      (_AttendanceCategory.absent, context.tr('Absent')),
      (_AttendanceCategory.permission, context.tr('Permission')),
      (_AttendanceCategory.pending, context.tr('Pending')),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final item in items)
            if (group.count(item.$1) > 0)
              _CountChip(
                label: item.$2,
                count: group.count(item.$1),
                color: _categoryColor(item.$1),
              ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueSessionRow extends StatefulWidget {
  const _IssueSessionRow({required this.session, required this.repository});

  final TeacherAttendanceSession session;
  final TeacherAttendanceRepository repository;

  @override
  State<_IssueSessionRow> createState() => _IssueSessionRowState();
}

class _IssueSessionRowState extends State<_IssueSessionRow> {
  Future<TeacherSessionStudents>? _studentsFuture;

  void _loadStudents() {
    _studentsFuture ??= widget.repository.fetchSessionStudents(
      widget.session.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.session);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(_loadStudents);
          }
        },
        tilePadding: const EdgeInsets.symmetric(vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_statusIcon(widget.session), color: color, size: 20),
        ),
        title: Text(
          widget.session.date,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${widget.session.startTime} - ${widget.session.endTime} - ${context.tr('Room')} ${widget.session.room}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: _CountChip(
          label: context.tr(_statusLabel(widget.session)),
          count: 1,
          color: color,
        ),
        children: [
          if (_studentsFuture == null)
            const SizedBox.shrink()
          else
            FutureBuilder<TeacherSessionStudents>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return _InlineSessionMessage(
                    icon: Icons.cloud_off_outlined,
                    text: context.tr('Could not load session students'),
                  );
                }

                final data = snapshot.data!;
                if (data.students.isEmpty) {
                  return _InlineSessionMessage(
                    icon: Icons.people_outline_rounded,
                    text: context.tr('No students found for this session.'),
                  );
                }

                return Column(
                  children: [
                    _StudentSessionSummary(data: data),
                    const SizedBox(height: 8),
                    for (final student in data.students)
                      _SessionStudentRow(student: student),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StudentSessionSummary extends StatelessWidget {
  const _StudentSessionSummary({required this.data});

  final TeacherSessionStudents data;

  @override
  Widget build(BuildContext context) {
    final absent = (data.totalCount - data.presentCount - data.excusedCount)
        .clamp(0, data.totalCount)
        .toInt();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _CountChip(
          label: context.tr('Students'),
          count: data.totalCount,
          color: AppColors.brandBlue,
        ),
        _CountChip(
          label: context.tr('Present'),
          count: data.presentCount,
          color: AppColors.green,
        ),
        _CountChip(
          label: context.tr('Permission'),
          count: data.excusedCount,
          color: AppColors.orange,
        ),
        _CountChip(
          label: context.tr('Absent'),
          count: absent,
          color: AppColors.rose,
        ),
      ],
    );
  }
}

class _SessionStudentRow extends StatelessWidget {
  const _SessionStudentRow({required this.student});

  final TeacherSessionStudent student;

  @override
  Widget build(BuildContext context) {
    final color = _studentStatusColor(student.status);
    final detailParts = [
      student.studentCode,
      if (student.checkInTime.isNotEmpty && student.checkInTime != 'â€”')
        student.checkInTime,
      if (student.method.isNotEmpty && student.method != 'â€”') student.method,
      if (student.permissionType.isNotEmpty) context.tr(student.permissionType),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              _studentStatusIcon(student.status),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
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
                  detailParts.join(' - '),
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
          const SizedBox(width: 8),
          _StudentStatusPill(status: student.status, color: color),
        ],
      ),
    );
  }
}

class _StudentStatusPill extends StatelessWidget {
  const _StudentStatusPill({required this.status, required this.color});

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
        context.tr(_studentStatusLabel(status)),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InlineSessionMessage extends StatelessWidget {
  const _InlineSessionMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedText, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.format('No attendance records for {month}.', {
                'month': monthLabel,
              }),
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
              context.tr('Could not load teacher attendance'),
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

enum _AttendanceCategory { present, absent, permission, late, pending }

class _SubjectIssueGroup {
  const _SubjectIssueGroup({
    required this.subjectName,
    required this.subjectCode,
    required this.groupName,
    required this.sessions,
  });

  final String subjectName;
  final String subjectCode;
  final String groupName;
  final List<TeacherAttendanceSession> sessions;

  int count(_AttendanceCategory category) => _countCategory(sessions, category);
}

List<_SubjectIssueGroup> _groupBySubject(
  List<TeacherAttendanceSession> sessions,
) {
  final groups = <String, List<TeacherAttendanceSession>>{};
  for (final session in sessions) {
    final key =
        '${session.subjectCode}|${session.subjectName}|${session.groupName}';
    groups.putIfAbsent(key, () => []).add(session);
  }

  final result = groups.entries.map((entry) {
    final first = entry.value.first;
    return _SubjectIssueGroup(
      subjectName: first.subjectName,
      subjectCode: first.subjectCode,
      groupName: first.groupName,
      sessions: entry.value,
    );
  }).toList();

  result.sort((a, b) => a.subjectName.compareTo(b.subjectName));
  return result;
}

int _countCategory(
  List<TeacherAttendanceSession> sessions,
  _AttendanceCategory category,
) {
  return sessions.where((session) => _categoryOf(session) == category).length;
}

_AttendanceCategory _categoryOf(TeacherAttendanceSession session) {
  final lower = session.status.toLowerCase().trim();
  if (lower == 'permission' || lower.contains('permission')) {
    return _AttendanceCategory.permission;
  }
  if (lower == 'absent' ||
      lower == 'asent' ||
      lower == 'missed' ||
      lower.contains('absent')) {
    return _AttendanceCategory.absent;
  }
  if (lower.contains('late') || lower == 'missing_check_out') {
    return _AttendanceCategory.late;
  }
  if (lower.contains('present') ||
      lower == 'on_time' ||
      lower == 'teaching' ||
      lower.contains('completed') ||
      lower.contains('early_leave') ||
      session.hasCheckIn) {
    return _AttendanceCategory.present;
  }
  return _AttendanceCategory.pending;
}

String _statusLabel(TeacherAttendanceSession session) {
  return switch (_categoryOf(session)) {
    _AttendanceCategory.present => 'Present',
    _AttendanceCategory.absent => 'Absent',
    _AttendanceCategory.permission => 'Permission',
    _AttendanceCategory.late => 'Late',
    _AttendanceCategory.pending => 'Pending',
  };
}

Color _statusColor(TeacherAttendanceSession session) {
  return _categoryColor(_categoryOf(session));
}

Color _categoryColor(_AttendanceCategory category) {
  return switch (category) {
    _AttendanceCategory.present => AppColors.green,
    _AttendanceCategory.absent => AppColors.rose,
    _AttendanceCategory.permission => AppColors.orange,
    _AttendanceCategory.late => AppColors.purple,
    _AttendanceCategory.pending => AppColors.brandBlue,
  };
}

IconData _statusIcon(TeacherAttendanceSession session) {
  return switch (_categoryOf(session)) {
    _AttendanceCategory.absent => Icons.cancel_outlined,
    _AttendanceCategory.permission => Icons.approval_outlined,
    _AttendanceCategory.present => Icons.how_to_reg_outlined,
    _AttendanceCategory.late => Icons.schedule_outlined,
    _AttendanceCategory.pending => Icons.hourglass_empty_rounded,
  };
}

String _studentStatusLabel(String status) {
  final lower = status.toLowerCase().trim();
  if (lower == 'excused' || lower == 'permission') return 'Permission';
  if (lower == 'late') return 'Late';
  if (lower == 'present') return 'Present';
  if (lower == 'absent') return 'Absent';
  return status;
}

Color _studentStatusColor(String status) {
  final lower = status.toLowerCase().trim();
  if (lower == 'excused' || lower == 'permission') return AppColors.orange;
  if (lower == 'late') return AppColors.purple;
  if (lower == 'present') return AppColors.green;
  if (lower == 'absent') return AppColors.rose;
  return AppColors.mutedText;
}

IconData _studentStatusIcon(String status) {
  final lower = status.toLowerCase().trim();
  if (lower == 'excused' || lower == 'permission') {
    return Icons.approval_outlined;
  }
  if (lower == 'late') return Icons.schedule_outlined;
  if (lower == 'present') return Icons.how_to_reg_outlined;
  if (lower == 'absent') return Icons.cancel_outlined;
  return Icons.help_outline_rounded;
}

bool _isSameMonth(DateTime? value, DateTime month) {
  if (value == null) return false;
  return value.year == month.year && value.month == month.month;
}

String _monthLabel(BuildContext context, DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${context.tr(months[value.month - 1])} ${value.year}';
}
