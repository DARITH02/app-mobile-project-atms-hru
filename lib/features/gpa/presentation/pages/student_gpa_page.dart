import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/gpa/data/student_gpa_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';

class StudentGpaPage extends StatefulWidget {
  const StudentGpaPage({super.key});

  @override
  State<StudentGpaPage> createState() => _StudentGpaPageState();
}

class _StudentGpaPageState extends State<StudentGpaPage> {
  late final StudentGpaRepository _repository;
  late Future<StudentGpaTranscript> _future;

  @override
  void initState() {
    super.initState();
    _repository = StudentGpaRepository();
    _future = _repository.fetchTranscript();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchTranscript();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('GPA Transcript')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: FutureBuilder<StudentGpaTranscript>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: _refresh);
              }

              final transcript = snapshot.data!;
              final byYear = _groupByYear(transcript.histories);

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  _TranscriptHeader(transcript: transcript),
                  const SizedBox(height: 18),
                  if (transcript.histories.isEmpty)
                    _EmptyState()
                  else
                    for (final entry in byYear.entries) ...[
                      _YearHeader(year: entry.key),
                      const SizedBox(height: 10),
                      for (final history in entry.value) ...[
                        _SemesterCard(history: history),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 4),
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const StudentBottomNavigation(
        current: StudentNavDestination.gpa,
      ),
    );
  }
}

class _TranscriptHeader extends StatelessWidget {
  const _TranscriptHeader({required this.transcript});

  final StudentGpaTranscript transcript;

  @override
  Widget build(BuildContext context) {
    final summary = transcript.summary;

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
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppColors.surface,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transcript.student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transcript.student.studentCode} - ${transcript.student.group}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${transcript.student.major} - ${context.tr('Year level')} ${transcript.student.yearLevel}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 86,
            ),
            children: [
              _SummaryTile(
                label: context.tr('Cumulative GPA'),
                value: _number(summary.cumulativeGpa),
              ),
              _SummaryTile(
                label: context.tr('Latest GPA'),
                value: _number(summary.latestGpa),
              ),
              _SummaryTile(
                label: context.tr('Semesters'),
                value: '${summary.semesterCount}',
              ),
              _SummaryTile(
                label: context.tr('Credits'),
                value: _number(summary.totalCredits),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    return Text(
      year,
      style: TextStyle(
        color: AppColors.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  const _SemesterCard({required this.history});

  final GpaSemesterHistory history;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      collapsedShape: _shape,
      shape: _shape,
      backgroundColor: AppColors.surface,
      collapsedBackgroundColor: AppColors.surface,
      leading: CircleAvatar(
        backgroundColor: _gpaColor(history.semesterGpa).withValues(alpha: 0.12),
        child: Icon(
          Icons.workspace_premium_outlined,
          color: _gpaColor(history.semesterGpa),
        ),
      ),
      title: Text(
        history.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${context.tr('GPA')} ${_number(history.semesterGpa)} - ${context.tr('Cumulative GPA')} ${_number(history.cumulativeGpa)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: _GpaBadge(value: history.semesterGpa),
      children: [
        _SemesterMeta(history: history),
        const SizedBox(height: 10),
        if (history.subjectGrades.isEmpty)
          _InlineEmpty(text: context.tr('No transcript subjects yet.'))
        else
          for (final subject in history.subjectGrades) ...[
            _SubjectTranscriptRow(subject: subject),
            if (subject != history.subjectGrades.last)
              const Divider(height: 18),
          ],
      ],
    );
  }

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: AppColors.border),
  );
}

class _SemesterMeta extends StatelessWidget {
  const _SemesterMeta({required this.history});

  final GpaSemesterHistory history;

  @override
  Widget build(BuildContext context) {
    final text =
        '${history.classGroupName} - ${history.majorName} - ${context.tr('Credits')} ${_number(history.totalCredits)}';
    return Row(
      children: [
        Icon(Icons.fact_check_outlined, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _GpaBadge extends StatelessWidget {
  const _GpaBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final color = _gpaColor(value);
    return Container(
      width: 52,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _number(value),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SubjectTranscriptRow extends StatelessWidget {
  const _SubjectTranscriptRow({required this.subject});

  final GpaSubjectGrade subject;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(subject.totalScore);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subject.letterGrade,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${subject.subjectCode} - ${context.tr('Credits')} ${_number(subject.credit)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniScore(
                    label: context.tr('Attendance'),
                    value: subject.attendanceScore,
                  ),
                  _MiniScore(
                    label: context.tr('Midterm'),
                    value: subject.midtermScore,
                  ),
                  _MiniScore(
                    label: context.tr('Assignment'),
                    value: subject.assignmentScore,
                  ),
                  _MiniScore(
                    label: context.tr('Final'),
                    value: subject.finalScore,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _number(subject.totalScore),
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${context.tr('GP')} ${_number(subject.gradePoint)}',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label ${_number(value)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.bodyText,
          fontSize: 11,
          height: 1.15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _InlineEmpty(text: context.tr('No GPA transcript records yet.'));
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
              context.tr('Could not load GPA transcript'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<GpaSemesterHistory>> _groupByYear(
  List<GpaSemesterHistory> histories,
) {
  final grouped = <String, List<GpaSemesterHistory>>{};
  for (final history in histories) {
    grouped.putIfAbsent(history.academicYear, () => []).add(history);
  }
  return grouped;
}

String _number(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}

Color _gpaColor(double value) {
  if (value >= 3.25) return AppColors.green;
  if (value >= 2.5) return AppColors.brandBlue;
  if (value > 0) return AppColors.orange;
  return AppColors.mutedText;
}

Color _scoreColor(double value) {
  if (value >= 80) return AppColors.green;
  if (value >= 60) return AppColors.brandBlue;
  if (value > 0) return AppColors.orange;
  return AppColors.mutedText;
}
