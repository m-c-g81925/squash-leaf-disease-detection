import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/schedule_model.dart';

class CalendarService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _collectionName = 'schedules';

  // Save a new schedule
  static Future<void> addSchedule({
    required String activity,
    required DateTime date,
  }) async {
    await _firestore.collection(_collectionName).add({
      'activity': activity.trim(),
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all schedules, earliest date first
  static Stream<List<Schedule>> getAllSchedules() {
    return _firestore
        .collection(_collectionName)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        return Schedule.fromDocument(
          document.id,
          document.data(),
        );
      }).toList();
    });
  }

  // Get schedules for one selected date
  static Stream<List<Schedule>> getSchedulesByDate(
    DateTime selectedDate,
  ) {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    return _firestore
        .collection(_collectionName)
        .where(
          'date',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(startOfDay),
        )
        .where(
          'date',
          isLessThan: Timestamp.fromDate(endOfDay),
        )
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        return Schedule.fromDocument(
          document.id,
          document.data(),
        );
      }).toList();
    });
  }

  // Get upcoming schedules for the Home screen
  static Stream<List<Schedule>> getUpcomingSchedules({
    int limit = 3,
  }) {
    final now = DateTime.now();

    final startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return _firestore
        .collection(_collectionName)
        .where(
          'date',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(startOfToday),
        )
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        return Schedule.fromDocument(
          document.id,
          document.data(),
        );
      }).toList();
    });
  }

  // Update an existing schedule
  static Future<void> updateSchedule({
    required String documentId,
    required String activity,
    required DateTime date,
  }) async {
    await _firestore
        .collection(_collectionName)
        .doc(documentId)
        .update({
      'activity': activity.trim(),
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete one schedule
  static Future<void> deleteSchedule(
    String documentId,
  ) async {
    await _firestore
        .collection(_collectionName)
        .doc(documentId)
        .delete();
  }
}