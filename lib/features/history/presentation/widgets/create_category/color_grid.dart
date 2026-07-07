import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorGrid extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onChanged;
  static const List<int> _colors = [
    0xFF00B4D8,
    0xFF10B981,
    0xFFFF9F43,
    0xFFFF4757,
    0xFF9B5DE5,
  ];

  const ColorGrid({
    super.key,
    required this.selectedColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ЦВЕТ КАТЕГОРИИ',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _colors.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(_colors[i]);
            },
            child: CircleAvatar(
              backgroundColor: Color(_colors[i]),
              child: _colors[i] == selectedColor
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
