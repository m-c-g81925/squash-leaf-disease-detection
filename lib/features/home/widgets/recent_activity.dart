import 'package:flutter/material.dart';

import '../../../core/services/scan_history_service.dart';
import '../../../models/scan_history_model.dart';
import '../../scan/scan_history_detail_screen.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;

      case 'medium':
        return Colors.orange;

      case 'low':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Bag-o lang';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutos ang nagligad';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} oras ang nagligad';
    }

    if (difference.inDays == 1) {
      return 'Kahapon';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} ka adlaw ang nagligad';
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScanHistory>>(
      stream: ScanHistoryService.getRecentScans(limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF179E43),
              ),
            ),
          );
        }

        final scans = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                'Bag-o nga mga Aktibidad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (scans.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 55,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Wala pa sang bag-o nga scan.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Diri makita ang imo pinakabag-o nga resulta sang scan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...scans.map(
                (scan) {
                  final severityColor =
                      _severityColor(scan.severity);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ScanHistoryDetailScreen(
                                scan: scan,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(.04),
                                blurRadius: 8,
                                offset:
                                    const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    severityColor
                                        .withOpacity(.15),
                                child: Icon(
                                  Icons.eco,
                                  color: severityColor,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      scan.disease,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 4),

                                    Text(
                                      '${scan.confidence.toStringAsFixed(2)}% Confidence',
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 6),

                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal:
                                                8,
                                            vertical: 3,
                                          ),
                                          decoration:
                                              BoxDecoration(
                                            color: severityColor
                                                .withOpacity(
                                                    .12),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    20),
                                          ),
                                          child: Text(
                                            scan.severity,
                                            style:
                                                TextStyle(
                                              color:
                                                  severityColor,
                                              fontSize:
                                                  11,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),

                                        const Spacer(),

                                        Text(
                                          _timeAgo(scan
                                              .scannedAt
                                              .toDate()),
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                11,
                                            color: Colors
                                                .grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Icon(
                                Icons
                                    .arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}