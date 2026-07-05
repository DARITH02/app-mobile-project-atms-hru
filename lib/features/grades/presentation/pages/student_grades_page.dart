import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/grades/data/student_grades_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';

class StudentGradesPage extends StatefulWidget {
  const StudentGradesPage({super.key});

  @override
  State<StudentGradesPage> createState() => _StudentGradesPageState();
}

class _StudentGradesPageState extends State<StudentGradesPage> {
  late final StudentGradesRepository _repository;
  late Future<StudentGrades> _future;

  @override
  void initState() {
    super.initState();
    _repository = StudentGradesRepository();
    _future = _repository.fetchGrades();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchGrades();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Grades')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<StudentGrades>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingScreen();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _ErrorState(onRetry: _refresh);
            }

            final grades = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
              children: [
                _SummaryBand(grades: grades),
                const SizedBox(height: 18),
                if (grades.subjects.isEmpty)
                  _EmptyState()
                else
                  for (final subject in grades.subjects) ...[
                    _SubjectGradeCard(subject: subject),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const StudentBottomNavigation(
        current: StudentNavDestination.grades,
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.grades});

  final StudentGrades grades;

  @override
  Widget build(BuildContext context) {
    final summary = grades.summary;
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
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
                      grades.student.name,
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
                      '${grades.student.group} - ${grades.student.major}',
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
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.45,
            ),
            children: [
              _SummaryTile(
                label: context.tr('Subjects'),
                value: '${summary.subjectsCount}',
              ),
              _SummaryTile(
                label: context.tr('Entered scores'),
                value: '${summary.scoresCount}',
              ),
              _SummaryTile(
                label: context.tr('Average score'),
                value: _scoreText(summary.averageTotalScore),
              ),
              _SummaryTile(
                label: context.tr('Attendance score'),
                value: _scoreText(summary.averageAttendanceScore),
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
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectGradeCard extends StatelessWidget {
  const _SubjectGradeCard({required this.subject});

  final StudentGradeSubject subject;

  @override
  Widget build(BuildContext context) {
    final latest = subject.scores.isEmpty ? null : subject.scores.first;
    final color = latest == null || !latest.hasScore
        ? AppColors.mutedText
        : _gradeColor(latest.totalScore);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      collapsedShape: _shape,
      shape: _shape,
      backgroundColor: AppColors.surface,
      collapsedBackgroundColor: AppColors.surface,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.menu_book_outlined, color: color),
      ),
      title: Text(
        subject.subjectName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${context.tr('Teacher')}: ${subject.teacher}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: _TotalBadge(score: latest),
      children: [
        _SubjectMeta(subject: subject),
        const SizedBox(height: 10),
        if (subject.scores.isEmpty)
          _InlineEmpty(text: context.tr('No scores entered yet.'))
        else
          for (final score in subject.scores) ...[
            _ScoreBreakdown(score: score),
            if (score != subject.scores.last) const SizedBox(height: 10),
          ],
      ],
    );
  }

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: AppColors.border),
  );
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.score});

  final StudentSubjectScore? score;

  @override
  Widget build(BuildContext context) {
    final hasScore = score?.hasScore ?? false;
    final color = hasScore
        ? _gradeColor(score!.totalScore)
        : AppColors.mutedText;

    return Container(
      width: 54,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        hasScore ? _scoreText(score!.totalScore) : context.tr('Pending'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: hasScore ? 12 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SubjectMeta extends StatelessWidget {
  const _SubjectMeta({required this.subject});

  final StudentGradeSubject subject;

  @override
  Widget build(BuildContext context) {
    final details = [
      subject.subjectCode,
      subject.group,
      if (subject.room.isNotEmpty)
        context.l10n.format('Room {room}', {'room': subject.room}),
      if (subject.schedule.isNotEmpty) subject.schedule,
    ].where((item) => item.isNotEmpty).join(' - ');

    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            details,
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

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.score});

  final StudentSubjectScore score;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ScorePart(context.tr('Attendance'), score.attendanceScore, 20),
      _ScorePart(context.tr('Midterm'), score.midtermScore, 15),
      _ScorePart(context.tr('Assignment'), score.assignmentScore, 15),
      _ScorePart(context.tr('Final'), score.finalScore, 50),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  score.semesterLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                label: score.hasScore
                    ? '${score.letterGrade} - ${_scoreText(score.totalScore)}'
                    : context.tr('Pending'),
                color: score.hasScore
                    ? _gradeColor(score.totalScore)
                    : AppColors.mutedText,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.85,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ScorePartTile(item: item);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  label: context.tr('Teacher score'),
                  value: _scoreText(score.teacherScore),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallInfo(
                  label: context.tr('Admin score'),
                  value: _scoreText(score.adminScore),
                ),
              ),
            ],
          ),
          if (score.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InlineEmpty(text: score.notes),
          ],
        ],
      ),
    );
  }
}

class _ScorePartTile extends StatelessWidget {
  const _ScorePartTile({required this.item});

  final _ScorePart item;

  @override
  Widget build(BuildContext context) {
    final progress = item.maxScore <= 0 ? 0.0 : item.score / item.maxScore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_scoreText(item.score)}/${_scoreText(item.maxScore)}',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              color: AppColors.brandBlue,
              backgroundColor: AppColors.brandBlue.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
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
    return _InlineEmpty(text: context.tr('No grades entered yet.'));
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
              context.tr('Could not load grades'),
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

class _ScorePart {
  const _ScorePart(this.label, this.score, this.maxScore);

  final String label;
  final double score;
  final double maxScore;
}

String _scoreText(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

Color _gradeColor(double score) {
  if (score >= 80) return AppColors.green;
  if (score >= 60) return AppColors.brandBlue;
  if (score > 0) return AppColors.orange;
  return AppColors.mutedText;
}
