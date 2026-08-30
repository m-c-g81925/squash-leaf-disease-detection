import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExpertReviewScreen extends StatelessWidget {
  const ExpertReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: const Text(
          'Expert reviews',
          style: TextStyle(
            color: Color(0xFF1F2923),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2923),
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expert_reviews')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF179E43),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load review requests.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5E6962),
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No expert review requests yet.',
                style: TextStyle(
                  color: Color(0xFF5E6962),
                ),
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final doc = reviews[index];
              final data = doc.data() as Map<String, dynamic>;

              return _ReviewCard(
                key: ValueKey(doc.id),
                documentId: doc.id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const _ReviewCard({
    super.key,
    required this.documentId,
    required this.data,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard>
    with AutomaticKeepAliveClientMixin<_ReviewCard> {
  static const Color _primaryColor = Color(0xFF179E43);
  static const String _baseUrl =
      'https://squash-leaf-disease-detection.onrender.com';

  final TextEditingController diagnosisController =
      TextEditingController();
  final TextEditingController recommendationController =
      TextEditingController();

  bool _isLoadingImage = false;
  bool _isSubmitting = false;
  Uint8List? _submittedImageBytes;
  String? _imageError;

  // Keeps already-downloaded review photos available even if
  // Flutter rebuilds a card after scrolling.
  static final Map<String, Uint8List> _imageCache =
      <String, Uint8List>{};

  String get _imagePath =>
      widget.data['imagePath']?.toString().trim() ?? '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    diagnosisController.text =
        widget.data['expertDiagnosis']?.toString() ?? '';

    recommendationController.text =
        widget.data['recommendation']?.toString() ?? '';

    final Uint8List? cachedImage = _imageCache[_imagePath];

    if (cachedImage != null) {
      _submittedImageBytes = cachedImage;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_imagePath.isNotEmpty && _submittedImageBytes == null) {
        _loadPrivateImage();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final String oldImagePath =
        oldWidget.data['imagePath']?.toString().trim() ?? '';

    if (oldImagePath != _imagePath) {
      _submittedImageBytes = _imageCache[_imagePath];
      _imageError = null;

      if (_submittedImageBytes == null &&
          _imagePath.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadPrivateImage();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    diagnosisController.dispose();
    recommendationController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivateImage() async {
    if (_imagePath.isEmpty || _isLoadingImage) {
      return;
    }

    final Uint8List? cachedImage = _imageCache[_imagePath];

    if (cachedImage != null) {
      if (!mounted) return;

      setState(() {
        _submittedImageBytes = cachedImage;
        _imageError = null;
      });

      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _imageError =
            'You must be logged in to view this image.';
      });

      return;
    }

    setState(() {
      _isLoadingImage = true;
      _imageError = null;
    });

    try {
      final String? idToken = await user.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Unable to verify the agriculturist account.',
        );
      }

      final Uri uri = Uri.parse(
        '$_baseUrl/expert-review/image',
      ).replace(
        queryParameters: <String, String>{
          'image_path': _imagePath,
        },
      );

      debugPrint('FARMER REQUEST IMAGE PATH: $_imagePath');
      debugPrint('FARMER REQUEST IMAGE GET: $uri');

      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer $idToken',
        },
      ).timeout(
        const Duration(seconds: 120),
      );

      if (response.statusCode != 200) {
        String message =
            'Unable to load the submitted leaf image.';

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
          'The server returned an invalid image response.',
        );
      }

      final String signedUrl =
          decoded['signedUrl']?.toString().trim() ?? '';

      if (signedUrl.isEmpty) {
        throw StateError(
          'The server did not return an image URL.',
        );
      }

      final http.Response imageResponse =
          await http.get(
        Uri.parse(signedUrl),
      ).timeout(
        const Duration(seconds: 120),
      );

      if (imageResponse.statusCode != 200) {
        throw StateError(
          'The image server returned '
          '${imageResponse.statusCode}.',
        );
      }

      if (imageResponse.bodyBytes.isEmpty) {
        throw StateError(
          'The submitted image contained no data.',
        );
      }

      final Uint8List imageBytes =
          imageResponse.bodyBytes;

      // Save the bytes in memory so scrolling down and back up
      // does not require another signed URL request.
      _imageCache[_imagePath] = imageBytes;

      if (!mounted) return;

      setState(() {
        _submittedImageBytes = imageBytes;
        _isLoadingImage = false;
        _imageError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingImage = false;
        _imageError =
            error.toString().replaceFirst(
                  'Bad state: ',
                  '',
                );
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) {
      return;
    }

    final String diagnosis = diagnosisController.text.trim();
    final String recommendation =
        recommendationController.text.trim();

    if (diagnosis.isEmpty || recommendation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter both the diagnosis and recommendation.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('expert_reviews')
          .doc(widget.documentId)
          .update({
        'expertDiagnosis': diagnosis,
        'recommendation': recommendation,
        'status': 'reviewed',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expert feedback submitted.'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to submit expert feedback: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_imagePath.isNotEmpty &&
        _submittedImageBytes == null &&
        !_isLoadingImage &&
        _imageError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadPrivateImage();
        }
      });
    }

    final String aiPrediction =
        widget.data['aiPrediction']?.toString() ?? 'Unknown';

    final dynamic confidence = widget.data['confidence'] ?? 0;

    final String status =
        widget.data['status']?.toString() ?? 'pending';

    final String farmerName =
        widget.data['farmerName']?.toString().trim() ?? '';

    final String municipality =
        widget.data['municipality']?.toString().trim() ?? '';

    final String contactNumber =
        widget.data['contactNumber']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1E7E2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBadge(status),
          if (farmerName.isNotEmpty ||
              municipality.isNotEmpty ||
              contactNumber.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Farmer information',
              style: TextStyle(
                color: Color(0xFF1F2923),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            if (farmerName.isNotEmpty)
              Text(
                farmerName,
                style: const TextStyle(
                  color: Color(0xFF1F2923),
                  fontSize: 14,
                ),
              ),
            if (municipality.isNotEmpty)
              Text(
                municipality,
                style: const TextStyle(
                  color: Color(0xFF5E6962),
                  fontSize: 13,
                ),
              ),
            if (contactNumber.isNotEmpty)
              Text(
                contactNumber,
                style: const TextStyle(
                  color: Color(0xFF5E6962),
                  fontSize: 13,
                ),
              ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Submitted leaf photo',
            style: TextStyle(
              color: Color(0xFF1F2923),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildSubmittedImage(),
          const SizedBox(height: 15),
          Text(
            'System prediction: $aiPrediction',
            style: const TextStyle(
              color: Color(0xFF1F2923),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confidence: $confidence%',
            style: const TextStyle(
              color: Color(0xFF5E6962),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: diagnosisController,
            decoration: InputDecoration(
              labelText: 'Diagnosis',
              filled: true,
              fillColor: const Color(0xFFF6F7F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFD7DED8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: recommendationController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Recommendation',
              filled: true,
              fillColor: const Color(0xFFF6F7F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFD7DED8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _primaryColor.withOpacity(0.55),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline,
                    ),
              label: Text(
                _isSubmitting
                    ? 'Submitting...'
                    : 'Submit feedback',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedImage() {
    if (_imagePath.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF68736B),
              size: 32,
            ),
            SizedBox(height: 7),
            Text(
              'No submitted image is available for this older request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5E6962),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingImage) {
      return Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
            ),
            SizedBox(height: 10),
            Text(
              'Loading submitted leaf image...',
              style: TextStyle(
                color: Color(0xFF5E6962),
              ),
            ),
          ],
        ),
      );
    }

    if (_imageError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFF1C7C3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 7),
            Text(
              _imageError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7F2A24),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadPrivateImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_submittedImageBytes == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.image_outlined,
              color: Color(0xFF68736B),
              size: 32,
            ),
            const SizedBox(height: 7),
            const Text(
              'Farmer photo is ready to load.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5E6962),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadPrivateImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Load image'),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 220,
          maxHeight: 380,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F3),
          border: Border.all(
            color: const Color(0xFFDDE5DF),
          ),
        ),
        alignment: Alignment.center,
        child: Image.memory(
          _submittedImageBytes!,
          width: double.infinity,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('FARMER REQUEST IMAGE DECODE ERROR: $error');
            return SizedBox(
              height: 210,
              child: Center(
                child: TextButton.icon(
                  onPressed: _loadPrivateImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload photo'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final bool reviewed =
        status.toLowerCase() == 'reviewed';

    final Color color = reviewed
        ? const Color(0xFF2F7D45)
        : const Color(0xFFB56A00);

    final Color background = reviewed
        ? const Color(0xFFE7F4EA)
        : const Color(0xFFFFF1DD);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          reviewed ? 'Reviewed' : 'Pending',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
 }