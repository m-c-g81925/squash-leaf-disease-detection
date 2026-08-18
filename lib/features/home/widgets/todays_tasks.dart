import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../calendar/schedule_detail_screen.dart';

class TodaysTasks extends StatelessWidget {
  const TodaysTasks({super.key});

  String _todayDateKey() {
    final DateTime now = DateTime.now();

    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Planting':
        return Icons.eco;
      case 'Watering':
        return Icons.water_drop;
      case 'Fertilizing':
        return Icons.grass;
      case 'Disease Scan':
        return Icons.camera_alt;
      case 'Pest Control':
        return Icons.shield;
      case 'Weeding':
        return Icons.yard;
      case 'Harvest':
        return Icons.agriculture;
      default:
        return Icons.event_note;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Watering':
        return Colors.blue;
      case 'Fertilizing':
        return Colors.orange;
      case 'Disease Scan':
        return Colors.red;
      case 'Pest Control':
        return Colors.deepPurple;
      case 'Weeding':
        return Colors.teal;
      case 'Harvest':
        return Colors.brown;
      default:
        return const Color(0xFF179E43);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
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
            'dateKey',
            isEqualTo: _todayDateKey(),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF179E43),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _messageCard(
            icon: Icons.error_outline,
            title: 'Unable to Load Today\'s Tasks',
            message: snapshot.error.toString(),
            iconColor: Colors.red,
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
            snapshot.data?.docs ?? [];

        documents.sort((first, second) {
          final String firstTime =
              first.data()['time']?.toString() ?? '';
          final String secondTime =
              second.data()['time']?.toString() ?? '';

          return firstTime.compareTo(secondTime);
        });

        if (documents.isEmpty) {
          return _messageCard(
            icon: Icons.event_available,
            title: 'No Tasks Today',
            message:
                'You have no farming activities scheduled for today.',
            iconColor: const Color(0xFF179E43),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: documents.map((document) {
              final Map<String, dynamic> data = document.data();

              final String task =
                  data['task']?.toString() ?? 'Schedule';

              final String type =
                  data['type']?.toString() ?? 'Other';

              final String time =
                  data['time']?.toString() ?? 'No time';

              final String priority =
                  data['priority']?.toString() ?? 'Medium';

              final String status =
                  data['status']?.toString() ?? 'Pending';

              return _TaskItem(
                task: task,
                type: type,
                time: time,
                priority: priority,
                status: status,
                icon: _typeIcon(type),
                typeColor: _typeColor(type),
                priorityColor: _priorityColor(priority),
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
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: iconColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
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
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String task;
  final String type;
  final String time;
  final String priority;
  final String status;
  final IconData icon;
  final Color typeColor;
  final Color priorityColor;
  final VoidCallback onTap;

  const _TaskItem({
    required this.task,
    required this.type,
    required this.time,
    required this.priority,
    required this.status,
    required this.icon,
    required this.typeColor,
    required this.priorityColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool completed =
        status.toLowerCase() == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    completed ? Icons.check_circle : icon,
                    color: completed ? Colors.green : typeColor,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        task,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$type • $time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
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
        ),
      ),
    );
  }
}