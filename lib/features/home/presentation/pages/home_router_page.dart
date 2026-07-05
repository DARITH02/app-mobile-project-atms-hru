import 'package:flutter/material.dart';
import 'package:hru_atms/features/auth/data/auth_repository.dart';
import 'package:hru_atms/features/auth/data/auth_session_store.dart';
import 'package:hru_atms/features/home/presentation/pages/student_portal_home_page.dart';
import 'package:hru_atms/features/home/presentation/pages/teacher_home_page.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';

class HomeRouterPage extends StatefulWidget {
  const HomeRouterPage({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<HomeRouterPage> createState() => _HomeRouterPageState();
}

class _HomeRouterPageState extends State<HomeRouterPage> {
  late final Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = AuthSessionStore().userRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: AppLoadingScreen());
        }

        if (snapshot.data == 'teacher') {
          return TeacherHomePage(authRepository: widget.authRepository);
        }

        return StudentPortalHomePage(authRepository: widget.authRepository);
      },
    );
  }
}
