import 'dart:math';

import 'package:flutter/material.dart';

class DailyTip extends StatelessWidget {
  const DailyTip({super.key});

  static const List<Map<String, dynamic>> _tips = [
    {
      'icon': Icons.water_drop,
      'title': 'Magbunyag sing aga',
      'tip':
          'Bunyagi ang imo tanom nga kalabasa sing temprano sa aga agod indi madali mag alisngaw ang tubig kag makabulig sa paglikaw sa fungal diseases.',
    },
    {
      'icon': Icons.eco,
      'title': 'I-check ang mga dahon',
      'tip':
          'Regualar nga i-check and ibabaw kag idalom sang mga dahon para makita kon may mga senyales sang balatian ukon halit sang mga insekto.',
    },
    {
      'icon': Icons.camera_alt,
      'title': 'Mag-scan kada semana',
      'tip':
          'Gamita and disease scanner bisan isa ka beses kada semana agod temprano nga ma-detect ang posible nga balatian sang tanom.',
    },
    {
      'icon': Icons.grass,
      'title': 'Magbutang sang abono',
      'tip':
          'Magbutang sang abono suno sa imo planting schedule agod magtubo sing maayo kag mangin healthy ang imo kalabasa.',
    },
    {
      'icon': Icons.wb_sunny,
      'title': 'Hatagi sing igo nga adlaw',
      'tip':
          'Mas maayo ang pagtubo sang kalabasa kon makabaton ini sang 6-8 ka oras nga direkta nga silak sang adlaw kada adlaw.',
    },
    {
      'icon': Icons.cleaning_services,
      'title': 'Limpyohon permi ang palibot',
      'tip':
          'Kuhaa ang mga patay nga dahon kag hilamon sa palibot sang imo nga tanom agod mabuligan nga malikawan ang paglapta sang balatian.',
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
                  "🌱 Tip sa pangunguma",
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