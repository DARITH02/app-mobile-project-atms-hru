import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('km'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isKhmer => locale.languageCode == 'km';

  String text(String english) {
    if (!isKhmer) return english;
    return _km[english] ?? english;
  }

  String format(String english, Map<String, String> values) {
    var value = text(english);
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((item) => item.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final language = locale.languageCode == 'en' ? 'en' : 'km';
    return AppLocalizations(Locale(language));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String english) => l10n.text(english);
}

const Map<String, String> _km = {
  'Pre-permission': 'សុំអនុញ្ញាតជាមុន',
  'Pre-permission request': 'សំណើសុំអនុញ្ញាតជាមុន',
  'Request before absence': 'ស្នើសុំមុនពេលអវត្តមាន',
  'Admin must approve or reject the request within 7 days.':
      'អ្នកគ្រប់គ្រងត្រូវអនុម័ត ឬបដិសេធសំណើក្នុងរយៈពេល ៧ ថ្ងៃ។',
  'My pre-permissions': 'សំណើសុំអនុញ្ញាតជាមុនរបស់ខ្ញុំ',
  'No pre-permission requests yet.': 'មិនទាន់មានសំណើសុំអនុញ្ញាតជាមុនទេ។',
  'Could not load pre-permission requests':
      'មិនអាចទាញយកសំណើសុំអនុញ្ញាតជាមុនបានទេ',
  'Could not load pre-permission requests.':
      'មិនអាចទាញយកសំណើសុំអនុញ្ញាតជាមុនបានទេ។',
  'Could not load request history. You can still submit a new request.':
      'មិនអាចទាញយកប្រវត្តិសំណើបានទេ។ អ្នកនៅតែអាចដាក់សំណើថ្មីបាន។',
  'Could not submit pre-permission request.':
      'មិនអាចដាក់សំណើសុំអនុញ្ញាតជាមុនបានទេ។',
  'Pre-permission request submitted.': 'បានដាក់សំណើសុំអនុញ្ញាតជាមុន។',
  'Pre-permission request submitted. Admin approval is required within 7 days.':
      'បានដាក់សំណើសុំអនុញ្ញាតជាមុន។ ត្រូវការការអនុម័តពីអ្នកគ្រប់គ្រងក្នុងរយៈពេល ៧ ថ្ងៃ។',
  'Start date': 'ថ្ងៃចាប់ផ្តើម',
  'End date': 'ថ្ងៃបញ្ចប់',
  'One session': 'មួយវគ្គ',
  'Many days': 'ច្រើនថ្ងៃ',
  'Choose session': 'ជ្រើសវគ្គ',
  'Please choose one session.': 'សូមជ្រើសវគ្គមួយ។',
  'Please choose one upcoming session.': 'សូមជ្រើសវគ្គខាងមុខមួយ។',
  'Please choose the start date and end date.':
      'សូមជ្រើសថ្ងៃចាប់ផ្តើម និងថ្ងៃបញ្ចប់។',
  'Submit request': 'ដាក់សំណើ',
  'Session: {subject}': 'វគ្គ៖ {subject}',
  'Submit': 'ដាក់ស្នើ',
  'Expires at {time}': 'ផុតកំណត់នៅ {time}',
  'Sick leave': 'ឈប់សម្រាកឈឺ',
  'School event': 'កម្មវិធីសាលា',
  'Personal permission': 'សុំអនុញ្ញាតផ្ទាល់ខ្លួន',
  'Official duty': 'ភារកិច្ចផ្លូវការ',
  'Other': 'ផ្សេងៗ',
  'expired': 'ផុតកំណត់',
  'HRU Student Portal': 'ប្រព័ន្ធវត្តមាននិស្សិត HRU',
  'Human Resource University': 'សាកលវិទ្យាល័យ ធនធានមនុស្ស',
  'Student Attendance Management System': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមាននិស្សិត',
  'Welcome back': 'សូមស្វាគមន៍ការត្រឡប់មកវិញ',
  'Sign in with your HRU account to continue.':
      'ចូលប្រើដោយគណនី HRU របស់អ្នក ដើម្បីបន្ត។',
  'Email': 'អ៊ីមែល',
  'Email or phone': 'អ៊ីមែល ឬលេខទូរស័ព្ទ',
  'Email, phone, or teacher code': 'អ៊ីមែល លេខទូរស័ព្ទ ឬកូដគ្រូ',
  'Student code': 'កូដនិស្សិត',
  'Password': 'ពាក្យសម្ងាត់',
  'Show password': 'បង្ហាញពាក្យសម្ងាត់',
  'Hide password': 'លាក់ពាក្យសម្ងាត់',
  'Signing in': 'កំពុងចូលប្រើ',
  'Signing in...': 'កំពុងចូលប្រើ...',
  'Sign in': 'ចូលប្រើ',
  'Continue to dashboard': 'បន្តទៅផ្ទាំងគ្រប់គ្រង',
  'Teacher account?': 'គណនីគ្រូ?',
  'Request access': 'ស្នើសុំចូលប្រើ',
  'Student': 'និស្សិត',
  'Teacher': 'គ្រូបង្រៀន',
  'Please enter your email.': 'សូមបញ្ចូលអ៊ីមែលរបស់អ្នក។',
  'Please enter your email or phone.': 'សូមបញ្ចូលអ៊ីមែល ឬលេខទូរស័ព្ទរបស់អ្នក។',
  'Please enter your login identifier.': 'សូមបញ្ចូលព័ត៌មានចូលប្រើរបស់អ្នក។',
  'Please enter your student code.': 'សូមបញ្ចូលកូដនិស្សិតរបស់អ្នក។',
  'Please enter your password.': 'សូមបញ្ចូលពាក្យសម្ងាត់របស់អ្នក។',
  'Could not connect to the HRU API. Check the backend server URL.':
      'មិនអាចភ្ជាប់ទៅ HRU API បានទេ។ សូមពិនិត្យ URL ម៉ាស៊ីនមេ។',
  'Teacher Account Registration': 'ការចុះឈ្មោះគណនីគ្រូ',
  'Request teacher access': 'ស្នើសុំសិទ្ធិចូលប្រើសម្រាប់គ្រូ',
  'Verify your email with OTP before submitting.':
      'សូមផ្ទៀងផ្ទាត់អ៊ីមែលដោយ OTP មុនពេលដាក់សំណើ។',
  'Students do not register here. Students sign in using email and student code from HRU records.':
      'និស្សិតមិនចុះឈ្មោះនៅទីនេះទេ។ និស្សិតចូលប្រើដោយអ៊ីមែល dនិងកូដនិស្សិតពីទិន្នន័យ HRU។',
  'Full name': 'ឈ្មោះពេញ',
  'Email OTP': 'លេខកូដ OTP អ៊ីមែល',
  'Phone': 'លេខទូរស័ព្ទ',
  'Department': 'ដេប៉ាតឺម៉ង់',
  'Specialization': 'ជំនាញ',
  'Confirm password': 'បញ្ជាក់ពាក្យសម្ងាត់',
  'OTP sent. Enter the 6-digit code below.':
      'បានផ្ញើ OTP។ សូមបញ្ចូលលេខកូដ ៦ ខ្ទង់ខាងក្រោម។',
  'Send OTP to verify this email.': 'ផ្ញើ OTP ដើម្បីផ្ទៀងផ្ទាត់អ៊ីមែលនេះ។',
  'Sending': 'កំពុងផ្ញើ',
  'Sending...': 'កំពុងផ្ញើ...',
  'Resend': 'ផ្ញើម្តងទៀត',
  'Send OTP': 'ផ្ញើ OTP',
  'Send code': 'ផ្ញើកូដ',
  'Submit teacher request': 'ដាក់សំណើគណនីគ្រូ',
  'Submitting': 'កំពុងដាក់សំណើ',
  'Submitting...': 'កំពុងដាក់សំណើ...',
  'Send request for approval': 'ផ្ញើសំណើសុំអនុម័ត',
  'Already approved?': 'បានអនុម័តរួចហើយ?',
  'Request sent for approval': 'បានផ្ញើសំណើសម្រាប់ការអនុម័ត',
  'Back to sign in': 'ត្រឡប់ទៅចូលប្រើ',
  'Please enter a valid email before sending OTP.':
      'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ មុនផ្ញើ OTP។',
  'Could not send verification code.': 'មិនអាចផ្ញើលេខកូដផ្ទៀងផ្ទាត់បានទេ។',
  'Verification code sent to {email}.': 'បានផ្ញើលេខកូដផ្ទៀងផ្ទាត់ទៅ {email}។',
  'Registration failed. Try again.': 'ការចុះឈ្មោះបរាជ័យ។ សូមព្យាយាមម្តងទៀត។',
  'Your teacher account request for {email} is waiting for HRU admin approval. You can sign in after the account is approved.':
      'សំណើគណនីគ្រូសម្រាប់ {email} កំពុងរង់ចាំការអនុម័តពីអ្នកគ្រប់គ្រង HRU។ អ្នកអាចចូលប្រើបានបន្ទាប់ពីគណនីត្រូវបានអនុម័ត។',
  'Please enter a valid email.': 'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ។',
  'Enter the 6-digit OTP.': 'សូមបញ្ចូល OTP ៦ ខ្ទង់។',
  'This field is required.': 'ត្រូវបំពេញវាលនេះ។',
  'Password must be at least 8 characters.':
      'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៨ តួអក្សរ។',
  'Passwords do not match.': 'ពាក្យសម្ងាត់មិនដូចគ្នាទេ។',
  'Student Dashboard': 'ផ្ទាំងគ្រប់គ្រងនិស្សិត',
  'Teacher Dashboard': 'ផ្ទាំងគ្រប់គ្រងគ្រូ',
  'Current Academic Term': 'វគ្គសិក្សាបច្ចុប្បន្ន',
  'Sessions': 'វគ្គរៀន',
  'Present': 'មានវត្តមាន',
  'Remaining': 'នៅសល់',
  'Comparison': 'ការប្រៀបធៀប',
  'Today schedule': 'កាលវិភាគថ្ងៃនេះ',
  'Today sessions': 'វគ្គថ្ងៃនេះ',
  'This week sessions': 'វគ្គក្នុងសប្តាហ៍នេះ',
  '{count} sessions': 'វគ្គរៀន {count}',
  'Next days this week': 'ថ្ងៃបន្ទាប់ក្នុងសប្តាហ៍នេះ',
  'No scheduled classes': 'មិនមានថ្នាក់ក្នុងកាលវិភាគ',
  'No sessions today': 'មិនមានវគ្គរៀនថ្ងៃនេះ',
  'No sessions this week': 'មិនមានវគ្គរៀនក្នុងសប្តាហ៍នេះ',
  'No more classes this week': 'មិនមានថ្នាក់បន្ថែមក្នុងសប្តាហ៍នេះ',
  'Your upcoming sessions will appear here.':
      'វគ្គរៀនខាងមុខរបស់អ្នកនឹងបង្ហាញនៅទីនេះ។',
  'Today sessions will appear here when available.':
      'វគ្គថ្ងៃនេះនឹងបង្ហាញនៅទីនេះពេលមាន។',
  'This week schedule will appear when available.':
      'កាលវិភាគសប្តាហ៍នេះនឹងបង្ហាញពេលមាន។',
  'Next week schedule will appear when available.':
      'កាលវិភាគសប្តាហ៍ក្រោយនឹងបង្ហាញពេលមាន។',
  'Recent': 'ថ្មីៗ',
  'Student services': 'សេវាកម្មនិស្សិត',
  'Quick access': 'ចូលប្រើរហ័ស',
  'Semester result': 'លទ្ធផលឆមាស',
  'Academic result': 'លទ្ធផលសិក្សា',
  'Semester result pending': 'លទ្ធផលឆមាសកំពុងរង់ចាំ',
  'The full result will appear after the teacher ends the semester.':
      'លទ្ធផលពេញលេញនឹងបង្ហាញ បន្ទាប់ពីគ្រូបញ្ចប់ឆមាស។',
  'The semester is still in progress. Only status is available now.':
      'ឆមាសកំពុងដំណើរការ។ ឥឡូវនេះមានតែស្ថានភាពប៉ុណ្ណោះ។',
  'Semester GPA': 'GPA ឆមាស',
  'Finalized': 'បានបញ្ចប់',
  'No recent chats': 'មិនមានការជជែកថ្មីៗ',
  'No comparison data available yet.': 'មិនទាន់មានទិន្នន័យប្រៀបធៀបទេ។',
  'Messages from teachers and support will appear here.':
      'សារពីគ្រូ និងក្រុមជំនួយនឹងបង្ហាញនៅទីនេះ។',
  'Grades': 'ពិន្ទុ',
  'GPA': 'GPA',
  'GPA Transcript': 'ព្រឹត្តប័ត្រពិន្ទុ',
  'Cumulative GPA': 'GPA សរុប',
  'Latest GPA': 'GPA ចុងក្រោយ',
  'Semesters': 'ឆមាស',
  'Credits': 'ក្រេឌីត',
  'GP': 'GP',
  'No transcript subjects yet.':
      'មិនទាន់មានមុខវិជ្ជាក្នុងព្រឹត្តប័ត្រពិន្ទុ ទេ។',
  'No GPA transcript records yet.': 'មិនទាន់មានកំណត់ត្រាព្រឹត្តប័ត្រពិន្ទុ ទេ។',
  'Could not load GPA transcript': 'មិនអាចទាញយកព្រឹត្តប័ត្រពិន្ទុ បានទេ',
  'Could not load GPA transcript.': 'មិនអាចទាញយកព្រឹត្តប័ត្រពិន្ទុ បានទេ។',
  'The server returned an invalid GPA transcript response.':
      'ម៉ាស៊ីនមេបានត្រឡប់ទិន្នន័យព្រឹត្តប័ត្រពិន្ទុ មិនត្រឹមត្រូវ។',
  'Subjects': 'មុខវិជ្ជា',
  'Entered scores': 'ពិន្ទុដែលបានបញ្ចូល',
  'Average score': 'ពិន្ទុមធ្យម',
  'Attendance score': 'ពិន្ទុវត្តមាន',
  'Midterm': 'ពាក់កណ្តាលឆមាស',
  'Assignment': 'កិច្ចការ',
  'Final': 'ប្រឡងចុងក្រោយ',
  'Teacher score': 'ពិន្ទុគ្រូ',
  'Admin score': 'ពិន្ទុអ្នកគ្រប់គ្រង',
  'No scores entered yet.': 'មិនទាន់មានពិន្ទុបានបញ្ចូលទេ។',
  'No grades entered yet.': 'មិនទាន់មានពិន្ទុទេ។',
  'Could not load grades': 'មិនអាចទាញយកពិន្ទុបានទេ',
  'Could not load grades.': 'មិនអាចទាញយកពិន្ទុបានទេ។',
  'The server returned an invalid grades response.':
      'ម៉ាស៊ីនមេបានត្រឡប់ទិន្នន័យពិន្ទុមិនត្រឹមត្រូវ។',
  'Room {room}': 'បន្ទប់ {room}',
  'You': 'អ្នក',
  'Class avg': 'មធ្យមថ្នាក់',
  'Top class': 'ថ្នាក់ល្អបំផុត',
  'Cumulative {value}': 'សរុប {value}',
  'Scheduled or active sessions': 'វគ្គដែលបានកំណត់ ឬកំពុងដំណើរការ',
  'No sessions assigned': 'មិនមានវគ្គដែលបានចាត់តាំង',
  'Scheduled classes': 'ថ្នាក់ដែលបានកំណត់ពេល',
  'This month attendance': 'វត្តមានខែនេះ',
  'Issues': 'បញ្ហា',
  'Blacklist': 'បញ្ជីខ្មៅ',
  'Yes': 'បាទ/ចាស',
  'No': 'ទេ',
  '{count} subjects': 'មុខវិជ្ជា {count}',
  '{rate}% attendance rate': 'អត្រាវត្តមាន {rate}%',
  'No scan time': 'មិនមានម៉ោងស្កេន',
  '{time} - {method}': '{time} - {method}',
  'Could not load student attendance': 'មិនអាចទាញយកវត្តមាននិស្សិតបានទេ',
  'Payments': 'ការទូទាត់',
  'Payment': 'ការទូទាត់',
  'Library': 'បណ្ណាល័យ',
  'Support': 'ជំនួយ',
  'Scheduled': 'បានកំណត់ពេល',
  'Completed': 'បានបញ្ចប់',
  'Conversation': 'ការសន្ទនា',
  'No messages yet.': 'មិនទាន់មានសារទេ។',
  'Monday': 'ថ្ងៃចន្ទ',
  'Tuesday': 'ថ្ងៃអង្គារ',
  'Wednesday': 'ថ្ងៃពុធ',
  'Thursday': 'ថ្ងៃព្រហស្បតិ៍',
  'Friday': 'ថ្ងៃសុក្រ',
  'Saturday': 'ថ្ងៃសៅរ៍',
  'Sunday': 'ថ្ងៃអាទិត្យ',
  'Performance': 'ប្រសិទ្ធភាព',
  'Schedule': 'កាលវិភាគ',
  'Chat': 'ជជែក',
  'Profile': 'ប្រវត្តិរូប',
  'Account': 'គណនី',
  'Role': 'តួនាទី',
  'Teacher information': 'ព័ត៌មានគ្រូ',
  'Teacher code': 'កូដគ្រូ',
  'Student information': 'ព័ត៌មាននិស្សិត',
  'Group': 'ក្រុម',
  'Major': 'មុខជំនាញ',
  'Year level': 'ឆ្នាំសិក្សា',
  'Status': 'ស្ថានភាព',
  'Profile details are read-only. Contact student support to correct your information.':
      'ព័ត៌មានប្រវត្តិរូបអាចមើលបានតែប៉ុណ្ណោះ។ សូមទាក់ទងផ្នែកជំនួយនិស្សិត ដើម្បីកែព័ត៌មាន។',
  'Could not load profile': 'មិនអាចទាញយកប្រវត្តិរូបបានទេ',
  'Check your connection and try again.':
      'សូមពិនិត្យការតភ្ជាប់ ហើយព្យាយាមម្តងទៀត។',
  'Home': 'ទំព័រដើម',
  'Menu': 'ម៉ឺនុយ',
  'Navigation': 'ការរុករក',
  'View profile': 'មើលប្រវត្តិរូប',
  'About': 'អំពី',
  'About HRU': 'អំពី HRU',
  'University history': 'ប្រវត្តិសាកលវិទ្យាល័យ',
  'Developer': 'អ្នកអភិវឌ្ឍន៍',
  'Mobile application developer': 'អ្នកអភិវឌ្ឍន៍កម្មវិធីទូរស័ព្ទ',
  'HRU University is an academic institution focused on practical learning, student development, and community service. Through its programs and digital systems, HRU supports students, teachers, and administrators with better access to academic information and attendance management.':
      'សាកលវិទ្យាល័យ HRU គឺជាស្ថាប័នអប់រំដែលផ្តោតលើការសិក្សាអនុវត្ត ការអភិវឌ្ឍនិស្សិត និងសេវាសហគមន៍។ តាមរយៈកម្មវិធីសិក្សា និងប្រព័ន្ធឌីជីថល HRU គាំទ្រនិស្សិត គ្រូបង្រៀន និងអ្នកគ្រប់គ្រងឱ្យចូលប្រើព័ត៌មានសិក្សា និងគ្រប់គ្រងវត្តមានបានកាន់តែល្អ។',
  'Request': 'សំណើ',
  'Refresh dashboard': 'ធ្វើបច្ចុប្បន្នភាពផ្ទាំងគ្រប់គ្រង',
  'Account menu': 'ម៉ឺនុយគណនី',
  'Logout': 'ចាកចេញ',
  'Signing out...': 'កំពុងចាកចេញ...',
  'Class performance': 'ប្រសិទ្ធភាពថ្នាក់',
  '{count} assigned classes': 'ថ្នាក់ដែលបានចាត់តាំង {count}',
  'View all': 'មើលទាំងអស់',
  'Needs attention': 'ត្រូវការយកចិត្តទុកដាក់',
  'Lowest attendance classes': 'ថ្នាក់ដែលមានវត្តមានទាប',
  '{count} recent sessions': 'វគ្គរៀនថ្មីៗ {count}',
  '{count} groups': 'ក្រុម {count}',
  '{count} subjects - {sessions} sessions':
      'មុខវិជ្ជា {count} - វគ្គរៀន {sessions}',
  '{count} schedules - Page {page} of {total}':
      'កាលវិភាគ {count} - ទំព័រ {page} នៃ {total}',
  'Room {room} - Session {session}': 'បន្ទប់ {room} - វគ្គ {session}',
  'Messages': 'សារ',
  'My classes': 'ថ្នាក់របស់ខ្ញុំ',
  'Refresh classes': 'ធ្វើបច្ចុប្បន្នភាពថ្នាក់',
  'First page': 'ទំព័រដំបូង',
  'Previous page': 'ទំព័រមុន',
  'Next page': 'ទំព័របន្ទាប់',
  'Last page': 'ទំព័រចុងក្រោយ',
  'Showing {start}-{end} of {total}': 'បង្ហាញ {start}-{end} ក្នុងចំណោម {total}',
  'Permission requests': 'សំណើសុំអនុញ្ញាត',
  'Teacher permission': 'ការសុំអនុញ្ញាតរបស់គ្រូ',
  'Choose the session for permission.': 'សូមជ្រើសវគ្គរៀនសម្រាប់សុំអនុញ្ញាត។',
  'No sessions in this date range.':
      'មិនមានវគ្គរៀនក្នុងចន្លោះកាលបរិច្ឆេទនេះទេ។',
  '{count} sessions selected': 'បានជ្រើសវគ្គរៀន {count}',
  'Teacher permission requests submitted. Admin approval is required.':
      'បានដាក់សំណើសុំអនុញ្ញាតរបស់គ្រូ។ ត្រូវការការអនុម័តពីអ្នកគ្រប់គ្រង។',
  'Teacher permission request submitted. Admin approval is required.':
      'បានដាក់សំណើសុំអនុញ្ញាតរបស់គ្រូ។ ត្រូវការការអនុម័តពីអ្នកគ្រប់គ្រង។',
  'Could not submit permission request.': 'មិនអាចដាក់សំណើសុំអនុញ្ញាតបានទេ។',
  'Your attendance session': 'វគ្គវត្តមានរបស់អ្នក',
  'Sick': 'ឈឺ',
  'Event': 'ព្រឹត្តិការណ៍',
  'Personal': 'ផ្ទាល់ខ្លួន',
  'Official': 'ផ្លូវការ',
  'Reason': 'មូលហេតុ',
  'Send to admin': 'ផ្ញើទៅអ្នកគ្រប់គ្រង',
  'Ask admin for permission': 'ស្នើសុំការអនុញ្ញាតពីអ្នកគ្រប់គ្រង',
  '{count} waiting for admin approval':
      'កំពុងរង់ចាំការអនុម័តពីអ្នកគ្រប់គ្រង {count}',
  'Choose a session.': 'សូមជ្រើសវគ្គរៀន។',
  'Enter the reason.': 'សូមបញ្ចូលមូលហេតុ។',
  'My requests': 'សំណើរបស់ខ្ញុំ',
  '{count} items': 'ធាតុ {count}',
  'Admin note: {note}': 'កំណត់ចំណាំអ្នកគ្រប់គ្រង៖ {note}',
  'No teacher permission requests yet.': 'មិនទាន់មានសំណើសុំអនុញ្ញាតរបស់គ្រូទេ។',
  'Could not load teacher permission':
      'មិនអាចទាញយកទិន្នន័យសុំអនុញ្ញាតរបស់គ្រូបានទេ',
  'Notifications': 'ការជូនដំណឹង',
  'Upcoming class': 'ថ្នាក់ជិតមកដល់',
  'Tomorrow': 'ថ្ងៃស្អែក',
  'In 5 hours': 'ក្នុងរយៈពេល ៥ ម៉ោង',
  'Upcoming': 'ជិតមកដល់',
  'pending': 'កំពុងរង់ចាំ',
  'approved': 'បានអនុម័ត',
  'rejected': 'បានបដិសេធ',
  'Refresh': 'ធ្វើបច្ចុប្បន្នភាព',
  'All notifications': 'ការជូនដំណឹងទាំងអស់',
  'Read all': 'សម្គាល់ថាបានអានទាំងអស់',
  'Saving': 'កំពុងរក្សាទុក',
  'No notifications yet.': 'មិនទាន់មានការជូនដំណឹងទេ។',
  'Could not load notifications': 'មិនអាចទាញយកការជូនដំណឹងបានទេ',
  'Retry': 'ព្យាយាមម្តងទៀត',
  'API': 'API',
  '{count} students': 'និស្សិត {count} នាក់',
  '{classes} classes - {active} active now':
      'ថ្នាក់ {classes} - កំពុងដំណើរការ {active}',
  '{rate}% total attendance performance': 'ប្រសិទ្ធភាពវត្តមានសរុប {rate}%',
  'Classes': 'ថ្នាក់',
  'Scans': 'ស្កេន',
  'Active': 'កំពុងដំណើរការ',
  'No class performance yet': 'មិនទាន់មានប្រសិទ្ធភាពថ្នាក់',
  'Assigned class performance will appear here.':
      'ប្រសិទ្ធភាពថ្នាក់ដែលបានចាត់តាំងនឹងបង្ហាញនៅទីនេះ។',
  '{group} - {count} students': '{group} - និស្សិត {count} នាក់',
  'No attention list': 'មិនមានបញ្ជីត្រូវយកចិត្តទុកដាក់',
  'Classes with low performance will appear here.':
      'ថ្នាក់ដែលមានប្រសិទ្ធភាពទាបនឹងបង្ហាញនៅទីនេះ។',
  '{group} - {count} sessions': '{group} - វគ្គរៀន {count}',
  'No sessions scheduled': 'មិនមានកាលវិភាគវគ្គរៀន',
  'Upcoming and recent sessions will appear here.':
      'វគ្គរៀនខាងមុខ និងថ្មីៗនឹងបង្ហាញនៅទីនេះ។',
  '{present}/{total} students': 'និស្សិត {present}/{total} នាក់',
  'Skipped': 'បានរំលង',
  '{time} - Room {room}': '{time} - បន្ទប់ {room}',
  'Class communication': 'ការទំនាក់ទំនងក្នុងថ្នាក់',
  '{classes} classes and {students} students ready for messages.':
      'ថ្នាក់ {classes} និងនិស្សិត {students} នាក់ រួចរាល់សម្រាប់សារ។',
  'Open chat': 'បើកការជជែក',
  '{count} classes': 'ថ្នាក់ {count}',
  '{students} students - {average}% average attendance':
      'និស្សិត {students} នាក់ - មធ្យមវត្តមាន {average}%',
  'Students': 'និស្សិត',
  'Class students': 'និស្សិតតាមថ្នាក់',
  '{classes} classes - {students} students':
      'ថ្នាក់ {classes} - និស្សិត {students} នាក់',
  'No students in this class.': 'មិនមាននិស្សិតក្នុងថ្នាក់នេះទេ។',
  'No class students found.': 'រកមិនឃើញនិស្សិតតាមថ្នាក់ទេ។',
  'Could not load class students': 'មិនអាចទាញយកនិស្សិតតាមថ្នាក់បានទេ',
  'Search students': 'ស្វែងរកនិស្សិត',
  'Clear search': 'សម្អាតការស្វែងរក',
  'No students match your search.': 'មិនមាននិស្សិតត្រូវនឹងការស្វែងរកទេ។',
  'Attendance': 'វត្តមាន',
  'Attendance history': 'ប្រវត្តិវត្តមាន',
  'No attendance history yet.': 'មិនទាន់មានប្រវត្តិវត្តមានទេ។',
  'Could not load student detail': 'មិនអាចទាញយកព័ត៌មានលម្អិតនិស្សិតបានទេ',
  'Close': 'បិទ',
  'Student ID': 'លេខសម្គាល់និស្សិត',
  'Student status': 'ស្ថានភាពនិស្សិត',
  'Account status': 'ស្ថានភាពគណនី',
  'Blacklist semesters': 'ឆមាសក្នុងបញ្ជីខ្មៅ',
  'Created at': 'បានបង្កើតនៅ',
  'Updated at': 'បានធ្វើបច្ចុប្បន្នភាពនៅ',
  'None': 'គ្មាន',
  'N/A': 'មិនមាន',
  'active': 'សកម្ម',
  'blacklisted': 'ក្នុងបញ្ជីខ្មៅ',
  'Room {room} - {schedule}': 'បន្ទប់ {room} - {schedule}',
  'No classes assigned yet.': 'មិនទាន់មានថ្នាក់ដែលបានចាត់តាំងទេ។',
  'Could not load classes': 'មិនអាចទាញយកថ្នាក់បានទេ',
  'Pending': 'កំពុងរង់ចាំ',
  'Skip': 'រំលង',
  'Excellent': 'ល្អឥតខ្ចោះ',
  'Good': 'ល្អ',
  'Warning': 'ព្រមាន',
  'Stable': 'មានស្ថិរភាព',
  'Attention': 'ត្រូវយកចិត្តទុកដាក់',
  'PRESENT': 'មានវត្តមាន',
  'ABSENT': 'អវត្តមាន',
  'LATE': 'យឺត',
  'EXCUSED': 'មានច្បាប់',
  'SCHEDULED': 'បានកំណត់ពេល',
  'Profile photo updated.': 'បានធ្វើបច្ចុប្បន្នភាពរូបថតប្រវត្តិរូប។',
  'Could not update profile photo.':
      'មិនអាចធ្វើបច្ចុប្បន្នភាពរូបថតប្រវត្តិរូបបានទេ។',
  'Refresh profile': 'ធ្វើបច្ចុប្បន្នភាពប្រវត្តិរូប',
  'Change profile photo': 'ប្តូររូបថតប្រវត្តិរូប',
  'Could not load teacher dashboard': 'មិនអាចទាញយកផ្ទាំងគ្រូបានទេ',
  'Could not load student dashboard': 'មិនអាចទាញយកផ្ទាំងនិស្សិតបានទេ',
  'Check the backend connection and try again.':
      'សូមពិនិត្យការភ្ជាប់ម៉ាស៊ីនមេ ហើយព្យាយាមម្តងទៀត។',
  'Check your backend API connection and try again.':
      'សូមពិនិត្យការភ្ជាប់ Backend API ហើយព្យាយាមម្តងទៀត។',
  'Preparing HRU ATMS': 'កំពុងរៀបចំ HRU ATMS',
  'My attendance': 'វត្តមានរបស់ខ្ញុំ',
  '{count} records': 'កំណត់ត្រា {count}',
  'Attendance summary for {month}': 'សរុបវត្តមានសម្រាប់ {month}',
  'This month records': 'កំណត់ត្រាខែនេះ',
  'Permission and absent records': 'កំណត់ត្រាច្បាប់ និងអវត្តមាន',
  'Subjects with permission or absent': 'មុខវិជ្ជាដែលមានច្បាប់ ឬអវត្តមាន',
  'Absent': 'អវត្តមាន',
  'Permission': 'ច្បាប់',
  'Late': 'យឺត',
  'Date': 'កាលបរិច្ឆេទ',
  'Room': 'បន្ទប់',
  'Check in': 'ចូល',
  'Check out': 'ចេញ',
  'No attendance records for {month}.':
      'មិនមានកំណត់ត្រាវត្តមានសម្រាប់ {month} ទេ។',
  'No subjects with permission or absent records for {month}.':
      'មិនមានមុខវិជ្ជាដែលមានច្បាប់ ឬអវត្តមានសម្រាប់ {month} ទេ។',
  'Could not load teacher attendance': 'មិនអាចទាញយកវត្តមានរបស់គ្រូបានទេ',
  'January': 'មករា',
  'February': 'កុម្ភៈ',
  'March': 'មីនា',
  'April': 'មេសា',
  'May': 'ឧសភា',
  'June': 'មិថុនា',
  'July': 'កក្កដា',
  'August': 'សីហា',
  'September': 'កញ្ញា',
  'October': 'តុលា',
  'November': 'វិច្ឆិកា',
  'December': 'ធ្នូ',
  'Loading your academic workspace': 'កំពុងទាញយកផ្ទៃការងារសិក្សារបស់អ្នក',
  'Documents': 'ឯកសារ',
  'Uploaded documents': 'ឯកសារដែលបានបង្ហោះ',
  '{count} documents uploaded': 'បានបង្ហោះឯកសារ {count}',
  'All': 'ទាំងអស់',
  'Approved': 'បានអនុម័ត',
  'Rejected': 'បានបដិសេធ',
  'Search documents': 'ស្វែងរកឯកសារ',
  'File name': 'ឈ្មោះឯកសារ',
  'Admin comment': 'មតិយោបល់អ្នកគ្រប់គ្រង',
  'No documents match your search.': 'មិនមានឯកសារត្រូវនឹងការស្វែងរកទេ។',
  'No uploaded documents yet.': 'មិនទាន់មានឯកសារដែលបានបង្ហោះទេ។',
  'Could not load teacher documents': 'មិនអាចទាញយកឯកសាររបស់គ្រូបានទេ',
  'Could not load student documents': 'មិនអាចទាញយកឯកសារនិស្សិតបានទេ',
  'Could not load student documents.': 'មិនអាចទាញយកឯកសារនិស្សិតបានទេ។',
  'No documents available yet.': 'មិនទាន់មានឯកសារទេ។',
  '{count} documents available': 'មានឯកសារ {count}',
  'Preview': 'មើលជាមុន',
  'Download': 'ទាញយក',
  'Open': 'បើក',
  'Document downloaded': 'បានទាញយកឯកសារ',
  'Could not open document.': 'មិនអាចបើកឯកសារបានទេ។',
  'Preview is not available for this file type.':
      'មិនអាចមើលជាមុនសម្រាប់ប្រភេទឯកសារនេះទេ។',
  'Scan attendance': 'ស្កេនវត្តមាន',
  'Scan attendance QR': 'ស្កេន QR វត្តមាន',
  'Start scan': 'ចាប់ផ្តើមស្កេន',
  'Student QR attendance': 'ស្កេន QR វត្តមាននិស្សិត',
  'Secure student scan': 'ស្កេននិស្សិតសុវត្ថិភាព',
  'This is not a student attendance QR code.':
      'នេះមិនមែនជា QR វត្តមាននិស្សិតទេ។',
  'Scan the teacher attendance QR code':
      'ស្កេន QR វត្តមានពីគ្រូ។ មិនចាំបាច់ជ្រើសឈ្មោះទេ។',
  'Could not verify attendance QR.': 'មិនអាចផ្ទៀងផ្ទាត់ QR វត្តមានបានទេ។',
  'The server returned an invalid QR attendance response.':
      'ម៉ាស៊ីនមេបានត្រឡប់ទិន្នន័យ QR វត្តមានមិនត្រឹមត្រូវ។',
  '{status} at {time}': '{status} នៅម៉ោង {time}',
  '{count} active sessions ready to scan': 'មានវគ្គសកម្ម {count} ត្រៀមស្កេន',
  'Open classes and choose a session': 'បើកថ្នាក់ ហើយជ្រើសវគ្គរៀន',
  'Start': 'ចាប់ផ្តើម',
  'Teacher QR check-in': 'ស្កេន QR វត្តមានគ្រូ',
  'Flash': 'ភ្លើងបំភ្លឺ',
  'This is not a teacher attendance QR code.': 'នេះមិនមែនជា QR វត្តមានគ្រូទេ។',
  'Checking in...': 'កំពុងចុះវត្តមាន...',
  'Reading attendance QR...': 'កំពុងអាន QR វត្តមាន...',
  'Check-in successful': 'ចុះវត្តមានបានជោគជ័យ',
  'Check-out successful': 'ចាកចេញពីវត្តមានបានជោគជ័យ',
  '{subject} checked in at {time}': '{subject} បានចុះវត្តមាននៅម៉ោង {time}',
  '{subject} checked out at {time}':
      '{subject} បានចាកចេញពីវត្តមាននៅម៉ោង {time}',
  'Checked in': 'បានចុះវត្តមាន',
  'Checked out': 'បានចាកចេញ',
  '{action} at {time}': '{action} នៅម៉ោង {time}',
  'No active session': 'មិនមានវគ្គសកម្ម',
  'This QR code does not match an active session for your teacher account.':
      'QR នេះមិនត្រូវនឹងវគ្គសកម្មសម្រាប់គណនីគ្រូរបស់អ្នកទេ។',
  'Ask the admin to open the correct teacher session QR, then scan again.':
      'សូមស្នើឱ្យអ្នកគ្រប់គ្រងបើក QR វគ្គគ្រូត្រឹមត្រូវ រួចស្កេនម្តងទៀត។',
  'Scan again': 'ស្កេនម្តងទៀត',
  'Done': 'រួចរាល់',
  'No active session matches this QR code for your teacher account.':
      'មិនមានវគ្គសកម្មណាមួយត្រូវនឹង QR នេះសម្រាប់គណនីគ្រូរបស់អ្នកទេ។',
  'No active session was found for this QR code.':
      'រកមិនឃើញវគ្គសកម្មសម្រាប់ QR នេះទេ។',
  'The QR token is invalid, expired, or already used.':
      'កូដ QR មិនត្រឹមត្រូវ ផុតកំណត់ ឬត្រូវបានប្រើរួចហើយ។',
  'The QR token is invalid or expired.': 'កូដ QR មិនត្រឹមត្រូវ ឬផុតកំណត់។',
  'This QR code does not belong to the authenticated teacher.':
      'QR នេះមិនមែនជារបស់គ្រូដែលបានចូលប្រើទេ។',
  'Scan the admin teacher attendance QR code':
      'ស្កេន QR វត្តមានគ្រូពីអ្នកគ្រប់គ្រង',
  'Could not start camera. Check permission.':
      'មិនអាចបើកកាមេរ៉ាបានទេ។ សូមពិនិត្យសិទ្ធិកាមេរ៉ា។',
  'Flash is not available': 'មិនអាចប្រើភ្លើងបំភ្លឺបានទេ',
  'Starting camera...': 'កំពុងបើកកាមេរ៉ា...',
  'Color mode': 'របៀបពណ៌',
  'System': 'ឧបករណ៍',
  'Light': 'ភ្លឺ',
  'Dark': 'ងងឹត',
  'Something went wrong': 'មានបញ្ហាមួយកើតឡើង',
  'The app could not open this page right now.':
      'កម្មវិធីមិនអាចបើកទំព័រនេះបាននៅពេលនេះទេ។',
  'The app found a problem while opening this view.':
      'កម្មវិធីបានរកឃើញបញ្ហាពេលកំពុងបើកទិដ្ឋភាពនេះ។',
  'Page not available': 'ទំព័រនេះមិនទាន់មានទេ',
  'This feature is not available in the mobile app yet.':
      'មុខងារនេះមិនទាន់មានក្នុងកម្មវិធីទូរស័ព្ទទេ។',
  'Back': 'ត្រឡប់ក្រោយ',
  'System maintenance': 'ប្រព័ន្ធកំពុងថែទាំ',
  'System maintenance is active. Please try again later.':
      'ប្រព័ន្ធកំពុងថែទាំ។ សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ។',
  'Check again': 'ពិនិត្យម្តងទៀត',
};

// when students use the app scan can't session name like web ;so if use phone after scan auto detect
