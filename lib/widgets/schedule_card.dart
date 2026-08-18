import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String text;

  const ScheduleCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(Icons.eco, color: Colors.green),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}