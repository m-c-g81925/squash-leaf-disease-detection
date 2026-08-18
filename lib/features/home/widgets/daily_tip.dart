import 'dart:math';

import 'package:flutter/material.dart';

class DailyTip extends StatelessWidget {
  const DailyTip({super.key});

  static const List<Map<String, dynamic>> _tips = [
    {
      'icon': Icons.water_drop,
      'title': 'Water Early',
      'tip':
          'Water your squash plants early in the morning to reduce evaporation and help prevent fungal diseases.',
    },
    {
      'icon': Icons.eco,
      'title': 'Inspect Leaves',
      'tip':
          'Check the top and underside of leaves regularly for signs of disease or insect damage.',
    },
    {
      'icon': Icons.camera_alt,
      'title': 'Scan Weekly',
      'tip':
          'Use the disease scanner at least once a week to detect infections early.',
    },
    {
      'icon': Icons.grass,
      'title': 'Apply Fertilizer',
      'tip':
          'Apply fertilizer according to your planting schedule to promote healthy squash growth.',
    },
    {
      'icon': Icons.wb_sunny,
      'title': 'Provide Sunlight',
      'tip':
          'Squash plants grow best with 6–8 hours of direct sunlight every day.',
    },
    {
      'icon': Icons.cleaning_services,
      'title': 'Keep the Area Clean',
      'tip':
          'Remove dead leaves and weeds around your plants to reduce disease spread.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final random = Random(DateTime.now().day);
    final tip = _tips[random.nextInt(_tips.length)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF179E43).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(
              tip['icon'],
              color: const Color(0xFF179E43),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🌱 Daily Farming Tip",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF179E43),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tip['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip['tip'],
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}