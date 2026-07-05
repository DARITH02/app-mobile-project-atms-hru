import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/auth/data/auth_repository.dart';
import 'package:hru_atms/features/gpa/data/student_gpa_repository.dart';
import 'package:hru_atms/features/home/data/student_dashboard_repository.dart';
import 'package:hru_atms/features/notifications/data/notification_repository.dart';
import 'package:hru_atms/core/notifications/schedule_notification_service.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/language_toggle_button.dart';
import 'package:hru_atms/shared/widgets/maintenance_page.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';
import 'package:hru_atms/shared/widgets/theme_mode_selector.dart';

class StudentPortalHomePage extends StatefulWidget {
  const StudentPortalHomePage({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<StudentPortalHomePage> createState() => _StudentPortalHomePageState();
}

class _StudentPortalHomePageState extends State<StudentPortalHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final StudentDashboardRepository _dashboardRepository;
  late final StudentGpaRepository _gpaRepository;
  late final NotificationRepository _notificationRepository;
  late Future<_StudentHomeData> _homeFuture;
  final _overviewKey = GlobalKey();
  final _scheduleKey = GlobalKey();
  final _attendanceKey = GlobalKey();
  final _gradesKey = GlobalKey();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _dashboardRepository = StudentDashboardRepository();
    _gpaRepository = StudentGpaRepository();
    _notificationRepository = NotificationRepository();
    _homeFuture = _fetchHomeData();
  }

  Future<void> _refresh() async {
    final future = _fetchHomeData();
    setState(() => _homeFuture = future);
    await future;
  }

  Future<_StudentHomeData> _fetchHomeData() async {
    final dashboardFuture = _dashboardRepository.fetchDashboard();
    final transcriptFuture = _gpaRepository
        .fetchTranscript()
        .then<StudentGpaTranscript?>((transcript) => transcript)
        .catchError((_) => null);
    final notificationsFuture = _notificationRepository
        .fetchNotifications()
        .then<AppNotificationFeed?>((feed) => feed)
        .catchError((_) => null);
    final dashboard = await dashboardFuture;
    await ScheduleNotificationService.instance.scheduleStudentScheduleReminders(
      [...dashboard.schedules, ...dashboard.weekSchedules],
    );
    await ScheduleNotificationService.instance
        .scheduleStudentDailyScheduleAlarms([
          ...dashboard.schedules,
          ...dashboard.weekSchedules,
        ]);

    return _StudentHomeData(
      dashboard: dashboard,
      transcript: await transcriptFuture,
      notifications: await notificationsFuture,
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    await widget.authRepository.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<_StudentHomeData>(
          future: _homeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingScreen();
            }
            final error = snapshot.error;
            if (error is ApiException && error.statusCode == 503) {
              return MaintenancePage(message: error.message, onRetry: _refresh);
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: () => _refresh());
            }
            final homeData = snapshot.data;
            if (homeData == null) {
              return _ErrorState(onRetry: () => _refresh());
            }
            final dashboard = homeData.dashboard;

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
              children: [
                _header(
                  dashboard,
                  () => _scaffoldKey.currentState?.openDrawer(),
                  homeData.notifications?.unreadCount ?? 0,
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _overviewKey,
                  child: _studentOverview(dashboard),
                ),
                const SizedBox(height: 14),
                _studentQrScanCard(dashboard),
                const SizedBox(height: 14),
                KeyedSubtree(
                  key: _gradesKey,
                  child: _performanceGrid(dashboard.performance),
                ),
                _sectionHeader(
                  context.tr('Comparison'),
                  _localizedDashboardPhrase(context, dashboard.termLabel),
                ),
                _comparisonCard(dashboard),
                KeyedSubtree(
                  key: _scheduleKey,
                  child: _sectionHeader(
                    context.tr('Today schedule'),
                    context.l10n.format('{count} classes', {
                      'count': '${dashboard.schedules.length}',
                    }),
                  ),
                ),
                if (dashboard.schedules.isEmpty)
                  _EmptyPanel(
                    icon: Icons.calendar_today_outlined,
                    title: context.tr('No scheduled classes'),
                    subtitle: context.tr(
                      'Your upcoming sessions will appear here.',
                    ),
                  )
                else
                  for (final item in dashboard.schedules) ...[
                    _scheduleCard(item),
                    const SizedBox(height: 10),
                  ],
                _sectionHeader(
                  context.tr('Next days this week'),
                  context.l10n.format('{count} classes', {
                    'count': '${dashboard.weekSchedules.length}',
                  }),
                ),
                _weekScheduleList(dashboard.weekSchedules),
                KeyedSubtree(
                  key: _attendanceKey,
                  child: _sectionHeader(
                    context.tr('This month attendance'),
                    _localizedDashboardPhrase(
                      context,
                      dashboard.monthAttendance.monthLabel,
                    ),
                  ),
                ),
                _monthAttendanceGrid(dashboard.monthAttendance),
                _sectionHeader(
                  context.tr('Semester result'),
                  context.tr('Academic result'),
                ),
                _semesterResultCard(homeData.transcript),
                _sectionHeader(
                  context.tr('Student services'),
                  context.tr('Quick access'),
                ),
                _quickActionGrid(dashboard.services),
              ],
            );
          },
        ),
      ),
      drawer: FutureBuilder<_StudentHomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          final dashboard = snapshot.data?.dashboard;
          final student = dashboard?.student;
          return _StudentHomeDrawer(
            studentName: student?.name ?? context.tr('Student'),
            studentDetail: dashboard == null
                ? context.tr('Student Dashboard')
                : '${_localizedDashboardPhrase(context, dashboard.termLabel)} - ${student?.major ?? ''}',
            profilePhotoUrl: student?.profilePhotoUrl ?? '',
            isLoggingOut: _isLoggingOut,
            onHome: () => _closeDrawerAndScroll(_overviewKey),
            onProfile: () => _closeDrawerAndPush(AppRoutes.profile),
            onSchedule: () => _closeDrawerAndScroll(_scheduleKey),
            onAttendance: () => _closeDrawerAndPush(AppRoutes.attendance),
            onGrades: () => _closeDrawerAndPush(AppRoutes.grades),
            onGpa: () => _closeDrawerAndPush(AppRoutes.gpa),
            onDocuments: () => _closeDrawerAndPush(AppRoutes.documents),
            onPermissions: () =>
                _closeDrawerAndPush(AppRoutes.studentPermissions),
            onAbout: () => _closeDrawerAndPush(AppRoutes.about),
            onLogout: _logout,
          );
        },
      ),
      bottomNavigationBar: const StudentBottomNavigation(
        current: StudentNavDestination.home,
      ),
    );
  }

  Widget _header(
    StudentDashboard dashboard,
    VoidCallback? onOpenMenu,
    int unreadNotifications,
  ) {
    final photoUrl = _resolveImageUrl(dashboard.student.profilePhotoUrl);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          onPressed: onOpenMenu,
          icon: Icon(Icons.menu_rounded),
          tooltip: context.tr('Menu'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dashboard.student.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_localizedDashboardPhrase(context, dashboard.termLabel)} - ${dashboard.student.major}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _NotificationIconButton(unreadCount: unreadNotifications),
        const SizedBox(width: 8),
        const LanguageToggleButton(),
        const SizedBox(width: 8),
        PopupMenuButton<_HomeMenuAction>(
          tooltip: context.tr('Account menu'),
          onSelected: (action) {
            if (action == _HomeMenuAction.profile) {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            }
            if (action == _HomeMenuAction.logout) _logout();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _HomeMenuAction.profile,
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text(context.tr('View profile')),
                ],
              ),
            ),
            PopupMenuItem(
              value: _HomeMenuAction.logout,
              enabled: !_isLoggingOut,
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _isLoggingOut
                        ? context.tr('Signing out...')
                        : context.tr('Logout'),
                  ),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.brandBlue,
            backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
            child: _isLoggingOut
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : photoUrl.isEmpty
                ? Text(
                    _initials(dashboard.student.name),
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _studentOverview(StudentDashboard dashboard) {
    final photoUrl = _resolveImageUrl(dashboard.student.profilePhotoUrl);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                  image: photoUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                alignment: Alignment.center,
                child: photoUrl.isEmpty
                    ? Icon(Icons.school_outlined, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.student.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${dashboard.student.group} - ${_localizedDashboardPhrase(context, dashboard.standing)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xDDEAF4FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewTile(
                  label: context.tr('Sessions'),
                  value: '${dashboard.stats.total}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewTile(
                  label: context.tr('Present'),
                  value: '${dashboard.stats.present}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewTile(
                  label: context.tr('Remaining'),
                  value: '${dashboard.stats.remaining}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _studentQrScanCard(StudentDashboard dashboard) {
    final session = dashboard.activeSession;
    final hasSession = session != null;

    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Scan attendance QR'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSession
                      ? '${session.subject} - ${_localizedStatus(context, session.status)}'
                      : context.tr('Scan the teacher attendance QR code'),
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
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.studentQrScan),
            icon: Icon(Icons.qr_code_scanner_rounded),
            tooltip: context.tr('Start scan'),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _performanceGrid(List<DashboardPerformance> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _MetricCard(
            data: items[index],
            icon: _metricIcon(items[index].label),
            color: _metricColor(index),
          ),
        );
      },
    );
  }

  Widget _comparisonCard(StudentDashboard dashboard) {
    return _Panel(
      child: Column(
        children: [
          if (dashboard.comparison.isEmpty)
            _EmptyInline(text: context.tr('No comparison data available yet.'))
          else
            for (final item in dashboard.comparison) ...[
              _ComparisonBar(
                item: item,
                color: _comparisonColor(dashboard.comparison.indexOf(item)),
              ),
              if (item != dashboard.comparison.last) const SizedBox(height: 14),
            ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: AppColors.brandTeal,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _localizedDashboardPhrase(context, dashboard.standing),
                    style: TextStyle(
                      color: AppColors.bodyText,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(DashboardSchedule item) {
    final color = _statusColor(item.status);
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.time,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(text: item.status, color: color),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.room} - ${item.teacher}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekScheduleList(List<DashboardSchedule> items) {
    if (items.isEmpty) {
      return _EmptyPanel(
        icon: Icons.event_available_outlined,
        title: context.tr('No more classes this week'),
        subtitle: context.tr('Next week schedule will appear when available.'),
      );
    }

    return _Panel(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: _weekScheduleChildren(items)),
    );
  }

  Widget _monthAttendanceGrid(DashboardMonthAttendance summary) {
    final statusItems = summary.statuses.isNotEmpty
        ? summary.statuses
              .map(
                (status) => _AttendanceStatusItem(
                  label: _localizedStatus(context, status.label),
                  value: '${status.count}',
                  icon: _attendanceStatusIcon(status.status),
                  color: _attendanceStatusColor(status.status),
                ),
              )
              .toList()
        : [
            _AttendanceStatusItem(
              label: context.tr('Present'),
              value: '${summary.present}',
              icon: Icons.how_to_reg_outlined,
              color: AppColors.green,
            ),
            _AttendanceStatusItem(
              label: context.tr('Absent'),
              value: '${summary.absent}',
              icon: Icons.cancel_outlined,
              color: AppColors.rose,
            ),
            _AttendanceStatusItem(
              label: context.tr('Permission'),
              value: '${summary.permission}',
              icon: Icons.approval_outlined,
              color: AppColors.brandBlue,
            ),
            _AttendanceStatusItem(
              label: context.tr('Late'),
              value: '${summary.late}',
              icon: Icons.schedule_outlined,
              color: AppColors.orange,
            ),
            _AttendanceStatusItem(
              label: context.tr('Issues'),
              value: '${summary.issues}',
              icon: Icons.report_problem_outlined,
              color: AppColors.purple,
            ),
          ];
    final items = [
      ...statusItems,
      _AttendanceStatusItem(
        label: context.tr('Blacklist'),
        value: summary.blacklisted ? context.tr('Yes') : context.tr('No'),
        icon: Icons.block_outlined,
        color: summary.blacklisted ? AppColors.rose : AppColors.mutedText,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 3 : 2;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 94,
          ),
          itemBuilder: (context, index) =>
              _AttendanceStatusTile(item: items[index]),
        );
      },
    );
  }

  Widget _semesterResultCard(StudentGpaTranscript? transcript) {
    final latest = transcript?.histories.isNotEmpty == true
        ? transcript!.histories.first
        : null;

    if (latest == null) {
      return _EmptyPanel(
        icon: Icons.pending_actions_outlined,
        title: context.tr('Semester result pending'),
        subtitle: context.tr(
          'The full result will appear after the teacher ends the semester.',
        ),
      );
    }

    final isFinalized =
        latest.resultStatus.toLowerCase() == 'finalized' &&
        latest.subjectGrades.isNotEmpty;
    final statusColor = isFinalized ? AppColors.green : AppColors.orange;

    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${latest.classGroupName} - ${latest.majorName}',
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
              _StatusPill(
                text: isFinalized ? 'Finalized' : latest.resultStatus,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 4 : 2;
              final stats = [
                _ResultStat(
                  label: context.tr('Semester GPA'),
                  value: latest.semesterGpa.toStringAsFixed(2),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.brandTeal,
                ),
                _ResultStat(
                  label: context.tr('Cumulative GPA'),
                  value: latest.cumulativeGpa.toStringAsFixed(2),
                  icon: Icons.timeline_rounded,
                  color: AppColors.brandBlue,
                ),
                _ResultStat(
                  label: context.tr('Credits'),
                  value: _formatScore(latest.totalCredits),
                  icon: Icons.credit_score_outlined,
                  color: AppColors.purple,
                ),
                _ResultStat(
                  label: context.tr('Subjects'),
                  value: '${latest.subjectGrades.length}',
                  icon: Icons.menu_book_outlined,
                  color: AppColors.orange,
                ),
              ];

              return GridView.builder(
                itemCount: stats.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 72,
                ),
                itemBuilder: (context, index) =>
                    _ResultStatTile(stat: stats[index]),
              );
            },
          ),
          const SizedBox(height: 14),
          if (!isFinalized)
            _SemesterPendingNotice(
              text: context.tr(
                'The semester is still in progress. Only status is available now.',
              ),
            )
          else ...[
            for (final subject in latest.subjectGrades) ...[
              _SemesterSubjectScoreRow(subject: subject),
              if (subject != latest.subjectGrades.last)
                const Divider(height: 18),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _weekScheduleChildren(List<DashboardSchedule> items) {
    final children = <Widget>[];
    String? currentDay;

    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      if (item.dayLabel != currentDay) {
        currentDay = item.dayLabel;
        children.add(_WeekDayHeader(label: item.dayLabel, date: item.date));
      }
      children.add(_WeekScheduleRow(item: item));
      if (index != items.length - 1) {
        children.add(const Divider(height: 1, indent: 18, endIndent: 18));
      }
    }

    return children;
  }

  Widget _quickActionGrid(List<DashboardService> actions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 6 : 3;
        return GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];
            final color = _serviceColor(item.icon);
            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(_serviceRoute(item.icon, item.label)),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_serviceIcon(item.icon), color: color, size: 27),
                      const SizedBox(height: 8),
                      Text(
                        _localizedDashboardPhrase(context, item.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
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

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _closeDrawerAndPush(String routeName) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(routeName);
  }

  void _closeDrawerAndScroll(GlobalKey key) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(key));
  }
}

class _StudentHomeDrawer extends StatelessWidget {
  const _StudentHomeDrawer({
    required this.studentName,
    required this.studentDetail,
    required this.profilePhotoUrl,
    required this.isLoggingOut,
    required this.onHome,
    required this.onProfile,
    required this.onSchedule,
    required this.onAttendance,
    required this.onGrades,
    required this.onGpa,
    required this.onDocuments,
    required this.onPermissions,
    required this.onAbout,
    required this.onLogout,
  });

  final String studentName;
  final String studentDetail;
  final String profilePhotoUrl;
  final bool isLoggingOut;
  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onSchedule;
  final VoidCallback onAttendance;
  final VoidCallback onGrades;
  final VoidCallback onGpa;
  final VoidCallback onDocuments;
  final VoidCallback onPermissions;
  final VoidCallback onAbout;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final photoUrl = _resolveImageUrl(profilePhotoUrl);
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brandBlue,
                    backgroundImage: photoUrl.isEmpty
                        ? null
                        : NetworkImage(photoUrl),
                    child: photoUrl.isEmpty
                        ? Text(
                            _initials(studentName),
                            style: TextStyle(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Navigation'),
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          studentDetail,
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
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const ThemeModeSelector(),
                  const Divider(height: 16),
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: context.tr('Home'),
                    onTap: onHome,
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: context.tr('View profile'),
                    onTap: onProfile,
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: context.tr('Schedule'),
                    onTap: onSchedule,
                  ),
                  _DrawerItem(
                    icon: Icons.query_stats_rounded,
                    label: context.tr('Grades'),
                    onTap: onGrades,
                  ),
                  _DrawerItem(
                    icon: Icons.school_rounded,
                    label: context.tr('GPA'),
                    onTap: onGpa,
                  ),
                  _DrawerItem(
                    icon: Icons.folder_copy_outlined,
                    label: context.tr('Documents'),
                    onTap: onDocuments,
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_late_outlined,
                    label: context.tr('Pre-permission'),
                    onTap: onPermissions,
                  ),
                  _DrawerItem(
                    icon: Icons.fact_check_outlined,
                    label: context.tr('Attendance'),
                    onTap: onAttendance,
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: context.tr('About'),
                    onTap: onAbout,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: isLoggingOut
                  ? context.tr('Signing out...')
                  : context.tr('Logout'),
              onTap: isLoggingOut ? null : onLogout,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon, color: colors.primary),
      title: Text(
        label,
        style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w800),
      ),
      onTap: onTap,
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.notifications),
          icon: Icon(Icons.notifications_none_rounded),
          tooltip: context.tr('Notifications'),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -1,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: AppColors.rose,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.data,
    required this.icon,
    required this.color,
  });

  final DashboardPerformance data;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _localizedDashboardPhrase(context, data.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      data.value,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (data.progress.clamp(0, 100)) / 100,
                    minHeight: 7,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.14),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _localizedDashboardPhrase(context, data.detail),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({required this.item, required this.color});

  final DashboardComparison item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            context.tr(item.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (item.score.clamp(0, 100)) / 100,
              minHeight: 13,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '${item.score}%',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xDDEAF4FF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatusItem {
  const _AttendanceStatusItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _AttendanceStatusTile extends StatelessWidget {
  const _AttendanceStatusTile({required this.item});

  final _AttendanceStatusItem item;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
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

class _ResultStat {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ResultStatTile extends StatelessWidget {
  const _ResultStatTile({required this.stat});

  final _ResultStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(stat.icon, color: stat.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
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

class _SemesterPendingNotice extends StatelessWidget {
  const _SemesterPendingNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterSubjectScoreRow extends StatelessWidget {
  const _SemesterSubjectScoreRow({required this.subject});

  final GpaSubjectGrade subject;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(subject.totalScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${subject.subjectCode} - ${context.tr('Credits')} ${_formatScore(subject.credit)}',
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
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _formatScore(subject.totalScore),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subject.letterGrade,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ScoreChip(
              label: context.tr('Attendance'),
              value: subject.attendanceScore,
            ),
            _ScoreChip(
              label: context.tr('Midterm'),
              value: subject.midtermScore,
            ),
            _ScoreChip(
              label: context.tr('Assignment'),
              value: subject.assignmentScore,
            ),
            _ScoreChip(label: context.tr('Final'), value: subject.finalScore),
            _ScoreChip(label: context.tr('GP'), value: subject.gradePoint),
          ],
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label ${_formatScore(value)}',
        style: TextStyle(
          color: AppColors.bodyText,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
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
        _localizedStatus(context, text),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WeekDayHeader extends StatelessWidget {
  const _WeekDayHeader({required this.label, required this.date});

  final String label;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: AppColors.brandBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (date.isNotEmpty)
            Text(
              date,
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

class _WeekScheduleRow extends StatelessWidget {
  const _WeekScheduleRow({required this.item});

  final DashboardSchedule item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              item.time,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.room} - ${item.teacher}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(text: item.status, color: color),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w600,
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

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.w700),
    );
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
              context.tr('Could not load student dashboard'),
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
              icon: Icon(Icons.refresh_rounded),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HomeMenuAction { profile, logout }

class _StudentHomeData {
  const _StudentHomeData({
    required this.dashboard,
    required this.transcript,
    required this.notifications,
  });

  final StudentDashboard dashboard;
  final StudentGpaTranscript? transcript;
  final AppNotificationFeed? notifications;
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p.characters.first).join();
  return letters.isEmpty ? 'SV' : letters.toUpperCase();
}

String _resolveImageUrl(String value) {
  return ApiConfig.resolveUrl(value);
}

String _localizedDashboardPhrase(BuildContext context, String value) {
  final text = value.trim();
  if (text.isEmpty) return text;

  const cumulativePrefix = 'Cumulative ';
  if (text.startsWith(cumulativePrefix)) {
    return context.l10n.format('Cumulative {value}', {
      'value': text.substring(cumulativePrefix.length),
    });
  }

  final normalized = switch (text) {
    'Excellent standing' => 'Excellent',
    'In good standing' => 'Good',
    'Monitor attendance' => 'Warning',
    'Needs attention' => 'Attention',
    'Classes scheduled' => 'Scheduled classes',
    _ => text,
  };

  return context.tr(normalized);
}

String _localizedStatus(BuildContext context, String value) {
  final normalized = switch (value.trim().toLowerCase()) {
    'present' => 'Present',
    'late' => 'Late',
    'absent' => 'Absent',
    'permission' => 'Permission',
    'excused' => 'Permission',
    'issues' => 'Issues',
    'issue' => 'Issues',
    'skipped' => 'Skipped',
    'active' => 'Active',
    'scheduled' => 'Scheduled',
    'completed' => 'Completed',
    _ => value.trim(),
  };

  return context.tr(normalized);
}

IconData _metricIcon(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('gpa')) return Icons.trending_up_rounded;
  if (lower.contains('assignment') || lower.contains('remaining')) {
    return Icons.assignment_turned_in_outlined;
  }
  return Icons.fact_check_outlined;
}

Color _metricColor(int index) {
  const colors = [AppColors.brandTeal, AppColors.brandBlue, AppColors.orange];
  return colors[index % colors.length];
}

Color _comparisonColor(int index) {
  const colors = [AppColors.brandBlue, AppColors.brandTeal, AppColors.orange];
  return colors[index % colors.length];
}

Color _statusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('active')) return AppColors.green;
  if (lower.contains('scheduled')) return AppColors.brandBlue;
  return AppColors.purple;
}

IconData _attendanceStatusIcon(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('present')) return Icons.how_to_reg_outlined;
  if (lower.contains('late')) return Icons.schedule_outlined;
  if (lower.contains('absent')) return Icons.cancel_outlined;
  if (lower.contains('permission') || lower.contains('excused')) {
    return Icons.approval_outlined;
  }
  if (lower.contains('issue')) return Icons.report_problem_outlined;
  if (lower.contains('active')) return Icons.play_circle_outline_rounded;
  if (lower.contains('scheduled')) return Icons.event_available_outlined;
  if (lower.contains('skipped')) return Icons.skip_next_rounded;
  if (lower.contains('completed')) return Icons.task_alt_rounded;
  return Icons.fact_check_outlined;
}

Color _attendanceStatusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('present')) return AppColors.green;
  if (lower.contains('late')) return AppColors.orange;
  if (lower.contains('absent')) return AppColors.rose;
  if (lower.contains('permission') || lower.contains('excused')) {
    return AppColors.brandBlue;
  }
  if (lower.contains('issue')) return AppColors.purple;
  if (lower.contains('active')) return AppColors.green;
  if (lower.contains('scheduled')) return AppColors.brandTeal;
  if (lower.contains('skipped')) return AppColors.mutedText;
  if (lower.contains('completed')) return AppColors.purple;
  return AppColors.brandBlue;
}

Color _scoreColor(double score) {
  if (score >= 85) return AppColors.green;
  if (score >= 70) return AppColors.brandTeal;
  if (score >= 50) return AppColors.orange;
  return AppColors.rose;
}

String _formatScore(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _serviceRoute(String icon, String label) {
  return switch (icon) {
    'attendance' => AppRoutes.attendance,
    'grades' => AppRoutes.grades,
    'documents' => AppRoutes.documents,
    'payments' || 'payment' => AppRoutes.payments,
    'library' => AppRoutes.library,
    'support' => AppRoutes.support,
    'courses' || 'course' => AppRoutes.courses,
    _ => '/unavailable/${Uri.encodeComponent(label)}',
  };
}

IconData _serviceIcon(String icon) {
  return switch (icon) {
    'grades' => Icons.bar_chart_rounded,
    'attendance' => Icons.qr_code_scanner_rounded,
    'payments' => Icons.account_balance_wallet_outlined,
    'library' => Icons.local_library_outlined,
    'documents' => Icons.folder_copy_outlined,
    'support' => Icons.support_agent_rounded,
    _ => Icons.apps_rounded,
  };
}

Color _serviceColor(String icon) {
  return switch (icon) {
    'grades' => AppColors.orange,
    'attendance' => AppColors.brandTeal,
    'payments' => AppColors.purple,
    'library' => AppColors.green,
    'documents' => AppColors.brandBlue,
    'support' => AppColors.rose,
    _ => AppColors.mutedText,
  };
}
