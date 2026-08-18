import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/scan_history_model.dart';

class ScanHistoryService {
  ScanHistoryService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collectionName = 'scan_history';
  static const int _maximumBatchSize = 450;

  static CollectionReference<Map<String, dynamic>>
      get _collection {
    return _firestore.collection(_collectionName);
  }

  static String _requireUserId() {
    final String? userId = _auth.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      throw StateError('No authenticated farmer was found.');
    }

    return userId;
  }

  // Save one scan result.
  static Future<void> saveScan({
    required String disease,
    required double confidence,
    required String severity,
    required String description,
    required String imagePath,
  }) async {
    final String userId = _requireUserId();

    await _collection.add({
      'userId': userId,
      'disease': disease.trim(),
      'confidence': confidence,
      'severity': severity.trim(),
      'description': description.trim(),
      'imagePath': imagePath.trim(),
      'scannedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all scan records, newest first.
  static Stream<List<ScanHistory>> getScanHistory() {
    final String userId = _requireUserId();

    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map(_mapSnapshotToHistory);
  }

  // Get only the most recent scan records.
  static Stream<List<ScanHistory>> getRecentScans({
    int limit = 3,
  }) {
    final String userId = _requireUserId();
    final int safeLimit = limit < 1 ? 1 : limit;

    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('scannedAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map(_mapSnapshotToHistory);
  }

  // Calculate dashboard statistics from scan history.
  static Stream<Map<String, dynamic>>
      getDashboardStatistics() {
    return getScanHistory().map((List<ScanHistory> scans) {
      int highRisk = 0;
      int mediumRisk = 0;
      int lowRisk = 0;

      double highestConfidence = 0;

      final Map<String, int> diseaseCount =
          <String, int>{};

      for (final ScanHistory scan in scans) {
        switch (scan.severity.trim().toLowerCase()) {
          case 'high':
          case 'critical':
            highRisk++;
            break;
          case 'medium':
            mediumRisk++;
            break;
          case 'low':
            lowRisk++;
            break;
        }

        if (scan.confidence > highestConfidence) {
          highestConfidence = scan.confidence;
        }

        final String diseaseName = scan.disease.trim();

        if (diseaseName.isNotEmpty) {
          diseaseCount.update(
            diseaseName,
            (int value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }

      return <String, dynamic>{
        'totalScans': scans.length,
        'highRisk': highRisk,
        'mediumRisk': mediumRisk,
        'lowRisk': lowRisk,
        'highestConfidence': highestConfidence,
        'mostCommonDisease':
            _findMostCommonDisease(diseaseCount),
      };
    });
  }

  // Delete one scan record.
  static Future<void> deleteScan(
    String documentId,
  ) async {
    final String id = documentId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'The scan history document ID cannot be empty.',
      );
    }

    final String userId = _requireUserId();
    final DocumentReference<Map<String, dynamic>> reference =
        _collection.doc(id);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await reference.get();

    if (!snapshot.exists) {
      throw StateError('This scan history record no longer exists.');
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    if (data['userId']?.toString() != userId) {
      throw StateError(
        'You are not allowed to delete this scan history record.',
      );
    }

    await reference.delete();
  }

  // Delete every scan record.
  //
  // Records are deleted in multiple batches so this continues
  // to work even when the collection contains hundreds of scans.
  static Future<void> deleteAllScans() async {
    final String userId = _requireUserId();

    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _collection
              .where('userId', isEqualTo: userId)
              .limit(_maximumBatchSize)
              .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = _firestore.batch();

      for (final QueryDocumentSnapshot<Map<String, dynamic>>
          document in snapshot.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();
    }
  }

  static List<ScanHistory> _mapSnapshotToHistory(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (
            QueryDocumentSnapshot<Map<String, dynamic>>
                document,
          ) {
            return ScanHistory.fromDocument(
              document.id,
              document.data(),
            );
          },
        )
        .toList(growable: false);
  }

  static String _findMostCommonDisease(
    Map<String, int> diseaseCount,
  ) {
    if (diseaseCount.isEmpty) {
      return 'None';
    }

    MapEntry<String, int>? mostCommon;

    for (final MapEntry<String, int> entry
        in diseaseCount.entries) {
      if (mostCommon == null ||
          entry.value > mostCommon.value) {
        mostCommon = entry;
      }
    }

    return mostCommon?.key ?? 'None';
  }
}
