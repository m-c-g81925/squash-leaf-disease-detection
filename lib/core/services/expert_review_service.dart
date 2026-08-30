import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpertReviewService {
  ExpertReviewService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static const String _collection = 'expert_reviews';
  static const String _bucket = 'expert-review-images';

  // Keeps the review image clear enough for the agriculturist
  // while reducing upload/download time.
  static const int _maxImageDimension = 1024;
  static const int _jpegQuality = 82;

  static Future<void> submitReview({
    required File imageFile,
    required String aiPrediction,
    required double confidence,
    required String farmerName,
    required String municipality,
    required String contactNumber,
  }) async {
    final firebase_auth.User? user = _auth.currentUser;

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

    final String extension =
        imageFile.path.split('.').last.toLowerCase();

    if (extension != 'jpg' &&
        extension != 'jpeg' &&
        extension != 'png') {
      throw StateError(
        'Only JPG, JPEG, and PNG images are allowed.',
      );
    }

    final Uint8List originalBytes =
        await imageFile.readAsBytes();

    final img.Image? decodedImage =
        img.decodeImage(originalBytes);

    if (decodedImage == null) {
      throw StateError(
        'The selected file is not a valid image.',
      );
    }

    img.Image processedImage = decodedImage;

    if (decodedImage.width > _maxImageDimension ||
        decodedImage.height > _maxImageDimension) {
      if (decodedImage.width >= decodedImage.height) {
        processedImage = img.copyResize(
          decodedImage,
          width: _maxImageDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        processedImage = img.copyResize(
          decodedImage,
          height: _maxImageDimension,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    // Convert every Expert Review image to JPEG.
    // This keeps file sizes small and consistent.
    final Uint8List uploadBytes = Uint8List.fromList(
      img.encodeJpg(
        processedImage,
        quality: _jpegQuality,
      ),
    );

    const int maxUploadSize = 5 * 1024 * 1024;

    if (uploadBytes.length > maxUploadSize) {
      throw StateError(
        'The optimized image is still larger than the 5 MB limit.',
      );
    }

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';

    final String storagePath =
        '${user.uid}/$fileName';

    try {
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            uploadBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
              cacheControl: '3600',
            ),
          );
    } on StorageException catch (error) {
      throw StateError(
        'Unable to upload the leaf image: ${error.message}',
      );
    } catch (error) {
      throw StateError(
        'Unable to upload the leaf image: $error',
      );
    }

    final String publicImageUrl =
        _supabase.storage
            .from(_bucket)
            .getPublicUrl(storagePath);

    final Map<String, dynamic> review = {
      'userId': user.uid,
      'email': user.email ?? '',
      'imagePath': storagePath,
      'imageUrl': publicImageUrl,
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
