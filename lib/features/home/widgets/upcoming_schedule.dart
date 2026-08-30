import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../calendar/schedule_detail_screen.dart';

class UpcomingSchedule extends StatelessWidget {
  const UpcomingSchedule({super.key});

  DateTime _getDate(Map<String, dynamic> data) {
    final value = data['date'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  String _task(Map<String, dynamic> data) {
    if (data['task'] != null &&
        data['task'].toString().trim().isNotEmpty) {
      return data['task'];
    }

    if (data['activity'] != null) {
      return data['activity']
          .toString()
          .split('•')
          .first
          .trim();
    }

    return 'Schedule';
  }

  String _type(Map<String, dynamic> data) {
    if (data['type'] != null &&
        data['type'].toString().trim().isNotEmpty) {
      return data['type'];
    }

    if (data['activity'] != null) {
      final parts = data['activity']
          .toString()
          .split('•')
          .map((e) => e.trim())
          .toList();

      if (parts.length >= 2) {
        return parts[1];
      }
    }

    return 'Iban';
  }

  IconData _icon(String type) {
    switch (type) {
      case 'Pagtanom':
        return Icons.eco;

      case 'Pagbunyag':
        return Icons.water_drop;

      case 'Pagbutang sang Abono':
        return Icons.grass;

      case 'Pag-scan sang Balatian':
        return Icons.camera_alt;

      case 'Pagkontrol sang Peste':
        return Icons.shield;

      case 'Pagpanghilamon':
        return Icons.yard;

      case 'Pag-ani':
        return Icons.agriculture;

      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  String _formatTime(DateTime date, BuildContext context) {
    return TimeOfDay.fromDateTime(date).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('schedules')
          .where(
            'userId',
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          )
          .where(
            'date',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime.now()),
          )
          .orderBy('date')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text("Indi ma-load ang mga schedule."),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Color(0xFF179E43),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Masunod nga mga Schedule",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 20,
                  ),
                  child: Center(
                    child: Text(
                      "Wala sang masunod nga schedule.",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                ...docs.map((doc) {
                  final data = doc.data();

                  final date = _getDate(data);

                  final task = _task(data);

                  final type = _type(data);

                  return InkWell(
                    borderRadius:
                        BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ScheduleDetailScreen(
                            documentId: doc.id,
                            data: {
                              ...data,
                              'id': doc.id,
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF7F9FC,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                const Color(
                              0xFFE8F5E9,
                            ),
                            child: Icon(
                              _icon(type),
                              color:
                                  const Color(0xFF179E43),
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
                                  task,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 15,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  type,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  "${_formatDate(date)} • ${_formatTime(date, context)}",
                                  style:
                                      const TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
