import 'package:cloud_firestore/cloud_firestore.dart';

class ScanHistory {
  final String id;
  final String disease;
  final double confidence;
  final String severity;
  final String description;
  final String imagePath;
  final Timestamp scannedAt;

  ScanHistory({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.imagePath,
    required this.scannedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'description': description,
      'imagePath': imagePath,
      'scannedAt': scannedAt,
    };
  }

  factory ScanHistory.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    return ScanHistory(
      id: id,
      disease: data['disease']?.toString() ?? '',
      confidence:
          (data['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: data['severity']?.toString() ?? '',
      description:
          data['description']?.toString() ?? '',
      imagePath: data['imagePath']?.toString() ?? '',
      scannedAt: data['scannedAt'] is Timestamp
          ? data['scannedAt'] as Timestamp
          : Timestamp.now(),
    );
  }
}