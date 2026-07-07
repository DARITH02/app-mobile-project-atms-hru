import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/features/permissions/data/teacher_permission_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';
import 'package:hru_atms/shared/widgets/fixed_menu_page_slide.dart';
import 'package:hru_atms/shared/widgets/teacher_bottom_navigation.dart';

class TeacherPermissionRequestPage extends StatefulWidget {
  const TeacherPermissionRequestPage({super.key});

  @override
  State<TeacherPermissionRequestPage> createState() =>
      _TeacherPermissionRequestPageState();
}

class _TeacherPermissionRequestPageState
    extends State<TeacherPermissionRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late final TeacherPermissionRepository _repository;
  late Future<TeacherPermissionData> _future;

  TeacherPermissionSession? _session;
  String _type = 'sick';
  String _mode = 'session';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = TeacherPermissionRepository();
    _future = _repository.load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _repository.load();
    setState(() => _future = future);
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

  Future<void> _submit(List<TeacherPermissionSession> sessions) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_mode == 'session' && _session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Choose the session for permission.')),
        ),
      );
      return;
    }
    final rangeSessions = _sessionsInRange(sessions);
    if (_mode == 'many_days' && rangeSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('No sessions in this date range.'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final message = _mode == 'many_days'
          ? await _repository.submitMany(
              attendanceSessionIds: rangeSessions
                  .map((session) => session.id)
                  .toList(),
              type: _type,
              reason: _reasonController.text,
            )
          : await _repository.submit(
              attendanceSessionId: _session!.id,
              type: _type,
              reason: _reasonController.text,
            );
      if (!mounted) return;
      _reasonController.clear();
      setState(() {
        _session = null;
        _type = 'sick';
        _mode = 'session';
        _startDate = DateTime.now();
        _endDate = DateTime.now();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr(message))));
      await _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Could not submit permission request.')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<TeacherPermissionSession> _sessionsInRange(
    List<TeacherPermissionSession> sessions,
  ) {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day);

    return sessions.where((session) {
      final date = session.sessionDate;
      if (date == null) return false;
      final day = DateTime(date.year, date.month, date.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Teacher permission')),
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
          child: FutureBuilder<TeacherPermissionData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoadingScreen();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _ErrorState(onRetry: _refresh);
              }
              final data = snapshot.data!;
              final permissionRequests = data.requests
                  .where((item) => item.requestedStatus == 'permission')
                  .toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
                children: [
                  _IntroCard(
                    pendingCount: permissionRequests
                        .where((item) => item.status == 'pending')
                        .length,
                  ),
                  const SizedBox(height: 14),
                  _PermissionForm(
                    formKey: _formKey,
                    mode: _mode,
                    sessions: data.sessions,
                    selectedSession: _session,
                    startDate: _startDate,
                    endDate: _endDate,
                    type: _type,
                    reasonController: _reasonController,
                    isSubmitting: _isSubmitting,
                    rangeSessionCount: _sessionsInRange(data.sessions).length,
                    onModeChanged: (value) => setState(() => _mode = value),
                    onSessionChanged: (value) =>
                        setState(() => _session = value),
                    onPickStart: () => _pickDate(start: true),
                    onPickEnd: () => _pickDate(start: false),
                    onTypeChanged: (value) => setState(() => _type = value),
                    onSubmit: () => _submit(data.sessions),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: context.tr('My requests'),
                    trailing: context.l10n.format('{count} items', {
                      'count': '${permissionRequests.length}',
                    }),
                  ),
                  if (permissionRequests.isEmpty)
                    const _EmptyHistory()
                  else
                    for (final request in permissionRequests) ...[
                      _RequestCard(request: request),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const TeacherBottomNavigation(
        current: TeacherNavDestination.permissions,
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.pendingCount});

  final int pendingCount;

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
            child: Icon(
              Icons.event_busy_outlined,
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
                  context.tr('Ask admin for permission'),
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.format('{count} waiting for admin approval', {
                    'count': '$pendingCount',
                  }),
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
    required this.sessions,
    required this.selectedSession,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.reasonController,
    required this.isSubmitting,
    required this.rangeSessionCount,
    required this.onModeChanged,
    required this.onSessionChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onTypeChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final String mode;
  final List<TeacherPermissionSession> sessions;
  final TeacherPermissionSession? selectedSession;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final TextEditingController reasonController;
  final bool isSubmitting;
  final int rangeSessionCount;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<TeacherPermissionSession?> onSessionChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'session',
                  icon: Icon(Icons.event_available_outlined),
                  label: Text(context.tr('One session')),
                ),
                ButtonSegment(
                  value: 'many_days',
                  icon: Icon(Icons.date_range_outlined),
                  label: Text(context.tr('Many days')),
                ),
              ],
              selected: {mode},
              showSelectedIcon: false,
              onSelectionChanged: (values) => onModeChanged(values.first),
            ),
            const SizedBox(height: 12),
            if (mode == 'session')
              DropdownButtonFormField<TeacherPermissionSession>(
                initialValue: selectedSession,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('Your attendance session'),
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                items: sessions
                    .map(
                      (session) => DropdownMenuItem(
                        value: session,
                        child: Text(
                          session.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) => mode == 'session' && value == null
                    ? context.tr('Choose a session.')
                    : null,
                onChanged: onSessionChanged,
              )
            else
              _DateRangeSelector(
                startDate: startDate,
                endDate: endDate,
                sessionCount: rangeSessionCount,
                onPickStart: onPickStart,
                onPickEnd: onPickEnd,
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PermissionTypeChip(
                  value: 'sick',
                  label: context.tr('Sick'),
                  selectedValue: type,
                  onSelected: onTypeChanged,
                ),
                _PermissionTypeChip(
                  value: 'event',
                  label: context.tr('Event'),
                  selectedValue: type,
                  onSelected: onTypeChanged,
                ),
                _PermissionTypeChip(
                  value: 'personal',
                  label: context.tr('Personal'),
                  selectedValue: type,
                  onSelected: onTypeChanged,
                ),
                _PermissionTypeChip(
                  value: 'official',
                  label: context.tr('Official'),
                  selectedValue: type,
                  onSelected: onTypeChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reasonController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: context.tr('Reason'),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.tr('Enter the reason.')
                  : null,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send_rounded),
              label: Text(
                isSubmitting
                    ? context.tr('Submitting')
                    : context.tr('Send to admin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTypeChip extends StatelessWidget {
  const _PermissionTypeChip({
    required this.value,
    required this.label,
    required this.selectedValue,
    required this.onSelected,
  });

  final String value;
  final String label;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      showCheckmark: false,
      avatar: Icon(
        _permissionTypeIcon(value),
        size: 17,
        color: selected ? Colors.white : AppColors.brandBlue,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primaryText,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: AppColors.brandBlue,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? AppColors.brandBlue : const Color(0xFFE6EBF2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (_) => onSelected(value),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.startDate,
    required this.endDate,
    required this.sessionCount,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int sessionCount;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: context.tr('Start date'),
                value: _formatDate(startDate),
                onTap: onPickStart,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateButton(
                label: context.tr('End date'),
                value: _formatDate(endDate),
                onTap: onPickEnd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.brandBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.format('{count} sessions selected', {
                    'count': '$sessionCount',
                  }),
                  style: TextStyle(
                    color: AppColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      icon: Icon(Icons.calendar_month_outlined),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final TeacherPermissionRequest request;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(request.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            request.date,
            style: TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.reason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.bodyText, height: 1.35),
          ),
          if (request.reviewNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.format('Admin note: {note}', {
                'note': request.reviewNote,
              }),
              style: TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

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
            trailing,
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('No teacher permission requests yet.'),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(
              context.tr('Could not load teacher permission'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x0F172033), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );
}

Color _statusColor(String status) {
  return switch (status.toLowerCase()) {
    'approved' => AppColors.green,
    'rejected' => AppColors.rose,
    _ => AppColors.orange,
  };
}

IconData _permissionTypeIcon(String type) {
  return switch (type) {
    'sick' => Icons.medical_services_outlined,
    'event' => Icons.event_outlined,
    'personal' => Icons.person_outline,
    'official' => Icons.badge_outlined,
    _ => Icons.description_outlined,
  };
}

String _formatDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
