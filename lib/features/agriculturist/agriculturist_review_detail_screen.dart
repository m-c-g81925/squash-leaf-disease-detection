import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AgriculturistReviewDetailScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const AgriculturistReviewDetailScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  @override
  State<AgriculturistReviewDetailScreen> createState() =>
      _AgriculturistReviewDetailScreenState();
}

class _AgriculturistReviewDetailScreenState
    extends State<AgriculturistReviewDetailScreen> {
  static const Color _primaryColor = Color(0xFF179E43);
  static const Color _backgroundColor = Color(0xFFF5F7FB);

  final TextEditingController _diagnosisController =
      TextEditingController();

  final TextEditingController _recommendationController =
      TextEditingController();

  String _selectedStatus = 'reviewed';
  bool _isSaving = false;

  static const String _baseUrl = 'http://10.0.25.151:8000';
  bool _isLoadingImage = false;
  Uint8List? _submittedImageBytes;
  String? _imageError;

  String get _imagePath =>
      widget.data['imagePath']?.toString().trim() ?? '';

  static const List<String> _statusOptions = [
    'reviewed',
    'verified',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();

    _diagnosisController.text =
        widget.data['expertDiagnosis']?.toString() ?? '';

    _recommendationController.text =
        widget.data['recommendation']?.toString() ?? '';

    final String savedStatus =
        widget.data['status']?.toString().toLowerCase() ??
            'pending';

    if (_statusOptions.contains(savedStatus)) {
      _selectedStatus = savedStatus;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_imagePath.isNotEmpty) {
        _loadSubmittedImage();
      }
    });
  }

  Future<void> _loadSubmittedImage() async {
    if (_isLoadingImage || _imagePath.isEmpty) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _imageError = 'You must be logged in to view this image.');
      return;
    }

    setState(() {
      _isLoadingImage = true;
      _imageError = null;
    });

    try {
      final String? idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Unable to verify the agriculturist account.');
      }

      final Uri uri = Uri.parse('$_baseUrl/expert-review/image').replace(
        queryParameters: <String, String>{'image_path': _imagePath},
      );

      final http.Response response = await http.get(
        uri,
        headers: <String, String>{'Authorization': 'Bearer $idToken'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        String message = 'Unable to load the submitted leaf image.';
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['detail'] != null) {
            message = decoded['detail'].toString();
          }
        } catch (_) {}
        throw StateError(message);
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) throw StateError('The server returned an invalid image response.');

      final String signedUrl = decoded['signedUrl']?.toString().trim() ?? '';
      if (signedUrl.isEmpty) throw StateError('The server did not return an image URL.');

      final http.Response imageResponse = await http.get(
        Uri.parse(signedUrl),
      ).timeout(const Duration(seconds: 30));

      if (imageResponse.statusCode != 200) {
        throw StateError('The image server returned ${imageResponse.statusCode}.');
      }
      if (imageResponse.bodyBytes.isEmpty) {
        throw StateError('The submitted image contained no data.');
      }
      if (!mounted) return;

      setState(() {
        _submittedImageBytes = imageResponse.bodyBytes;
        _isLoadingImage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingImage = false;
        _imageError = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Widget _buildSubmittedPhotoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submitted Leaf Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (_imagePath.isEmpty)
            const SizedBox(height: 160, child: Center(child: Text('No photo is attached to this request.')))
          else if (_isLoadingImage)
            const SizedBox(height: 210, child: Center(child: CircularProgressIndicator(color: _primaryColor)))
          else if (_imageError != null)
            SizedBox(
              height: 190,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_outlined, color: Colors.red, size: 38),
                    const SizedBox(height: 8),
                    Text(_imageError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    TextButton.icon(onPressed: _loadSubmittedImage, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
                  ],
                ),
              ),
            )
          else if (_submittedImageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 200, maxHeight: 360),
                color: const Color(0xFFF0F2F0),
                alignment: Alignment.center,
                child: Image.memory(
                  _submittedImageBytes!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  cacheWidth: 1200,
                  errorBuilder: (_, __, ___) => SizedBox(
                    height: 210,
                    child: Center(child: TextButton.icon(onPressed: _loadSubmittedImage, icon: const Icon(Icons.refresh), label: const Text('Reload Photo'))),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'reviewed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'reviewed':
        return Icons.fact_check;
      default:
        return Icons.pending_actions;
    }
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'No submission date';
    }

    final DateTime date = value.toDate();

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

  Future<void> _saveReview() async {
    if (_isSaving) {
      return;
    }

    final String diagnosis =
        _diagnosisController.text.trim();

    final String recommendation =
        _recommendationController.text.trim();

    if (diagnosis.isEmpty || recommendation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter both the diagnosis and recommendation.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('expert_reviews')
          .doc(widget.documentId)
          .update({
        'expertDiagnosis': diagnosis,
        'recommendation': recommendation,
        'status': _selectedStatus,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expert review saved successfully.',
          ),
          backgroundColor: _primaryColor,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save review: '
            '${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save review: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String farmerName =
        widget.data['farmerName']?.toString() ??
            'Unknown Farmer';

    final String municipality =
        widget.data['municipality']?.toString() ??
            'Not provided';

    final String contactNumber =
        widget.data['contactNumber']?.toString() ??
            'Not provided';

    final String aiPrediction =
        widget.data['aiPrediction']?.toString() ??
            'Unknown Prediction';

    final double confidence =
        (widget.data['confidence'] as num?)
                ?.toDouble() ??
            0.0;

    final String currentStatus =
        widget.data['status']?.toString() ??
            'pending';

    final Color currentStatusColor =
        _statusColor(currentStatus);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Review Request Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildPredictionCard(
              prediction: aiPrediction,
              confidence: confidence,
              status: currentStatus,
              statusColor: currentStatusColor,
            ),
            const SizedBox(height: 16),
            _buildSubmittedPhotoCard(),
            const SizedBox(height: 16),
            _buildFarmerCard(
              farmerName: farmerName,
              municipality: municipality,
              contactNumber: contactNumber,
              submittedDate: _formatDate(
                widget.data['submittedAt'],
              ),
            ),
            const SizedBox(height: 16),
            _buildReviewForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard({
    required String prediction,
    required double confidence,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(status),
              color: statusColor,
              size: 42,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            prediction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'AI Confidence: '
            '${confidence.toStringAsFixed(2)}%',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerCard({
    required String farmerName,
    required String municipality,
    required String contactNumber,
    required String submittedDate,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Farmer Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _detailRow(
            icon: Icons.person_outline,
            label: 'Farmer Name',
            value: farmerName,
          ),
          _detailRow(
            icon: Icons.location_city_outlined,
            label: 'Municipality',
            value: municipality,
          ),
          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Contact Number',
            value: contactNumber,
          ),
          _detailRow(
            icon: Icons.access_time,
            label: 'Submitted',
            value: submittedDate,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expert Review',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _diagnosisController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Expert Diagnosis',
              hintText:
                  'Enter the verified disease or condition.',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 55),
                child: Icon(
                  Icons.medical_information_outlined,
                  color: _primaryColor,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _recommendationController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Recommendation',
              hintText:
                  'Enter treatment and prevention recommendations.',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 75),
                child: Icon(
                  Icons.recommend_outlined,
                  color: _primaryColor,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Review Status',
              prefixIcon: Icon(
                _statusIcon(_selectedStatus),
                color: _statusColor(_selectedStatus),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _statusOptions.map(
              (String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status[0].toUpperCase() +
                        status.substring(1),
                  ),
                );
              },
            ).toList(),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  _isSaving ? null : _saveReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Saving Review...'
                    : 'Save Expert Review',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: _primaryColor,
              size: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}