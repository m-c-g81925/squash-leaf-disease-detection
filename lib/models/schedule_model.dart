import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String activity;
  final DateTime date;

  const Schedule({
    required this.id,
    required this.activity,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Schedule.fromDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final dateValue = data['date'];

    DateTime scheduleDate = DateTime.now();

    if (dateValue is Timestamp) {
      scheduleDate = dateValue.toDate();
    } else if (dateValue is DateTime) {
      scheduleDate = dateValue;
    } else if (dateValue is String) {
      scheduleDate =
          DateTime.tryParse(dateValue) ?? DateTime.now();
    }

    return Schedule(
      id: documentId,
      activity:
          data['activity']?.toString() ?? 'Untitled activity',
      date: scheduleDate,
    );
  }
}