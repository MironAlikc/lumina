import 'package:flutter/material.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/air_key.dart';

class AirKeyboard extends StatelessWidget {
  final ValueChanged<String> onKeyPress;

  const AirKeyboard({super.key, required this.onKeyPress});

  static const List<List<String>> _keyboardRows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          children: _keyboardRows.map((rowKeys) => _buildRow(rowKeys)).toList(),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys
          .map(
            (k) => Expanded(
              child: AirKey(label: k, onTap: () => onKeyPress(k)),
            ),
          )
          .toList(),
    );
  }
}
