import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/scan_history_model.dart';

class ScanHistoryDetailScreen
    extends StatelessWidget {
  final ScanHistory scan;

  const ScanHistoryDetailScreen({
    super.key,
    required this.scan,
  });

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

  String _formatDate(DateTime date) {
    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final int hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String minute =
        date.minute.toString().padLeft(2, '0');

    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year} '
        'at $hour:$minute $period';
  }

  Future<bool> _canViewScan() async {
    final String? userId =
        FirebaseAuth.instance.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        document = await FirebaseFirestore.instance
            .collection('scan_history')
            .doc(scan.id)
            .get();

    if (!document.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return data['userId']?.toString() == userId;
  }

  Widget _buildScannedImage() {
    if (scan.imagePath.isEmpty) {
      return _buildImagePlaceholder(
        message:
            'No saved image for this scan.',
      );
    }

    final File imageFile =
        File(scan.imagePath);

    if (!imageFile.existsSync()) {
      return _buildImagePlaceholder(
        message:
            'The saved image is no longer available.',
      );
    }

    return Image.file(
      imageFile,
      width: double.infinity,
      height: 230,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _buildImagePlaceholder(
          message:
              'Unable to display the saved image.',
        );
      },
    );
  }

  Widget _buildImagePlaceholder({
    required String message,
  }) {
    return Container(
      width: double.infinity,
      height: 230,
      color: Colors.green.shade50,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 70,
            color: Color(0xFF179E43),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF5E6962),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canViewScan(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            backgroundColor:
                const Color(0xFFF6F7F5),
            appBar: AppBar(
              title: const Text(
                'Scan Details',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              backgroundColor:
                  Colors.white,
              foregroundColor:
                  Colors.black,
              elevation: 0,
            ),
            body: const Center(
              child:
                  CircularProgressIndicator(
                color: Color(0xFF179E43),
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data != true) {
          return Scaffold(
            backgroundColor:
                const Color(0xFFF6F7F5),
            appBar: AppBar(
              title: const Text(
                'Scan Details',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              backgroundColor:
                  Colors.white,
              foregroundColor:
                  Colors.black,
              elevation: 0,
            ),
            body: const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Text(
                  'You do not have permission to view this scan record, or it no longer exists.',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ),
          );
        }

        final Color severityColor =
            _severityColor(
          scan.severity,
        );

        return Scaffold(
          backgroundColor:
              const Color(0xFFF6F7F5),
          appBar: AppBar(
            title: const Text(
              'Scan Details',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            backgroundColor:
                Colors.white,
            foregroundColor:
                Colors.black,
            elevation: 0,
          ),
          body: SafeArea(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                children: [
                  Container(
                    width:
                        double.infinity,
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .green.shade50,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                      border:
                          Border.all(
                        color: Colors
                            .grey
                            .shade200,
                      ),
                    ),
                    clipBehavior:
                        Clip.antiAlias,
                    child:
                        _buildScannedImage(),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(
                      20,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      border:
                          Border.all(
                        color: Colors
                            .grey
                            .shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                            0.04,
                          ),
                          blurRadius: 8,
                          offset:
                              const Offset(
                            0,
                            3,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          scan.disease,
                          style:
                              const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .track_changes,
                              size: 20,
                              color: Color(
                                0xFF179E43,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                'Confidence: '
                                '${scan.confidence.toStringAsFixed(2)}%',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Row(
                          children: [
                            const Text(
                              'Severity: ',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    10,
                                vertical: 5,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    severityColor
                                        .withOpacity(
                                  0.12,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                scan.severity,
                                style:
                                    TextStyle(
                                  color:
                                      severityColor,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 22,
                        ),
                        const Text(
                          'Description',
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          scan.description
                                  .isEmpty
                              ? 'No description available.'
                              : scan.description,
                          style: TextStyle(
                            height: 1.5,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Icon(
                              Icons
                                  .access_time,
                              color: Color(
                                0xFF179E43,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                _formatDate(
                                  scan.scannedAt
                                      .toDate(),
                                ),
                                style:
                                    const TextStyle(
                                  fontSize:
                                      14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
