import 'package:flutter/material.dart';

class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
