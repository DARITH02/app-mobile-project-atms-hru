import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_config.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/core/notifications/schedule_notification_service.dart';
import 'package:hru_atms/features/auth/data/auth_repository.dart';
import 'package:hru_atms/features/home/data/teacher_dashboard_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/language_toggle_button.dart';
import 'package:hru_atms/shared/widgets/maintenance_page.dart';
import 'package:hru_atms/shared/widgets/teacher_bottom_navigation.dart';
import 'package:hru_atms/shared/widgets/theme_mode_selector.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TeacherDashboardRepository _repository;
  late Future<TeacherDashboard> _dashboardFuture;
  final _overviewKey = GlobalKey();
  final _performanceKey = GlobalKey();
  final _scheduleKey = GlobalKey();
  final _chatKey = GlobalKey();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _repository = TeacherDashboardRepository();
    _dashboardFuture = _loadDashboard();
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  Future<TeacherDashboard> _loadDashboard() async {
    final dashboard = await _repository.fetchDashboard();
    await ScheduleNotificationService.instance.scheduleTeacherSessionReminders(
      dashboard.sessions,
    );
    await ScheduleNotificationService.instance
        .scheduleTeacherDailyScheduleAlarms(dashboard.sessions);
    return dashboard;
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
        child: FutureBuilder<TeacherDashboard>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingScreen();
            }
            final error = snapshot.error;
            if (error is ApiException && error.statusCode == 503) {
              return MaintenancePage(message: error.message, onRetry: _refresh);
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _ErrorState(onRetry: _refresh);
            }

            final dashboard = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
              children: [
                _Header(
                  teacherName: dashboard.summary.teacher,
                  profilePhotoUrl: dashboard.summary.profilePhotoUrl,
                  isLoggingOut: _isLoggingOut,
                  onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onViewProfile: () =>
                      Navigator.of(context).pushNamed(AppRoutes.profile),
                  onNotifications: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                  onLogout: _logout,
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _overviewKey,
                  child: _HeroKpi(summary: dashboard.summary),
                ),
                const SizedBox(height: 14),
                _KpiGrid(dashboard: dashboard),
                const SizedBox(height: 12),
                _ScanAttendanceShortcut(
                  summary: dashboard.summary,
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.teacherQrCheckIn),
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _performanceKey,
                  child: _ActionSectionHeader(
                    title: context.tr('Class performance'),
                    subtitle: context.l10n.format('{count} assigned classes', {
                      'count': '${dashboard.classes.length}',
                    }),
                    actionLabel: context.tr('View all'),
                    onAction: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.teacherClasses),
                  ),
                ),
                _PerformancePanel(classes: dashboard.topClasses),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Needs attention',
                  subtitle: context.tr('Lowest attendance classes'),
                ),
                _AttentionPanel(classes: dashboard.attentionClasses),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _scheduleKey,
                  child: _SectionHeader(
                    title: context.tr('Schedule'),
                    subtitle: context.l10n.format('{count} recent sessions', {
                      'count': '${dashboard.sessions.length}',
                    }),
                  ),
                ),
                _SchedulePanel(sessions: dashboard.sessions.take(5).toList()),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: _chatKey,
                  child: _SectionHeader(
                    title: context.tr('Chat'),
                    subtitle: context.tr('Messages'),
                  ),
                ),
                _ChatPanel(
                  classesCount: dashboard.summary.totalClasses,
                  studentsCount: dashboard.summary.totalStudents,
                ),
              ],
            );
          },
        ),
      ),
      drawer: FutureBuilder<TeacherDashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data?.summary;
          return _TeacherHomeDrawer(
            teacherName: summary?.teacher ?? context.tr('Teacher'),
            profilePhotoUrl: summary?.profilePhotoUrl ?? '',
            isLoggingOut: _isLoggingOut,
            onHome: () => _closeDrawerAndScroll(_overviewKey),
            onProfile: () => _closeDrawerAndPush(AppRoutes.profile),
            onClasses: () => _closeDrawerAndPush(AppRoutes.teacherClasses),
            onDocuments: () => _closeDrawerAndPush(AppRoutes.teacherDocuments),
            onStudents: () => _closeDrawerAndPush(AppRoutes.teacherStudents),
            onSchedules: () => _closeDrawerAndPush(AppRoutes.teacherSchedules),
            onAttendance: () =>
                _closeDrawerAndPush(AppRoutes.teacherAttendance),
            onPermissions: () =>
                _closeDrawerAndPush(AppRoutes.teacherPermissions),
            onNotifications: () => _closeDrawerAndPush(AppRoutes.notifications),
            onAbout: () => _closeDrawerAndPush(AppRoutes.about),
            onLogout: _logout,
          );
        },
      ),
      bottomNavigationBar: TeacherBottomNavigation(
        current: TeacherNavDestination.home,
        onCurrentTap: () => _scrollTo(_overviewKey),
        replaceRoutes: false,
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

class _TeacherHomeDrawer extends StatelessWidget {
  const _TeacherHomeDrawer({
    required this.teacherName,
    required this.profilePhotoUrl,
    required this.isLoggingOut,
    required this.onHome,
    required this.onProfile,
    required this.onClasses,
    required this.onDocuments,
    required this.onStudents,
    required this.onSchedules,
    required this.onAttendance,
    required this.onPermissions,
    required this.onNotifications,
    required this.onAbout,
    required this.onLogout,
  });

  final String teacherName;
  final String profilePhotoUrl;
  final bool isLoggingOut;
  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onClasses;
  final VoidCallback onDocuments;
  final VoidCallback onStudents;
  final VoidCallback onSchedules;
  final VoidCallback onAttendance;
  final VoidCallback onPermissions;
  final VoidCallback onNotifications;
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
                            _initials(teacherName),
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
                          teacherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
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
                    icon: Icons.dashboard_rounded,
                    label: context.tr('Home'),
                    onTap: onHome,
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: context.tr('View profile'),
                    onTap: onProfile,
                  ),
                  _DrawerItem(
                    icon: Icons.school_outlined,
                    label: context.tr('My classes'),
                    onTap: onClasses,
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: context.tr('Documents'),
                    onTap: onDocuments,
                  ),
                  _DrawerItem(
                    icon: Icons.groups_2_outlined,
                    label: context.tr('Students'),
                    onTap: onStudents,
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: context.tr('Schedule'),
                    onTap: onSchedules,
                  ),
                  _DrawerItem(
                    icon: Icons.fact_check_outlined,
                    label: context.tr('My attendance'),
                    onTap: onAttendance,
                  ),
                  _DrawerItem(
                    icon: Icons.approval_outlined,
                    label: context.tr('Request'),
                    onTap: onPermissions,
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: context.tr('Notifications'),
                    onTap: onNotifications,
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

class _Header extends StatelessWidget {
  const _Header({
    required this.teacherName,
    required this.profilePhotoUrl,
    required this.isLoggingOut,
    required this.onOpenMenu,
    required this.onViewProfile,
    required this.onNotifications,
    required this.onLogout,
  });

  final String teacherName;
  final String profilePhotoUrl;
  final bool isLoggingOut;
  final VoidCallback onOpenMenu;
  final VoidCallback onViewProfile;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final photoUrl = _resolveImageUrl(profilePhotoUrl);

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
                context.tr('Teacher Dashboard'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                teacherName,
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
        IconButton.filledTonal(
          onPressed: onNotifications,
          icon: Icon(Icons.notifications_rounded),
          tooltip: context.tr('Notifications'),
        ),
        const SizedBox(width: 8),
        const LanguageToggleButton(),
        const SizedBox(width: 8),
        PopupMenuButton<_TeacherMenuAction>(
          tooltip: context.tr('Account menu'),
          onSelected: (action) {
            if (action == _TeacherMenuAction.profile) onViewProfile();
            if (action == _TeacherMenuAction.classes) {
              Navigator.of(context).pushNamed(AppRoutes.teacherClasses);
            }
            if (action == _TeacherMenuAction.notifications) {
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            }
            if (action == _TeacherMenuAction.permissions) {
              Navigator.of(context).pushNamed(AppRoutes.teacherPermissions);
            }
            if (action == _TeacherMenuAction.logout) onLogout();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _TeacherMenuAction.profile,
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 18),
                  SizedBox(width: 10),
                  Text(context.tr('View profile')),
                ],
              ),
            ),
            PopupMenuItem(
              value: _TeacherMenuAction.classes,
              child: Row(
                children: [
                  Icon(Icons.school_outlined, size: 18),
                  SizedBox(width: 10),
                  Text(context.tr('My classes')),
                ],
              ),
            ),
            PopupMenuItem(
              value: _TeacherMenuAction.notifications,
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 18),
                  SizedBox(width: 10),
                  Text(context.tr('Notifications')),
                ],
              ),
            ),
            PopupMenuItem(
              value: _TeacherMenuAction.permissions,
              child: Row(
                children: [
                  Icon(Icons.approval_outlined, size: 18),
                  SizedBox(width: 10),
                  Text(context.tr('Permission requests')),
                ],
              ),
            ),
            PopupMenuItem(
              value: _TeacherMenuAction.logout,
              enabled: !isLoggingOut,
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    isLoggingOut
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
            child: isLoggingOut
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : photoUrl.isEmpty
                ? Text(
                    _initials(teacherName),
                    style: TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _HeroKpi extends StatelessWidget {
  const _HeroKpi({required this.summary});

  final TeacherSummary summary;

  @override
  Widget build(BuildContext context) {
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
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
                      context.l10n.format('{count} students', {
                        'count': '${summary.totalStudents}',
                      }),
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n
                          .format('{classes} classes - {active} active now', {
                            'classes': '${summary.totalClasses}',
                            'active': '${summary.activeSessions}',
                          }),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (summary.attendanceRate.clamp(0, 100)) / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.format('{rate}% total attendance performance', {
              'rate': '${summary.attendanceRate}',
            }),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.dashboard});

  final TeacherDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        icon: Icons.school_outlined,
        label: context.tr('Classes'),
        value: '${dashboard.summary.totalClasses}',
        color: AppColors.brandBlue,
      ),
      _KpiItem(
        icon: Icons.event_available_outlined,
        label: context.tr('Sessions'),
        value: '${dashboard.summary.totalSessions}',
        color: AppColors.purple,
      ),
      _KpiItem(
        icon: Icons.how_to_reg_outlined,
        label: context.tr('Scans'),
        value: '${dashboard.summary.totalScans}',
        color: AppColors.green,
      ),
      _KpiItem(
        icon: Icons.play_circle_outline,
        label: context.tr('Active'),
        value: '${dashboard.summary.activeSessions}',
        color: AppColors.orange,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.85,
      ),
      itemBuilder: (context, index) => _KpiTile(item: items[index]),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.label,
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
        ],
      ),
    );
  }
}

class _ScanAttendanceShortcut extends StatelessWidget {
  const _ScanAttendanceShortcut({required this.summary, required this.onTap});

  final TeacherSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = summary.activeSessions > 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F172033),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Scan attendance'),
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
                      hasActiveSession
                          ? context.l10n.format(
                              '{count} active sessions ready to scan',
                              {'count': '${summary.activeSessions}'},
                            )
                          : context.tr('Open classes and choose a session'),
                      maxLines: 2,
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
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onTap,
                icon: Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(context.tr('Start')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel({required this.classes});

  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return _EmptyPanel(
        icon: Icons.bar_chart_rounded,
        title: context.tr('No class performance yet'),
        subtitle: context.tr('Assigned class performance will appear here.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          for (final item in classes) ...[
            _ClassPerformanceRow(item: item),
            if (item != classes.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ClassPerformanceRow extends StatelessWidget {
  const _ClassPerformanceRow({required this.item});

  final TeacherClass item;

  @override
  Widget build(BuildContext context) {
    final color = item.efficacy >= 85
        ? AppColors.green
        : item.efficacy >= 70
        ? AppColors.orange
        : AppColors.rose;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${item.efficacy}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.format('{group} - {count} students', {
            'group': item.groupName,
            'count': '${item.totalStudents}',
          }),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (item.efficacy.clamp(0, 100)) / 100,
            minHeight: 9,
            color: color,
            backgroundColor: const Color(0xFFE7ECF3),
          ),
        ),
      ],
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({required this.classes});

  final List<TeacherClass> classes;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return _EmptyPanel(
        icon: Icons.insights_outlined,
        title: context.tr('No attention list'),
        subtitle: context.tr('Classes with low performance will appear here.'),
      );
    }

    return Column(
      children: [
        for (final item in classes) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _panelDecoration(),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.priority_high_rounded,
                    color: AppColors.rose,
                  ),
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
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.format('{group} - {count} sessions', {
                          'group': item.groupName,
                          'count': '${item.sessionsCount}',
                        }),
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
                Text(
                  '${item.efficacy}%',
                  style: TextStyle(
                    color: AppColors.rose,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (item != classes.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({required this.sessions});

  final List<TeacherSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _EmptyPanel(
        icon: Icons.calendar_today_outlined,
        title: context.tr('No sessions scheduled'),
        subtitle: context.tr('Upcoming and recent sessions will appear here.'),
      );
    }

    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          for (final session in sessions) ...[
            _SessionTile(session: session),
            if (session != sessions.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final TeacherSession session;

  @override
  Widget build(BuildContext context) {
    final color = switch (session.status.toLowerCase()) {
      'active' => AppColors.green,
      'completed' => AppColors.brandBlue,
      _ => AppColors.orange,
    };

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.format('{time} - Room {room}', {
                    'time': _timeRange(session),
                    'room': session.room,
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (session.attendanceRate.clamp(0, 100)) / 100,
                    minHeight: 6,
                    color: color,
                    backgroundColor: const Color(0xFFE7ECF3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            session.status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({required this.classesCount, required this.studentsCount});

  final int classesCount;
  final int studentsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Class communication'),
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.format(
                    '{classes} classes and {students} students ready for messages.',
                    {'classes': '$classesCount', 'students': '$studentsCount'},
                  ),
                  maxLines: 2,
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
          IconButton.filledTonal(
            onPressed: () =>
                Navigator.of(context).pushNamed('/unavailable/chat'),
            icon: Icon(Icons.arrow_forward_rounded),
            tooltip: context.tr('Open chat'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
            subtitle,
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

class _ActionSectionHeader extends StatelessWidget {
  const _ActionSectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(actionLabel),
          ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
            Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('Could not load teacher dashboard'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Check the backend connection and try again.'),
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

class _KpiItem {
  const _KpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

enum _TeacherMenuAction { profile, classes, notifications, permissions, logout }

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

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts.map((part) => part[0].toUpperCase()).take(2).join();
}

String _resolveImageUrl(String value) {
  return ApiConfig.resolveUrl(value);
}

String _timeRange(TeacherSession session) {
  final start = _formatTime(session.startTime);
  final end = _formatTime(session.endTime);
  if (start == 'TBD' && end == 'TBD') return 'TBD';
  return '$start - $end';
}

String _formatTime(DateTime? value) {
  if (value == null) return 'TBD';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
