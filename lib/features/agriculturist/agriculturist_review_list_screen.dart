import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'agriculturist_review_detail_screen.dart';

class AgriculturistReviewListScreen extends StatelessWidget {
  const AgriculturistReviewListScreen({super.key});

  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF5F7FB);

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'verified':
      case 'reviewed':
      case 'completed':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'verified':
      case 'reviewed':
      case 'completed':
        return Icons.verified;

      case 'rejected':
        return Icons.cancel;

      default:
        return Icons.pending_actions;
    }
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'No submission date';
    }

    final DateTime date = value.toDate();

    final int hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String minute =
        date.minute.toString().padLeft(2, '0');

    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.month}/${date.day}/${date.year} '
        'at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Expert Review Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('expert_reviews')
            .orderBy(
              'submittedAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              title: 'Unable to Load Requests',
              message: snapshot.error.toString(),
              color: Colors.red,
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const _MessageState(
              icon: Icons.assignment_outlined,
              title: 'No Review Requests',
              message:
                  'Farmer requests that require expert verification will appear here.',
              color: _primaryColor,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            separatorBuilder: (_, __) {
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              final document = documents[index];
              final data = document.data();

              final String prediction =
                  data['aiPrediction']
                          ?.toString() ??
                      'Unknown Prediction';

              final double confidence =
                  (data['confidence'] as num?)
                          ?.toDouble() ??
                      0.0;

              final String farmerName =
                  data['farmerName']
                          ?.toString() ??
                      'Unknown Farmer';

              final String municipality =
                  data['municipality']
                          ?.toString() ??
                      'Not provided';

              final String status =
                  data['status']?.toString() ??
                      'pending';

              final Color statusColor =
                  _statusColor(status);

              return _ReviewRequestCard(
                prediction: prediction,
                confidence: confidence,
                farmerName: farmerName,
                municipality: municipality,
                submittedDate: _formatDate(
                  data['submittedAt'],
                ),
                status: status,
                statusColor: statusColor,
                statusIcon: _statusIcon(status),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AgriculturistReviewDetailScreen(
                        documentId: document.id,
                        data: data,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewRequestCard extends StatelessWidget {
  final String prediction;
  final double confidence;
  final String farmerName;
  final String municipality;
  final String submittedDate;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _ReviewRequestCard({
    required this.prediction,
    required this.confidence,
    required this.farmerName,
    required this.municipality,
    required this.submittedDate,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color:
                          statusColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: '
                          '${confidence.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _DetailRow(
                icon: Icons.person_outline,
                text: farmerName,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon:
                    Icons.location_city_outlined,
                text: municipality,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.access_time,
                text: submittedDate,
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open request',
                      style: TextStyle(
                        color: Color(0xFF179E43),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Color(0xFF179E43),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF179E43),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: color,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}