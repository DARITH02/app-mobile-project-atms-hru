import 'package:flutter/material.dart';
import 'package:hru_atms/app/app.dart';
import 'package:hru_atms/app/l10n/language_controller.dart';
import 'package:hru_atms/app/theme/theme_controller.dart';
import 'package:hru_atms/core/notifications/schedule_notification_service.dart';
import 'package:hru_atms/shared/widgets/app_error_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) {
    return AppErrorView(
      title: 'Something went wrong',
      message: 'The app found a problem while opening this view.',
      details: details.exceptionAsString(),
    );
  };
  await LanguageController.instance.load();
  await ThemeController.instance.load();
  await ScheduleNotificationService.instance.initialize();
  runApp(const HruStudentPortalApp());
}
