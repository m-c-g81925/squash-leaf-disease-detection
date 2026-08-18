import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExpertReviewRequestsScreen extends StatelessWidget {
  const ExpertReviewRequestsScreen({super.key});

  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF6F7F5);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'completed':
      case 'reviewed':
        return const Color(0xFF2F7D45);

      case 'rejected':
        return const Color(0xFFC33A32);

      case 'pending':
      default:
        return const Color(0xFFB56A00);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'completed':
      case 'reviewed':
        return Icons.verified;

      case 'rejected':
        return Icons.cancel;

      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'No submission date';
    }

    final DateTime date = timestamp.toDate();

    final int hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String minute =
        date.minute.toString().padLeft(2, '0');

    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.month}/${date.day}/${date.year} '
        'at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final String? userId =
        FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text('Expert review requests'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2923),
          elevation: 0,
        ),
        body: _buildMessageState(
          icon: Icons.lock_outline,
          title: 'Login required',
          message:
              'Please log in to view your expert review requests.',
          color: Colors.orange,
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Expert review requests',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2923),
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('expert_reviews')
            .where(
              'userId',
              isEqualTo: userId,
            )
            .orderBy(
              'submittedAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildMessageState(
              icon: Icons.error_outline,
              title: 'Unable to load requests',
              message: snapshot.error.toString(),
              color: Colors.red,
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return _buildMessageState(
              icon: Icons.assignment_outlined,
              title: 'No review requests yet',
              message:
                  'Your submitted expert review requests will appear here.',
              color: _primaryColor,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final document = documents[index];
              final Map<String, dynamic> data =
                  document.data();

              return _ReviewRequestCard(
                key: ValueKey(document.id),
                data: data,
                formattedDate: _formatDate(
                  data['submittedAt'] is Timestamp
                      ? data['submittedAt'] as Timestamp
                      : null,
                ),
                statusColor: _statusColor(
                  data['status']?.toString() ??
                      'pending',
                ),
                statusIcon: _statusIcon(
                  data['status']?.toString() ??
                      'pending',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2923),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5E6962),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRequestCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formattedDate;
  final Color statusColor;
  final IconData statusIcon;

  const _ReviewRequestCard({
    super.key,
    required this.data,
    required this.formattedDate,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  State<_ReviewRequestCard> createState() =>
      _ReviewRequestCardState();
}

class _ReviewRequestCardState
    extends State<_ReviewRequestCard> {
  static const String _baseUrl =
      'http://10.0.25.151:8000';

  bool _isLoadingImage = false;
  String? _imageError;
  Uint8List? _imageBytes;

  // Keeps already-downloaded farmer request photos in memory.
  static final Map<String, Uint8List> _imageCache =
      <String, Uint8List>{};

  String get _imagePath =>
      widget.data['imagePath']
              ?.toString()
              .trim() ??
          '';

  @override
  void initState() {
    super.initState();

    final Uint8List? cachedImage = _imageCache[_imagePath];
    if (cachedImage != null) {
      _imageBytes = cachedImage;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startImageLoadIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant _ReviewRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final String oldImagePath =
        oldWidget.data['imagePath']?.toString().trim() ?? '';

    if (oldImagePath != _imagePath) {
      _imageBytes = _imageCache[_imagePath];
      _imageError = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startImageLoadIfNeeded();
      });
    }
  }

  void _startImageLoadIfNeeded() {
    if (!mounted) return;

    debugPrint('FARMER REQUEST PHOTO PATH: $_imagePath');

    if (_imagePath.isNotEmpty &&
        _imageBytes == null &&
        !_isLoadingImage) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_isLoadingImage ||
        _imagePath.isEmpty) {
      return;
    }

    final Uint8List? cachedImage = _imageCache[_imagePath];
    if (cachedImage != null) {
      if (!mounted) return;

      setState(() {
        _imageBytes = cachedImage;
        _imageError = null;
      });
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
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
      final String? idToken =
          await user.getIdToken();

      if (idToken == null ||
          idToken.isEmpty) {
        throw StateError(
          'Unable to verify your account.',
        );
      }

      final Uri uri = Uri.parse(
        '$_baseUrl/expert-review/image',
      ).replace(
        queryParameters: <String, String>{
          'image_path': _imagePath,
        },
      );

      debugPrint('FARMER REQUEST PHOTO GET: $uri');

      final http.Response response =
          await http.get(
        uri,
        headers: <String, String>{
          'Authorization':
              'Bearer $idToken',
        },
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        String message =
            'Unable to load the submitted image.';

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

      final String signedUrl =
          decoded is Map
              ? decoded['signedUrl']
                      ?.toString()
                      .trim() ??
                  ''
              : '';

      if (signedUrl.isEmpty) {
        throw StateError(
          'The server did not return an image URL.',
        );
      }

      final http.Response imageResponse =
          await http.get(
        Uri.parse(signedUrl),
      ).timeout(
        const Duration(seconds: 30),
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

      debugPrint(
        'FARMER REQUEST PHOTO DOWNLOADED: ${imageBytes.length} bytes',
      );

      _imageCache[_imagePath] = imageBytes;

      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytes = imageBytes;
        _isLoadingImage = false;
        _imageError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingImage = false;
        _imageError = error
            .toString()
            .replaceFirst(
              'Bad state: ',
              '',
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imagePath.isNotEmpty &&
        _imageBytes == null &&
        !_isLoadingImage &&
        _imageError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startImageLoadIfNeeded();
      });
    }

    final String prediction =
        widget.data['aiPrediction']
                ?.toString() ??
            'Unknown Prediction';

    final double confidence =
        (widget.data['confidence'] as num?)
                ?.toDouble() ??
            0.0;

    final String status =
        widget.data['status']
                ?.toString() ??
            'pending';

    final String farmerName =
        widget.data['farmerName']
                ?.toString() ??
            'Unknown Farmer';

    final String municipality =
        widget.data['municipality']
                ?.toString() ??
            'Not provided';

    final String diagnosis =
        widget.data['expertDiagnosis']
                ?.toString() ??
            '';

    final String recommendation =
        widget.data['recommendation']
                ?.toString() ??
            '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE1E7E2),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.statusColor
                      .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.statusIcon,
                  color: widget.statusColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF1F2923),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Confidence: '
                      '${confidence.toStringAsFixed(2)}%',
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF5E6962),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.statusColor
                      .withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color:
                        widget.statusColor,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildPhoto(),

          const SizedBox(height: 14),

          _detailRow(
            icon: Icons.person_outline,
            text: farmerName,
          ),
          const SizedBox(height: 8),
          _detailRow(
            icon:
                Icons.location_city_outlined,
            text: municipality,
          ),
          const SizedBox(height: 8),
          _detailRow(
            icon: Icons.access_time,
            text: widget.formattedDate,
          ),

          if (diagnosis.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Expert diagnosis',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1F2923),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              diagnosis,
              style: const TextStyle(
                height: 1.4,
                color: Color(0xFF39423C),
              ),
            ),
          ],

          if (recommendation
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              'Recommendation',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1F2923),
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEAF5ED),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                recommendation,
                style: const TextStyle(
                  color:
                      Color(0xFF0B7D35),
                  height: 1.4,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),
          ],

          if (diagnosis.trim().isEmpty &&
              recommendation
                  .trim()
                  .isEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 15,
              ),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF4E3),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        const Color(0xFFF2D29F),
                  ),
                ),
                child: const Text(
                  'Waiting for an agriculturist to review this request.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Color(0xFF8C5A00),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (_imagePath.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              const Color(0xFFF3F5F3),
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: const Text(
          'No photo is available for this older request.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF5E6962),
            fontSize: 12.5,
          ),
        ),
      );
    }

    if (_isLoadingImage) {
      return Container(
        width: double.infinity,
        height: 190,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              const Color(0xFFF3F5F3),
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF179E43),
            ),
            SizedBox(height: 9),
            Text(
              'Loading submitted photo...',
              style: TextStyle(
                color:
                    Color(0xFF5E6962),
              ),
            ),
          ],
        ),
      );
    }

    if (_imageError != null) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              const Color(0xFFFFF3F1),
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color:
                const Color(0xFFF1C7C3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: Colors.red,
            ),
            const SizedBox(height: 6),
            Text(
              _imageError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    Color(0xFF7F2A24),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 7),
            TextButton.icon(
              onPressed: _loadImage,
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text('Reload photo'),
            ),
          ],
        ),
      );
    }

    if (_imageBytes == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        constraints:
            const BoxConstraints(
          minHeight: 180,
          maxHeight: 300,
        ),
        color:
            const Color(0xFFF3F5F3),
        child: Image.memory(
          _imageBytes!,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color:
              const Color(0xFF179E43),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color:
                  Color(0xFF4F5A53),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
