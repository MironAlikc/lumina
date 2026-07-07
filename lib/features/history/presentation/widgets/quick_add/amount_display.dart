import 'package:flutter/material.dart';

class AmountDisplay extends StatelessWidget {
  final String amount;
  const AmountDisplay({super.key, required this.amount});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            amount,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800),
          ),
          const Text(
            ' ₴',
            style: TextStyle(fontSize: 28, color: Colors.black38),
          ),
        ],
      ),
    ),
  );
}
