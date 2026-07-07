import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';

const _hruHistoryKhmer = '''
សាកលវិទ្យាល័យធនធានមនុស្សត្រូវបានបង្កើតឡើងជាលើកដំបូងដែលមានឈ្មោះថា វិទ្យាស្ថានអភិវឌ្ឍន៍ធនធានមនុស្ស នៅក្នុងខែឧសភាឆ្នាំ ១៩៩៨ ដោយស្ថាបនិក ៣ រូបគឺ៖ ឯកឧត្តមបណ្ឌិត សេង ផល្លី ឯកឧត្តមបណ្ឌិត ឯក មនោសែន និងឯកឧត្តម អោក សោភា។ វិទ្យាស្ថានអភិវឌ្ឍន៍ធនធានមនុស្សបានផ្តល់វគ្គបណ្ដុះបណ្ដាលរយៈពេលខ្លីៗ ពី ៣ ទៅ ៦ ខែ និងរយៈពេល ១ ឆ្នាំ លើមុខវិជ្ជាសំខាន់ៗដូចជា៖ គណនេយ្យ ទីផ្សារ ការគ្រប់គ្រង ភាពជាអ្នកដឹកនាំ កិច្ចការរដ្ឋបាល ជំនាញលេខាធិការ និងភាសាបរទេស។

ដើម្បីឆ្លើយតបទៅនឹងការអភិវឌ្ឍសេដ្ឋកិច្ចសង្គម និងតម្រូវការសម្រាប់ការសិក្សាស្រាវជ្រាវ ការបណ្តុះបណ្តាលដែលមានគុណភាព វិទ្យាស្ថាននេះបានអភិវឌ្ឍខ្លួនក្លាយជាសាកលវិទ្យាល័យធនធានមនុស្ស ដោយអនុក្រឹត្យលេខ ៤១ អនក្រ.បក របស់រាជរដ្ឋាភិបាលកម្ពុជា ចុះថ្ងៃទី ២១ ខែកុម្ភៈ ឆ្នាំ ២០០៥។ សាកលវិទ្យាល័យធនធានមនុស្ស (HRU) មានកម្មវិធីបណ្តុះបណ្តាលកម្រិតក្រោយបរិញ្ញាបត្រ (ថ្នាក់បរិញ្ញាបត្រជាន់ខ្ពស់ និងថ្នាក់បណ្ឌិត) និងមានមហាវិទ្យាល័យចំនួនប្រាំសម្រាប់កម្មវិធីបណ្តុះបណ្តាលកម្រិតបរិញ្ញាបត្រ និងកម្រិតបរិញ្ញាបត្ររង។

មហាវិទ្យាល័យទាំងប្រាំរួមមាន៖ មហាវិទ្យាល័យសិល្បៈ មនុស្សសាស្រ្ត និងភាសា មហាវិទ្យាល័យវិទ្យាសាស្ត្រនិងបច្ចេកវិទ្យា មហាវិទ្យាល័យវិទ្យាសាស្ត្រសង្គម និងសេដ្ឋកិច្ច មហាវិទ្យាល័យគ្រប់គ្រងពាណិជ្ជកម្មនិងទេសចរណ៍ និងមហាវិទ្យាល័យនីតិសាស្រ្តនិងវិទ្យាសាស្រ្តនយោបាយ។ បច្ចុប្បន្ន សាកលវិទ្យាល័យធនធានមនុស្សបាននិងកំពុងបណ្តុះបណ្តាលលើកម្មវិធីសិក្សា វគ្គសិក្សាខ្លីៗ បរិញ្ញាបត្ររង បរិញ្ញាបត្រ បរិញ្ញាបត្រជាន់ខ្ពស់ និងថ្នាក់បណ្ឌិត លើឯកទេសសិក្សាជាច្រើនដូចជា៖ ទីផ្សារ ការគ្រប់គ្រង គណនេយ្យនិងហិរញ្ញវត្ថុ ធនាគារនិងហិរញ្ញវត្ថុ សណ្ឋាគារនិងទេសចរណ៍ ភាសាអង់គ្លេសសម្រាប់ការបង្រៀន និងភាសាអង់គ្លេសសម្រាប់ទំនាក់ទំនងវិជ្ជាជីវៈ។

សាកលវិទ្យាល័យធនធានមនុស្សបច្ចុប្បន្ននេះគឺជាគ្រឹះស្ថានឧត្តមសិក្សាដែលពេញនិយម និងមានប្រជាប្រិយភាពនៅកម្ពុជា ដែលទទួលស្គាល់ពីគណៈកម្មាធិការទទួលស្គាល់គុណភាពអប់រំនៃកម្ពុជា ថាជាស្ថាប័នអប់រំដែលមានគុណភាពខ្ពស់។ ជារៀងរាល់ឆ្នាំមាននិស្សិតចុះឈ្មោះចូលរៀនថ្មីជាង ១០០០ នាក់។ រហូតដល់ឆ្នាំ ២០១៨ ចំនួននិស្សិតបញ្ចប់ការសិក្សាពីសាកលវិទ្យាល័យនេះគឺប្រហែល ៣៧០០០ នាក់ ហើយមាននិស្សិតកំពុងសិក្សាចំនួន ៦៥០០ នាក់។

សាកលវិទ្យាល័យធនធានមនុស្សបានសម្ពោធដាក់ឱ្យប្រើប្រាស់អគារសិក្សាផ្ទាល់ខ្លួនធំថ្មី ទំនើប កម្ពស់ ១២ ជាន់ កណ្តាលរាជធានីភ្នំពេញ ដែលមានវិសាលភាពទទួលបណ្តុះបណ្តាលនិស្សិតប្រមាណ ២០០០០ នាក់។ អគារនេះបំពាក់ដោយសម្ភារឧបទ្ទេសទំនើបៗ នៅគ្រប់បន្ទប់ការងារ និងបន្ទប់សិក្សា ប្រកបដោយផាសុកភាព មានបណ្ណាល័យធំទូលាយ បន្ទប់អនុវត្តគ្រប់ប្រភេទ និងមានអាហារដ្ឋាន។
''';

const _hruHistoryEnglish = '''
The Human Resource University was formerly established as the Institute of Human Resource Development (IHRD) in May 1998 by three founders: H.E. Dr. SENG Phally, H.E. Dr. EK Monosen, and H.E. OK Sophea. IHRD provided specialist short-term training courses for three to six months and one year in major subjects such as accounting, marketing, management and leadership, administrative affairs, secretarial skills, and foreign languages.

In response to socio-economic development and the need for academic research and quality education, the institute was promoted to the Human Resource University (HRU) by Sub-decree No. 41 S.P. of the Royal Government of Cambodia, dated 21 February 2005. HRU has graduate programs for master's and PhD degrees, and five faculties for undergraduate and associate degree programs: the Faculty of Art, Humanity and Languages, the Faculty of Science and Technology, the Faculty of Social Science and Economics, the Faculty of Business Administration and Tourism, and the Faculty of Law and Political Science.

Currently, HRU offers short courses, associate, bachelor, master, and doctoral programs in various fields of study, including marketing, management, accounting, accounting and finance, banking and finance, hotels and tourism, teaching English as a foreign language, and English for professional communication.

HRU is a well-known and popular higher education institution in Cambodia, recognized by the Accreditation Committee of Cambodia as a high-quality education institution. More than one thousand new students enroll at HRU every year. Up to 2018, approximately 37,000 students had graduated from the university, and about 6,500 students were studying on campus.

Human Resource University has established and inaugurated a new modern building in central Phnom Penh. The university building has 12 floors and can accommodate approximately 20,000 learners. Offices and classrooms are equipped with modern facilities and comfortable air conditioning, along with a large library, different kinds of laboratories, and a canteen.
''';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('About HRU'))),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/branding/hru_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Human Resource University'),
                            // textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('Attendance Management System'),
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
              ),
              const SizedBox(height: 16),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.history_edu_outlined,
                      title: context.tr('University history'),
                    ),
                    const SizedBox(height: 10),
                    Text(_hruHistoryKhmer, style: _historyTextStyle),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.translate_rounded,
                      title: context.tr('University History in English'),
                    ),
                    const SizedBox(height: 10),
                    Text(_hruHistoryEnglish, style: _historyTextStyle),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.code_rounded,
                      title: context.tr('Developer'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'D',
                            style: TextStyle(
                              color: AppColors.brandBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Darith',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.tr('Mobile application developer'),
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const StudentBottomNavigationForRole(
        current: StudentNavDestination.about,
      ),
    );
  }
}

final _historyTextStyle = TextStyle(
  color: AppColors.bodyText,
  height: 1.55,
  fontWeight: FontWeight.w600,
);

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brandBlue),
        const SizedBox(width: 8),
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
      ],
    );
  }
}
