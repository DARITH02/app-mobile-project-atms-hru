import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/core/network/api_exception.dart';
import 'package:hru_atms/core/notifications/schedule_notification_service.dart';
import 'package:hru_atms/features/notifications/data/notification_repository.dart';
import 'package:hru_atms/shared/widgets/app_loading_screen.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _repository;
  late Future<AppNotificationFeed> _future;
  bool _isMarkingRead = false;
  bool _isSchedulingAlarm = false;
  bool _testAlarmEnabled = false;
  Duration _testAlarmDelay = const Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    _repository = NotificationRepository();
    _future = _repository.fetchNotifications();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchNotifications();
    setState(() => _future = future);
    await future;
  }

  Future<void> _markAllRead() async {
    if (_isMarkingRead) return;
    setState(() => _isMarkingRead = true);
    try {
      await _repository.markAllRead();
      await _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isMarkingRead = false);
    }
  }

  Future<void> _scheduleTestAlarm() async {
    if (_isSchedulingAlarm) return;
    setState(() => _isSchedulingAlarm = true);
    try {
      final scheduledAt = await ScheduleNotificationService.instance
          .scheduleTestAlarm(delay: _testAlarmDelay);
      if (!mounted) return;
      setState(() => _testAlarmEnabled = scheduledAt != null);
      final message = scheduledAt == null
          ? context.tr('Alarm test is not available on this platform.')
          : context.l10n.format('Alarm test scheduled for {time}', {
              'time': _time(scheduledAt),
            });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not schedule alarm test.'))),
      );
    } finally {
      if (mounted) setState(() => _isSchedulingAlarm = false);
    }
  }

  Future<void> _cancelTestAlarm() async {
    if (_isSchedulingAlarm) return;
    setState(() => _isSchedulingAlarm = true);
    try {
      await ScheduleNotificationService.instance.cancelTestAlarm();
      if (!mounted) return;
      setState(() => _testAlarmEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Alarm test turned off.'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not turn off alarm test.'))),
      );
    } finally {
      if (mounted) setState(() => _isSchedulingAlarm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Notifications')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh_rounded),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<AppNotificationFeed>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingScreen();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _ErrorState(onRetry: _refresh);
            }

            final feed = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _SummaryCard(
                  unreadCount: feed.unreadCount,
                  isMarkingRead: _isMarkingRead,
                  isSchedulingAlarm: _isSchedulingAlarm,
                  testAlarmEnabled: _testAlarmEnabled,
                  testAlarmDelay: _testAlarmDelay,
                  onMarkAllRead: feed.unreadCount == 0 ? null : _markAllRead,
                  onScheduleTestAlarm: _scheduleTestAlarm,
                  onCancelTestAlarm: _cancelTestAlarm,
                  onDelayChanged: (value) {
                    if (value == null) return;
                    setState(() => _testAlarmDelay = value);
                  },
                ),
                const SizedBox(height: 16),
                if (feed.items.isEmpty)
                  const _EmptyState()
                else
                  for (final item in feed.items) ...[
                    _NotificationCard(item: item),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.unreadCount,
    required this.isMarkingRead,
    required this.isSchedulingAlarm,
    required this.testAlarmEnabled,
    required this.testAlarmDelay,
    required this.onMarkAllRead,
    required this.onScheduleTestAlarm,
    required this.onCancelTestAlarm,
    required this.onDelayChanged,
  });

  final int unreadCount;
  final bool isMarkingRead;
  final bool isSchedulingAlarm;
  final bool testAlarmEnabled;
  final Duration testAlarmDelay;
  final VoidCallback? onMarkAllRead;
  final VoidCallback onScheduleTestAlarm;
  final VoidCallback onCancelTestAlarm;
  final ValueChanged<Duration?> onDelayChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(8),
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
                  Icons.notifications_active_outlined,
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
                      context.tr('All notifications'),
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.format('{count} unread', {
                        'count': '$unreadCount',
                      }),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: isMarkingRead ? null : onMarkAllRead,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(
                  isMarkingRead ? context.tr('Saving') : context.tr('Read all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.alarm_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('Test alarm'),
                        style: TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Switch(
                      value: testAlarmEnabled,
                      activeThumbColor: AppColors.surface,
                      activeTrackColor: AppColors.green,
                      inactiveThumbColor: AppColors.surface,
                      inactiveTrackColor: Colors.white38,
                      onChanged: isSchedulingAlarm
                          ? null
                          : (value) => value
                                ? onScheduleTestAlarm()
                                : onCancelTestAlarm(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Duration>(
                  initialValue: testAlarmDelay,
                  dropdownColor: AppColors.surface,
                  iconEnabledColor: AppColors.surface,
                  decoration: InputDecoration(
                    labelText: context.tr('Alarm after'),
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w800,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: const Duration(minutes: 1),
                      child: Text(
                        context.tr('1 minute'),
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ),
                    DropdownMenuItem(
                      value: const Duration(minutes: 3),
                      child: Text(
                        context.tr('3 minutes'),
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ),
                    DropdownMenuItem(
                      value: const Duration(minutes: 5),
                      child: Text(
                        context.tr('5 minutes'),
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ),
                    DropdownMenuItem(
                      value: const Duration(minutes: 10),
                      child: Text(
                        context.tr('10 minutes'),
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ),
                  ],
                  selectedItemBuilder: (context) =>
                      [
                            Text(context.tr('1 minute')),
                            Text(context.tr('3 minutes')),
                            Text(context.tr('5 minutes')),
                            Text(context.tr('10 minutes')),
                          ]
                          .map(
                            (child) => DefaultTextStyle(
                              style: TextStyle(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w800,
                              ),
                              child: child,
                            ),
                          )
                          .toList(),
                  onChanged: isSchedulingAlarm ? null : onDelayChanged,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isSchedulingAlarm
                        ? null
                        : testAlarmEnabled
                        ? onCancelTestAlarm
                        : onScheduleTestAlarm,
                    icon: isSchedulingAlarm
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            testAlarmEnabled
                                ? Icons.alarm_off_rounded
                                : Icons.alarm_on_rounded,
                          ),
                    label: Text(
                      isSchedulingAlarm
                          ? context.tr('Saving alarm')
                          : testAlarmEnabled
                          ? context.tr('Turn off alarm')
                          : context.tr('Turn on alarm'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.brandBlue,
                    ),
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final color = item.isRead ? AppColors.mutedText : AppColors.brandBlue;
    final statusColor = _statusColor(item.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isRead
              ? const Color(0xFFE6EBF2)
              : AppColors.brandBlue.withValues(alpha: 0.24),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F172033),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.isRead
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(item.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.createdAt,
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.status.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          context.tr(item.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('tomorrow')) return AppColors.orange;
  if (lower.contains('5')) return AppColors.rose;
  if (lower.contains('upcoming')) return AppColors.brandBlue;
  if (lower.contains('pending')) return AppColors.orange;
  if (lower.contains('approved')) return AppColors.green;
  if (lower.contains('rejected')) return AppColors.rose;
  return AppColors.mutedText;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none_rounded, color: AppColors.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('No notifications yet.'),
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
              context.tr('Could not load notifications'),
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

String _time(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
