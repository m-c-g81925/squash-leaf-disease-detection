import 'package:flutter/material.dart';

import '../../../core/services/scan_history_service.dart';
import 'stat_card.dart';
import 'wide_stat_card.dart';

class DashboardStatistics extends StatelessWidget {
  const DashboardStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ScanHistoryService.getDashboardStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF179E43),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unable to load dashboard statistics.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final statistics = snapshot.data ??
            {
              'totalScans': 0,
              'highRisk': 0,
              'mediumRisk': 0,
              'lowRisk': 0,
              'highestConfidence': 0.0,
              'mostCommonDisease': 'None',
            };

        final totalScans =
            statistics['totalScans'] as int? ?? 0;

        final highRisk =
            statistics['highRisk'] as int? ?? 0;

        final mediumRisk =
            statistics['mediumRisk'] as int? ?? 0;

        final lowRisk =
            statistics['lowRisk'] as int? ?? 0;

        final highestConfidence =
            (statistics['highestConfidence'] as num? ?? 0)
                .toDouble();

        final mostCommonDisease =
            statistics['mostCommonDisease']
                    ?.toString() ??
                'None';

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Scan Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Scans',
                      value: totalScans.toString(),
                      icon: Icons.document_scanner,
                      color: const Color(0xFF179E43),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: StatCard(
                      title: 'High Risk',
                      value: highRisk.toString(),
                      icon: Icons.warning_amber,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Medium Risk',
                      value: mediumRisk.toString(),
                      icon: Icons.report_problem_outlined,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: StatCard(
                      title: 'Low Risk',
                      value: lowRisk.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: WideStatCard(
                title: 'Highest Confidence',
                value: totalScans == 0
                    ? '0.00%'
                    : '${highestConfidence.toStringAsFixed(2)}%',
                icon: Icons.track_changes,
                color: const Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: WideStatCard(
                title: 'Most Common Disease',
                value: mostCommonDisease,
                icon: Icons.coronavirus_outlined,
                color: const Color(0xFF7B1FA2),
              ),
            ),
          ],
        );
      },
    );
  }
}