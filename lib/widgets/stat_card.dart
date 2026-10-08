import 'package:flutter/material.dart';

/* Counter tile used in list headers (licences, profiles). Meant to sit in a
Row, so it expands to share the width with its siblings. */
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.color, this.icon});

  final String label;
  final int value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final valueColor = icon == null ? color : null;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor)),
                  Text(label, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
