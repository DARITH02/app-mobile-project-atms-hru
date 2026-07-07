import 'package:flutter/material.dart';

class FixedMenuPageSlide extends StatelessWidget {
  const FixedMenuPageSlide({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final direction = _slideDirection(
      ModalRoute.of(context)?.settings.arguments,
    );

    return ClipRect(
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: Offset(direction, 0), end: Offset.zero),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        builder: (context, offset, child) {
          return FractionalTranslation(translation: offset, child: child);
        },
        child: child,
      ),
    );
  }
}

double _slideDirection(Object? arguments) {
  if (arguments == 'slide-left-to-right') return -1;
  if (arguments == 'slide-right-to-left') return 1;
  return 0;
}
