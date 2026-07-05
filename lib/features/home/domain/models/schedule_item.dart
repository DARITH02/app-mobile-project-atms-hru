import 'package:flutter/material.dart';

class ScheduleItem {
  const ScheduleItem({
    required this.time,
    required this.course,
    required this.room,
    required this.color,
  });

  final String time;
  final String course;
  final String room;
  final Color color;
}
