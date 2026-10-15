import 'package:flutter/material.dart';

/// Ограничивает ширину содержимого на планшетах и в landscape.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
