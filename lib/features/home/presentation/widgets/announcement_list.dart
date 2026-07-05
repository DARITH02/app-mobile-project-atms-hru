import 'package:flutter/material.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/features/home/domain/models/announcement.dart';

class AnnouncementList extends StatelessWidget {
  const AnnouncementList({required this.announcements, super.key});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final announcement in announcements) ...[
          _AnnouncementTile(announcement: announcement),
          if (announcement != announcements.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: announcement.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(announcement.icon, color: announcement.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
