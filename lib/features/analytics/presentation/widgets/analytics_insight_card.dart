import 'package:flutter/material.dart';
import 'package:lumina/core/theme/lumina_dimensions.dart';

class AnalyticsInsightCard extends StatelessWidget {
  const AnalyticsInsightCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LuminaDimensions.paddingL),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: LuminaDimensions.borderRadiusLarge,
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
