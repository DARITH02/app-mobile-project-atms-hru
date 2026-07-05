import 'package:flutter/material.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/home/domain/models/schedule_item.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({required this.items, super.key});

  final List<ScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (final item in items) ...[
            _ScheduleRow(item: item),
            if (item != items.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.time,
            textAlign: TextAlign.center,
            style: TextStyle(color: item.color, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.course,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                item.room,
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              Navigator.of(context).pushNamed('/unavailable/schedule-detail'),
          icon: Icon(Icons.chevron_right),
          tooltip: 'Open schedule item',
        ),
      ],
    );
  }
}
