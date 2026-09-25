import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/features/transactions/presentation/widgets/quick_add/air_key.dart';

class AirKeyboard extends StatelessWidget {
  const AirKeyboard({super.key, required this.onKeyPress});

  final ValueChanged<String> onKeyPress;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in _rows)
              Row(
                children: [
                  for (final key in row)
                    Expanded(
                      child: AirKey(
                        label: key,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onKeyPress(key);
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
