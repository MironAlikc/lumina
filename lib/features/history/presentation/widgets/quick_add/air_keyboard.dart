import 'package:flutter/material.dart';
import 'package:lumina/features/history/presentation/widgets/quick_add/air_key.dart';

class AirKeyboard extends StatelessWidget {
  final Function(String) onKeyPress;
  const AirKeyboard({super.key, required this.onKeyPress});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          _buildRow(['.', '0', '⌫']),
        ],
      ),
    ),
  );

  Widget _buildRow(List<String> keys) => Row(
    children: keys
        .map(
          (k) => Expanded(
            child: AirKey(label: k, onTap: () => onKeyPress(k)),
          ),
        )
        .toList(),
  );
}
