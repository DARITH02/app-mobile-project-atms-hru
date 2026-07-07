import 'package:flutter/material.dart';
import 'package:hru_atms/app/app_routes.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/l10n/language_controller.dart';
import 'package:hru_atms/app/theme/app_theme.dart';
import 'package:hru_atms/app/theme/theme_controller.dart';
import 'package:hru_atms/core/system/system_status_repository.dart';
import 'package:hru_atms/features/about/presentation/pages/about_page.dart';
import 'package:hru_atms/features/attendance/presentation/pages/student_attendance_page.dart';
import 'package:hru_atms/features/attendance/presentation/pages/student_qr_scan_page.dart';
import 'package:hru_atms/features/attendance/presentation/pages/teacher_attendance_page.dart';
import 'package:hru_atms/features/attendance/presentation/pages/teacher_qr_check_in_page.dart';
import 'package:hru_atms/features/auth/data/auth_repository.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:hru_atms/features/auth/presentation/pages/login_page.dart';
import 'package:hru_atms/features/auth/presentation/pages/register_page.dart';
import 'package:hru_atms/features/classes/presentation/pages/teacher_classes_page.dart';
import 'package:hru_atms/features/documents/presentation/pages/teacher_documents_page.dart';
import 'package:hru_atms/features/documents/presentation/pages/student_documents_page.dart';
import 'package:hru_atms/features/grades/presentation/pages/student_grades_page.dart';
import 'package:hru_atms/features/gpa/presentation/pages/student_gpa_page.dart';
import 'package:hru_atms/features/home/presentation/pages/home_router_page.dart';
import 'package:hru_atms/features/notifications/presentation/pages/notifications_page.dart';
import 'package:hru_atms/features/permissions/presentation/pages/student_permission_page.dart';
import 'package:hru_atms/features/permissions/presentation/pages/teacher_permission_request_page.dart';
import 'package:hru_atms/features/profile/presentation/pages/student_profile_page.dart';
import 'package:hru_atms/features/schedules/presentation/pages/teacher_schedules_page.dart';
import 'package:hru_atms/features/students/presentation/pages/teacher_students_page.dart';
import 'package:hru_atms/shared/widgets/app_error_page.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/maintenance_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class HruStudentPortalApp extends StatefulWidget {
  const HruStudentPortalApp({super.key});

  @override
  State<HruStudentPortalApp> createState() => _HruStudentPortalAppState();
}

class _HruStudentPortalAppState extends State<HruStudentPortalApp> {
  late final AuthRepository _authRepository;
  late final SystemStatusRepository _statusRepository;
  late Future<_StartupState> _startupFuture;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _statusRepository = SystemStatusRepository();
    _startupFuture = _loadStartupState();
  }

  Future<_StartupState> _loadStartupState() async {
    final status = await _statusRepository.check();
    final hasSavedSession = await AuthSessionStore().hasToken();
    return _StartupState(status: status, hasSavedSession: hasSavedSession);
  }

  Future<void> _retryStartupCheck() async {
    final future = _loadStartupState();
    setState(() => _startupFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.instance,
      builder: (context, locale, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance,
          builder: (context, themeMode, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'HRU',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: FutureBuilder<_StartupState>(
                future: _startupFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const _AppLoadingScreen();
                  }

                  final startup = snapshot.data!;
                  if (startup.status.isMaintenance) {
                    return MaintenancePage(
                      message: startup.status.message,
                      onRetry: _retryStartupCheck,
                    );
                  }

                  if (startup.hasSavedSession) {
                    return HomeRouterPage(authRepository: _authRepository);
                  }

                  return LoginPage(authRepository: _authRepository);
                },
              ),
              onGenerateRoute: _buildRoute,
              onUnknownRoute: (settings) {
                return _FixedMenuPageRoute<dynamic>(
                  settings: settings,
                  builder: (context) => AppErrorPage(
                    title: context.tr('Page not available'),
                    message: context.tr(
                      'This feature is not available in the mobile app yet.',
                    ),
                    details: settings.name,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Route<dynamic>? _buildRoute(RouteSettings settings) {
    final WidgetBuilder? builder = switch (settings.name) {
      AppRoutes.login => (context) => LoginPage(
        authRepository: _authRepository,
      ),
      AppRoutes.register => (context) => const RegisterPage(),
      AppRoutes.home => (context) => HomeRouterPage(
        authRepository: _authRepository,
      ),
      AppRoutes.attendance => (context) => const StudentAttendancePage(),
      AppRoutes.studentQrScan => (context) => const StudentQrScanPage(),
      AppRoutes.studentPermissions =>
        (context) => const StudentPermissionPage(),
      AppRoutes.grades => (context) => const StudentGradesPage(),
      AppRoutes.gpa => (context) => const StudentGpaPage(),
      AppRoutes.documents => (context) => const StudentDocumentsPage(),
      AppRoutes.profile => (context) => const StudentProfilePage(),
      AppRoutes.teacherClasses => (context) => const TeacherClassesPage(),
      AppRoutes.teacherDocuments => (context) => const TeacherDocumentsPage(),
      AppRoutes.teacherStudents => (context) => const TeacherStudentsPage(),
      AppRoutes.teacherSchedules => (context) => const TeacherSchedulesPage(),
      AppRoutes.teacherAttendance => (context) => const TeacherAttendancePage(),
      AppRoutes.teacherQrCheckIn => (context) => const TeacherQrCheckInPage(),
      AppRoutes.notifications => (context) => const NotificationsPage(),
      AppRoutes.about => (context) => const AboutPage(),
      AppRoutes.teacherPermissions =>
        (context) => const TeacherPermissionRequestPage(),
      _ => null,
    };

    if (builder == null) return null;
    return _FixedMenuPageRoute<dynamic>(settings: settings, builder: builder);
  }
}

class _FixedMenuPageRoute<T> extends PageRouteBuilder<T> {
  _FixedMenuPageRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) : super(
         settings: settings,
         transitionDuration: Duration.zero,
         reverseTransitionDuration: Duration.zero,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
       );
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoadingScreen());
  }
}

class _StartupState {
  const _StartupState({required this.status, required this.hasSavedSession});

  final SystemStatus status;
  final bool hasSavedSession;
}
