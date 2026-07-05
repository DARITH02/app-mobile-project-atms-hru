# HRU ATMS Flutter App Documentation

## 1. Project Overview

HRU ATMS is a Flutter mobile application for HRU attendance and academic workflows. The app supports student and teacher users, connects to a Laravel backend API, stores authentication locally, and presents role-specific dashboards and tools.

Main goals:

- Let students view academic information, schedules, attendance, profile, and services.
- Let teachers manage assigned classes, students, schedules, attendance, QR check-in, documents, notifications, and permission requests.
- Provide a clean mobile interface for HRU attendance operations.
- Keep API communication separated from UI code through repository classes.

The Flutter app is located in:

```text
hru_atms/
```

The backend Laravel project is located next to it:

```text
hru-project-v2/
```

## 2. Technology Stack

### Mobile App

- Flutter: Cross-platform mobile framework.
- Dart SDK: `^3.12.2`.
- Material Design: Main UI system.
- `http`: REST API calls.
- `shared_preferences`: Local token/session storage.
- `google_fonts`: Typography.
- `image_picker`: Profile/document image selection.
- `mime` and `http_parser`: Multipart upload support.
- `flutter_local_notifications`: Local schedule reminders.
- `timezone`: Notification scheduling support.
- `mobile_scanner`: Teacher QR attendance scanning.
- `flutter_localizations`: Khmer and English localization.

### Backend Integration

- Laravel backend API.
- Bearer token authentication.
- JSON REST endpoints.
- API base URL configured by `ApiConfig`.

### Testing and Code Quality

- `flutter_test` for unit/widget tests.
- `flutter_lints` for recommended lint rules.
- Existing tests:
  - `test/auth_repository_test.dart`
  - `test/teacher_attendance_repository_test.dart`
  - `test/widget_test.dart`

## 3. Application Startup Workflow

The app starts from:

```text
lib/main.dart
```

The main app widget is:

```text
lib/app/app.dart
```

Startup flow:

1. Flutter starts the app.
2. `HruStudentPortalApp` initializes:
   - `AuthRepository`
   - `SystemStatusRepository`
3. The app checks system maintenance status.
4. The app checks whether a saved auth token exists in `SharedPreferences`.
5. If the backend is in maintenance mode, it shows `MaintenancePage`.
6. If a token exists, it opens `HomeRouterPage`.
7. If no token exists, it opens `LoginPage`.

Important startup classes:

```text
lib/app/app.dart
lib/core/system/system_status_repository.dart
lib/features/auth/data/auth_session_store.dart
lib/features/home/presentation/pages/home_router_page.dart
```

## 4. Routing Workflow

Routes are centralized in:

```text
lib/app/app_routes.dart
```

Main routes:

```text
/home
/login
/register
/profile
/teacher/classes
/teacher/documents
/teacher/students
/teacher/schedules
/teacher/attendance
/teacher/attendance/qr-check-in
/teacher/permissions
/notifications
/about
```

Routes are registered in `MaterialApp.routes` inside `app.dart`.

Unknown routes show:

```text
AppErrorPage
```

## 5. Project Folder Structure

The project follows a feature-first structure:

```text
lib/
  app/
  core/
  features/
  shared/
  main.dart
```

### `app/`

Contains app-wide configuration:

```text
app/
  app.dart
  app_routes.dart
  l10n/
  theme/
```

Responsibilities:

- App startup.
- Route registration.
- Theme configuration.
- Language/localization.

### `core/`

Contains low-level shared services:

```text
core/
  network/
  notifications/
  system/
```

Responsibilities:

- API base URL configuration.
- API exception model.
- Local notification scheduling.
- System maintenance status.

### `features/`

Contains product features. Each feature owns its data and presentation code.

Examples:

```text
features/auth/
features/home/
features/attendance/
features/schedules/
features/permissions/
features/students/
features/documents/
features/notifications/
features/profile/
```

Common pattern:

```text
feature_name/
  data/
  domain/
  presentation/
```

Not every feature has every layer yet.

### `shared/`

Contains reusable UI widgets:

```text
shared/widgets/
  app_error_page.dart
  app_loading_screen.dart
  app_logo.dart
  language_toggle_button.dart
  maintenance_page.dart
  section_header.dart
  teacher_bottom_navigation.dart
  theme_mode_selector.dart
```

Recent improvement:

- Teacher bottom navigation is now shared in `teacher_bottom_navigation.dart`.
- This avoids repeating the same navigation code across teacher pages.

## 6. Feature Modules

### Auth Feature

Path:

```text
lib/features/auth/
```

Main responsibilities:

- Login.
- Logout.
- Teacher registration.
- Save and clear auth session.

Important files:

```text
data/auth_repository.dart
data/auth_session_store.dart
data/teacher_registration_repository.dart
domain/models/auth_session.dart
domain/models/auth_user.dart
presentation/pages/login_page.dart
presentation/pages/register_page.dart
```

Login workflow:

1. User enters login credentials.
2. `AuthRepository.login()` sends the request to the backend.
3. Backend returns token and user.
4. `AuthSessionStore` saves token and user info.
5. App routes to `HomeRouterPage`.

### Home Feature

Path:

```text
lib/features/home/
```

Main responsibilities:

- Route users by role.
- Student dashboard.
- Teacher dashboard.
- Quick access cards.

Important pages:

```text
presentation/pages/home_router_page.dart
presentation/pages/student_portal_home_page.dart
presentation/pages/teacher_home_page.dart
```

Teacher dashboard loads:

- Summary cards.
- Class performance.
- Recent sessions.
- Notifications shortcut.
- QR attendance shortcut.

### Teacher Attendance Feature

Path:

```text
lib/features/attendance/
```

Main responsibilities:

- Teacher attendance history.
- Status summary.
- Permission/absent status handling.
- QR attendance check-in.

Important files:

```text
data/teacher_attendance_repository.dart
presentation/pages/teacher_attendance_page.dart
presentation/pages/teacher_qr_check_in_page.dart
```

Attendance workflow:

1. Page calls `TeacherAttendanceRepository.fetchAllSessions()`.
2. Repository loads teacher attendance sessions.
3. Repository loads correction/action records.
4. Approved corrections are applied to sessions.
5. UI groups records by subject.
6. UI shows all statuses:
   - Present
   - Late
   - Absent
   - Permission
   - Pending

QR workflow:

1. Teacher opens QR check-in page.
2. Camera scans QR code.
3. Token is submitted to:

```text
POST /teacher/attendance/qr/check-in
```

4. Backend validates token and marks check-in.
5. App shows success/error message.

### Teacher Schedules Feature

Path:

```text
lib/features/schedules/
```

Main responsibilities:

- Display teacher schedules.
- Group schedules by class group.
- Show status chips, including skipped sessions.

Important files:

```text
data/teacher_schedule_repository.dart
presentation/pages/teacher_schedules_page.dart
```

Schedule workflow:

1. `TeacherScheduleRepository.fetchAllSchedules()` loads all pages.
2. Schedules are grouped by class group.
3. UI shows each schedule item with:
   - Subject
   - Code
   - Time
   - Room
   - Session number
   - Status

Skipped status handling:

- The mobile model reads status from:
  - `source_attendance_session.status`
  - `attendance_session.attendance_status`
  - `attendance_session.status`
  - schedule `status`
- If status contains `skip`, the UI displays `Skip`.

### Teacher Permissions Feature

Path:

```text
lib/features/permissions/
```

Main responsibilities:

- Submit permission request.
- Select attendance session.
- Show existing permission request history.

Important files:

```text
data/teacher_permission_repository.dart
presentation/pages/teacher_permission_request_page.dart
```

Permission request workflow:

1. Teacher selects attendance session.
2. Teacher selects permission type.
3. Teacher enters reason.
4. App submits request to:

```text
POST /teacher/attendance/corrections
```

5. Backend stores the correction request.
6. Admin later approves or rejects it.

### Teacher Students Feature

Path:

```text
lib/features/students/
```

Main responsibilities:

- Show students grouped by teacher classes.
- Search students.
- Open student details.
- Show attendance stats/history.

Important files:

```text
data/teacher_students_repository.dart
presentation/pages/teacher_students_page.dart
```

### Teacher Documents Feature

Path:

```text
lib/features/documents/
```

Main responsibilities:

- Load teacher documents.
- Show status counts.
- Display document metadata and admin comments.

Important files:

```text
data/teacher_documents_repository.dart
presentation/pages/teacher_documents_page.dart
```

### Notifications Feature

Path:

```text
lib/features/notifications/
```

Main responsibilities:

- Load app notifications.
- Mark notifications as read.
- Display notification status.

Important files:

```text
data/notification_repository.dart
presentation/pages/notifications_page.dart
```

### Profile Feature

Path:

```text
lib/features/profile/
```

Main responsibilities:

- Load profile data.
- Update profile photo.
- Show student or teacher profile details.

Important files:

```text
data/student_profile_repository.dart
presentation/pages/student_profile_page.dart
```

## 7. Data Flow Pattern

The common data flow is:

```text
Page Widget
  -> Repository
    -> HTTP request
      -> Laravel API
    <- JSON response
  <- Dart model
Widget renders model
```

Example:

```text
TeacherAttendancePage
  -> TeacherAttendanceRepository.fetchAllSessions()
    -> GET /teacher/attendance/sessions
    -> GET /teacher/attendance/corrections
  -> List<TeacherAttendanceSession>
  -> UI summary and grouped cards
```

This pattern keeps API logic mostly outside the UI.

## 8. API Configuration

API settings are in:

```text
lib/core/network/api_config.dart
```

Default behavior:

- Web uses:

```text
http://localhost:8080/api
```

- Mobile/desktop uses:

```text
http://192.168.18.2:8080/api
```

You can override the base URL at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_SERVER/api
```

`ApiConfig.resolveUrl()` converts relative backend file paths into full URLs.

## 9. Authentication and Session Storage

Session storage is handled by:

```text
lib/features/auth/data/auth_session_store.dart
```

Stored values:

- `auth_token`
- `auth_user_name`
- `auth_user_role`

Repositories read the token and send:

```text
Authorization: Bearer <token>
```

If the token is missing, repositories throw:

```text
ApiException('Please sign in again.')
```

## 10. Error Handling

Common error class:

```text
lib/core/network/api_exception.dart
```

Repositories usually:

1. Decode backend response.
2. Check HTTP status code.
3. Extract `message`, `error`, or validation errors.
4. Throw `ApiException` for the UI to display.

UI pages typically show:

- Loading screen while waiting.
- Error state with Retry button.
- Empty state if data list is empty.

## 11. Localization

Localization is stored in:

```text
lib/app/l10n/app_localizations.dart
```

Supported languages:

- English
- Khmer

The app uses:

```dart
context.tr('Text')
context.l10n.format('Hello {name}', {'name': value})
```

Language state is controlled by:

```text
lib/app/l10n/language_controller.dart
```

## 12. Theme and UI System

Theme files:

```text
lib/app/theme/app_theme.dart
lib/app/theme/app_colors.dart
lib/app/theme/theme_controller.dart
```

The app supports:

- Light mode.
- Dark mode.
- System mode.

Common UI patterns:

- `AppColors.background`
- `AppColors.surface`
- `AppColors.primaryText`
- `AppColors.mutedText`
- `AppColors.brandBlue`

Shared UI widgets are in:

```text
lib/shared/widgets/
```

## 13. Teacher Navigation

Teacher bottom navigation is centralized in:

```text
lib/shared/widgets/teacher_bottom_navigation.dart
```

Destinations:

- Home
- My classes
- Schedule
- Request
- My attendance

Usage example:

```dart
bottomNavigationBar: const TeacherBottomNavigation(
  current: TeacherNavDestination.attendance,
),
```

This avoids duplicated menu code across teacher pages.

## 14. Notification Workflow

Local notifications are handled by:

```text
lib/core/notifications/schedule_notification_service.dart
```

Teacher dashboard loads sessions and schedules reminders.

Workflow:

1. Teacher dashboard loads sessions.
2. Notification service checks schedule times.
3. Local notifications are scheduled before class sessions.

## 15. Testing Workflow

Existing tests:

```text
test/auth_repository_test.dart
test/teacher_attendance_repository_test.dart
test/widget_test.dart
```

Recommended commands:

```bash
flutter test
flutter analyze
dart format --set-exit-if-changed lib test
```

Note: In the current local shell used during documentation creation, Dart/Flutter tooling was hanging. When the toolchain is healthy, these commands should be part of every maintenance pass.

## 16. How To Add A New Feature

Recommended steps:

1. Create a feature folder:

```text
lib/features/new_feature/
```

2. Add data layer:

```text
lib/features/new_feature/data/new_feature_repository.dart
```

3. Add models, either in:

```text
data/
```

or:

```text
domain/models/
```

4. Add page:

```text
lib/features/new_feature/presentation/pages/new_feature_page.dart
```

5. Add route constant in:

```text
lib/app/app_routes.dart
```

6. Register route in:

```text
lib/app/app.dart
```

7. Add navigation entry if needed.

8. Add tests for repository parsing or critical UI behavior.

## 17. Recommended Future Improvements

### 17.1 Split Large Pages

Some page files are large and should be split for better maintenance:

```text
teacher_home_page.dart
student_portal_home_page.dart
teacher_students_page.dart
teacher_schedules_page.dart
teacher_attendance_page.dart
```

Suggested structure:

```text
presentation/pages/teacher_home_page.dart
presentation/widgets/teacher_home_header.dart
presentation/widgets/teacher_kpi_grid.dart
presentation/widgets/teacher_schedule_panel.dart
presentation/widgets/teacher_attention_panel.dart
```

### 17.2 Extract JSON Helpers

Many repositories repeat:

```dart
_asMap()
_asList()
_int()
_shortTime()
```

Recommended shared file:

```text
lib/core/data/json_readers.dart
```

Example helpers:

```dart
Map<String, dynamic> asJsonMap(Object? value)
List<Map<String, dynamic>> asJsonList(Object? value)
int jsonInt(Object? value)
String shortTime(Object? value)
```

### 17.3 Extract Shared Decorations

Many pages repeat `_panelDecoration()`.

Recommended shared file:

```text
lib/shared/theme/app_decorations.dart
```

Example:

```dart
abstract final class AppDecorations {
  static BoxDecoration panel() { ... }
}
```

### 17.4 Improve API Client Layer

Current repositories manually:

- Build URLs.
- Add token headers.
- Decode JSON.
- Handle error status codes.

Recommended future abstraction:

```text
lib/core/network/api_client.dart
```

Possible methods:

```dart
Future<Map<String, dynamic>> getMap(String path)
Future<Map<String, dynamic>> postJson(String path, Map<String, Object?> body)
Future<List<Map<String, dynamic>>> getList(String path)
```

Benefits:

- Less repeated code.
- Consistent auth headers.
- Consistent error handling.
- Easier testing.

### 17.5 Improve Localization Structure

Current translations are stored in one Dart map. For bigger scale, consider ARB files:

```text
lib/l10n/app_en.arb
lib/l10n/app_km.arb
```

Benefits:

- Better Flutter tooling support.
- Easier translator workflow.
- Cleaner generated localization code.

## 18. Development Commands

Common commands:

```bash
flutter pub get
flutter run
flutter test
flutter analyze
dart format lib test
```

Run with custom API URL:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api
```

Build Android APK:

```bash
flutter build apk --release
```

Build web:

```bash
flutter build web --dart-define=API_BASE_URL=http://localhost:8080/api
```

## 19. Maintenance Checklist

Before merging changes:

1. Run formatter.
2. Run analyzer.
3. Run tests.
4. Check no duplicated widgets were introduced.
5. Check all API errors show clear user messages.
6. Check mobile layouts on small screen width.
7. Check both English and Khmer labels.
8. Check token/session behavior after logout.

Recommended commands:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## 20. Summary

The HRU ATMS Flutter app is organized around feature modules, repository-based API access, shared app-level routing/theme/localization, and role-specific workflows for students and teachers.

The current architecture is workable and understandable. The biggest next steps for long-term scaling are:

- Split large page files into smaller widgets.
- Extract repeated JSON parsing helpers.
- Extract repeated panel decoration.
- Add a shared API client.
- Move localization to ARB files if translation grows.

These improvements will make the app easier to maintain, easier to test, and easier to extend as HRU adds more mobile features.
