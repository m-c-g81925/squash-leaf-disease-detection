import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../schedule_detail_screen.dart';
import 'empty_schedule.dart';
import 'loading_widget.dart';
import 'schedule_card.dart';

class SavedScheduleList extends StatelessWidget {
  final DateTime selectedDay;
  final String Function(DateTime) createDateKey;
  final String userId;

  const SavedScheduleList({
    super.key,
    required this.selectedDay,
    required this.createDateKey,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String dateKey = createDateKey(selectedDay);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .where('dateKey', isEqualTo: dateKey)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.red.shade200,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to load schedules',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const LoadingWidget();
        }

        final schedules = snapshot.data?.docs ?? [];

        if (schedules.isEmpty) {
          return const EmptySchedule();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final document = schedules[index];
            final data = document.data();

            return ScheduleCard(
              schedule: data,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleDetailScreen(
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
    );
  }
}
