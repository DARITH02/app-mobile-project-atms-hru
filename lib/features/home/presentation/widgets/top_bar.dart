import 'package:flutter/material.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/shared/widgets/app_logo.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogo(),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Portal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(
                'Hanoi University',
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () =>
              Navigator.of(context).pushNamed('/unavailable/search'),
          icon: Icon(Icons.search),
          tooltip: 'Search',
        ),
      ],
    );
  }
}
