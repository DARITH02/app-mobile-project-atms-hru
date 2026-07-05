import 'package:flutter_test/flutter_test.dart';
import 'package:hru_atms/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app shows login page when no saved session exists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HruStudentPortalApp());
    await tester.pumpAndSettle();

    expect(find.text('សូមស្វាគមន៍ការត្រឡប់មកវិញ'), findsOneWidget);
    expect(find.text('បន្តទៅផ្ទាំងគ្រប់គ្រង'), findsOneWidget);
    expect(find.text('និស្សិត'), findsOneWidget);
    expect(find.text('គ្រូបង្រៀន'), findsOneWidget);
    expect(find.text('អ៊ីមែល ឬលេខទូរស័ព្ទ'), findsOneWidget);
    expect(find.text('កូដនិស្សិត'), findsOneWidget);
    expect(find.text('ពាក្យសម្ងាត់'), findsNothing);
  });

  testWidgets('teacher role updates login identifier label', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HruStudentPortalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('គ្រូបង្រៀន'));
    await tester.pumpAndSettle();

    expect(find.text('អ៊ីមែល លេខទូរស័ព្ទ ឬកូដគ្រូ'), findsOneWidget);
    expect(find.text('ពាក្យសម្ងាត់'), findsOneWidget);
  });
}
