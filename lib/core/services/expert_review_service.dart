import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ExpertReviewService {
  ExpertReviewService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const String _collection = 'expert_reviews';

  // Change this if your computer's IPv4 address changes.
  static const String _baseUrl =
      'http://10.0.25.151:8000';

  static Future<void> submitReview({
    required File imageFile,
    required String aiPrediction,
    required double confidence,
    required String farmerName,
    required String municipality,
    required String contactNumber,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must be logged in to submit an expert review request.',
      );
    }

    if (!await imageFile.exists()) {
      throw StateError(
        'The selected leaf image could not be found.',
      );
    }

    // Check extension.
    final String filePath = imageFile.path;
    final String extension =
        filePath.split('.').last.toLowerCase();

    if (extension != 'jpg' &&
        extension != 'jpeg' &&
        extension != 'png') {
      throw StateError(
        'Only JPG, JPEG, and PNG images are allowed.',
      );
    }

    final String? idToken =
        await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Unable to verify your account.',
      );
    }

    final Uri uploadUri = Uri.parse(
      '$_baseUrl/expert-review/upload',
    );

    final http.MultipartRequest request =
        http.MultipartRequest(
      'POST',
      uploadUri,
    );

    request.headers['Authorization'] =
        'Bearer $idToken';

    // Explicitly assign MIME type.
    //
    // .jpg and .jpeg BOTH use image/jpeg.
    // .png uses image/png.
    final String mimeType =
        extension == 'png'
            ? 'image/png'
            : 'image/jpeg';

    final List<int> imageBytes =
        await imageFile.readAsBytes();

    final http.MultipartFile multipartFile =
        http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename:
          'expert_review_${DateTime.now().millisecondsSinceEpoch}.$extension',
      contentType: http.MediaType.parse(mimeType),
    );

    request.files.add(multipartFile);

    final http.StreamedResponse streamedResponse =
        await request.send().timeout(
      const Duration(seconds: 60),
    );

    final http.Response response =
        await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      String message =
          'Unable to upload the leaf image.';

      try {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is Map &&
            decoded['detail'] != null) {
          message =
              decoded['detail'].toString();
        }
      } catch (_) {}

      throw StateError(message);
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw StateError(
        'The server returned an invalid response.',
      );
    }

    final String imagePath =
        decoded['imagePath']
                ?.toString()
                .trim() ??
            '';

    if (imagePath.isEmpty) {
      throw StateError(
        'The server did not return an image path.',
      );
    }

    final Map<String, dynamic> review = {
      'userId': user.uid,
      'email': user.email ?? '',
      'imagePath': imagePath,
      'aiPrediction': aiPrediction.trim(),
      'confidence': confidence,
      'farmerName': farmerName.trim(),
      'municipality': municipality.trim(),
      'contactNumber': contactNumber.trim(),
      'status': 'pending',
      'expertDiagnosis': '',
      'recommendation': '',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection(_collection)
          .add(review);
    } catch (_) {
      throw StateError(
        'The image was uploaded, but the review request could not be saved.',
      );
    }
  }
}