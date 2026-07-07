import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/permissions/data/student_permission_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/student_bottom_navigation.dart';

class StudentPermissionPage extends StatefulWidget {
  const StudentPermissionPage({super.key});

  @override
  State<StudentPermissionPage> createState() => _StudentPermissionPageState();
}

class _StudentPermissionPageState extends State<StudentPermissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late final StudentPermissionRepository _repository;
  late Future<StudentPermissionData> _future;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _type = 'sick';
  String _mode = 'session';
  int? _selectedSessionId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = StudentPermissionRepository();
    _future = _repository.load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _repository.load();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_mode == 'session' && _selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please choose one session.'))),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final message = await _repository.submit(
        mode: _mode,
        attendanceSessionId: _mode == 'session' ? _selectedSessionId : null,
        startDate: _startDate,
        endDate: _endDate,
        type: _type,
        reason: _reasonController.text,
      );
      _reasonController.clear();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr(message))));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Pre-permission')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: FixedMenuPageSlide(
        child: SafeArea(
          child: FutureBuilder<StudentPermissionData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              final hasLoadError = snapshot.hasError || snapshot.data == null;
              final data =
                  snapshot.data ??
                  const StudentPermissionData(
                    student: StudentPermissionOwner(
                      name: 'Student',
                      studentCode: 'N/A',
                      group: 'N/A',
                    ),
                    requests: [],
                    sessions: [],
                  );
              if (_mode == 'session' &&
                  _selectedSessionId == null &&
                  data.sessions.isNotEmpty) {
                _selectedSessionId = data.sessions.first.id;
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  if (hasLoadError) ...[
                    _LoadWarning(onRetry: _refresh),
                    const SizedBox(height: 14),
                  ],
                  _IntroCard(student: data.student),
                  const SizedBox(height: 14),
                  _PermissionForm(
                    formKey: _formKey,
                    mode: _mode,
                    type: _type,
                    sessions: data.sessions,
                    selectedSessionId: _selectedSessionId,
                    startDate: _startDate,
                    endDate: _endDate,
                    reasonController: _reasonController,
                    submitting: _submitting,
                    onModeChanged: (value) => setState(() => _mode = value),
                    onTypeChanged: (value) => setState(() => _type = value),
                    onSessionChanged: (value) =>
                        setState(() => _selectedSessionId = value),
                    onPickStart: () => _pickDate(start: true),
                    onPickEnd: () => _pickDate(start: false),
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: context.tr('My pre-permissions'),
                    subtitle: context.l10n.format('{count} items', {
                      'count': '${data.requests.length}',
                    }),
                  ),
                  if (data.requests.isEmpty)
                    const _EmptyState()
                  else
                    for (final request in data.requests) ...[
                      _PermissionCard(request: request),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const StudentBottomNavigationForRole(
        current: StudentNavDestination.permissions,
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.student});

  final StudentPermissionOwner student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_late_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Pre-permission request'),
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.name} - ${student.studentCode} - ${student.group}',
                  maxLines: 2,
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
    );
  }
}

class _PermissionForm extends StatelessWidget {
  const _PermissionForm({
    required this.formKey,
    required this.mode,
    required this.type,
    required this.sessions,
    required this.selectedSessionId,
    required this.startDate,
    required this.endDate,
    required this.reasonController,
    required this.submitting,
    required this.onModeChanged,
    required this.onTypeChanged,
    required this.onSessionChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final String mode;
  final String type;
  final List<StudentPermissionSession> sessions;
  final int? selectedSessionId;
  final DateTime startDate;
  final DateTime endDate;
  final TextEditingController reasonController;
  final bool submitting;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int?> onSessionChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final validSelectedSession = sessions.any(
      (session) => session.id == selectedSessionId,
    );

    return _Panel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Request before absence'),
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(
                'Admin must approve or reject the request within 7 days.',
              ),
              style: TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.tr('One session')),
                  selected: mode == 'session',
                  onSelected: (_) => onModeChanged('session'),
                ),
                ChoiceChip(
                  label: Text(context.tr('Many days')),
                  selected: mode == 'range',
                  onSelected: (_) => onModeChanged('range'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _permissionTypes)
                  ChoiceChip(
                    label: Text(context.tr(item.label)),
                    selected: type == item.value,
                    onSelected: (_) => onTypeChanged(item.value),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (mode == 'session')
              DropdownButtonFormField<int>(
                initialValue: validSelectedSession ? selectedSessionId : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('Choose session'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  for (final session in sessions)
                    DropdownMenuItem(
                      value: session.id,
                      child: Text(
                        session.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                validator: (_) {
                  if (sessions.isEmpty || !validSelectedSession) {
                    return context.tr('Please choose one session.');
                  }
                  return null;
                },
                onChanged: onSessionChanged,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: context.tr('Start date'),
                      value: _date(startDate),
                      onTap: onPickStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(
                      label: context.tr('End date'),
                      value: _date(endDate),
                      onTap: onPickEnd,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr('Reason'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 4) {
                  return context.tr('Enter the reason.');
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send_rounded),
                label: Text(
                  submitting
                      ? context.tr('Submitting')
                      : context.tr('Submit request'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.event_rounded, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.request});

  final StudentPermissionRequest request;

  @override
  Widget build(BuildContext context) {
    final status = request.effectiveStatus;
    final color = _statusColor(status);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(_typeLabel(request.type)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(text: context.tr(status), color: color),
            ],
          ),
          const SizedBox(height: 8),
          if (request.attendanceSessionId > 0 && request.subject.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.l10n.format('Session: {subject}', {
                  'subject': request.subject,
                }),
                style: TextStyle(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Text(
            '${request.startDate} - ${request.endDate}',
            style: TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.reason,
            style: TextStyle(
              color: AppColors.bodyText,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (request.expiresAt.isNotEmpty && status == 'pending') ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.format('Expires at {time}', {
                'time': _shortDateTime(request.expiresAt),
              }),
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
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
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

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
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('No pre-permission requests yet.'),
              style: TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadWarning extends StatelessWidget {
  const _LoadWarning({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(
                'Could not load request history. You can still submit a new request.',
              ),
              style: TextStyle(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
        ],
      ),
    );
  }
}

class _PermissionType {
  const _PermissionType(this.value, this.label);

  final String value;
  final String label;
}

const _permissionTypes = [
  _PermissionType('sick', 'Sick leave'),
  _PermissionType('event', 'School event'),
  _PermissionType('personal', 'Personal permission'),
  _PermissionType('official', 'Official duty'),
  _PermissionType('other', 'Other'),
];

Color _statusColor(String value) {
  return switch (value.toLowerCase()) {
    'approved' => AppColors.green,
    'rejected' => AppColors.rose,
    'expired' => AppColors.mutedText,
    _ => AppColors.orange,
  };
}

String _typeLabel(String value) {
  return switch (value) {
    'sick' => 'Sick leave',
    'event' => 'School event',
    'personal' => 'Personal permission',
    'official' => 'Official duty',
    _ => 'Other',
  };
}

String _date(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _shortDateTime(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  return '${_date(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
