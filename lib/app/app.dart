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
              routes: {
                AppRoutes.login: (_) =>
                    LoginPage(authRepository: _authRepository),
                AppRoutes.register: (_) => const RegisterPage(),
                AppRoutes.home: (_) =>
                    HomeRouterPage(authRepository: _authRepository),
                AppRoutes.attendance: (_) => const StudentAttendancePage(),
                AppRoutes.studentQrScan: (_) => const StudentQrScanPage(),
                AppRoutes.studentPermissions: (_) =>
                    const StudentPermissionPage(),
                AppRoutes.grades: (_) => const StudentGradesPage(),
                AppRoutes.gpa: (_) => const StudentGpaPage(),
                AppRoutes.documents: (_) => const StudentDocumentsPage(),
                AppRoutes.profile: (_) => const StudentProfilePage(),
                AppRoutes.teacherClasses: (_) => const TeacherClassesPage(),
                AppRoutes.teacherDocuments: (_) => const TeacherDocumentsPage(),
                AppRoutes.teacherStudents: (_) => const TeacherStudentsPage(),
                AppRoutes.teacherSchedules: (_) => const TeacherSchedulesPage(),
                AppRoutes.teacherAttendance: (_) =>
                    const TeacherAttendancePage(),
                AppRoutes.teacherQrCheckIn: (_) => const TeacherQrCheckInPage(),
                AppRoutes.notifications: (_) => const NotificationsPage(),
                AppRoutes.about: (_) => const AboutPage(),
                AppRoutes.teacherPermissions: (_) =>
                    const TeacherPermissionRequestPage(),
              },
              onUnknownRoute: (settings) {
                return MaterialPageRoute<void>(
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
