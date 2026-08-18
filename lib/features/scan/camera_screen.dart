import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/expert_review_service.dart';
import '../../models/disease_model.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final File? galleryImage;

  const CameraScreen({
    super.key,
    this.galleryImage,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  bool _isReady = false;
  bool _hasError = false;
  bool _isAnalyzing = false;
  bool _isSubmittingReview = false;

  File? _capturedImage;

  static const double confidenceThreshold = 60.0;

  @override
  void initState() {
    super.initState();

    if (widget.galleryImage != null) {
      _capturedImage = widget.galleryImage;
      _isReady = true;
    } else {
      _initCamera();
    }
  }

  Disease _createDisease(String rawDisease) {
    final key = rawDisease.trim().toLowerCase();

    switch (key) {
      case 'healthy_leaf':
      case 'healthy':
        return const Disease(
          name: 'Healthy Leaf',
          severity: 'Low',
          image: '',
          description:
              'The leaf appears healthy and has no visible signs of disease. Continue proper watering, sanitation, and regular monitoring.',
        );

      case 'powdery_mildew':
      case 'powdery mildew':
        return const Disease(
          name: 'Powdery Mildew',
          severity: 'Medium',
          image: '',
          description:
              'A fungal disease that creates white powdery spots on the leaves. Remove infected leaves, improve airflow, and apply an appropriate fungicide when necessary.',
        );

      case 'downy_mildew':
      case 'downy mildew':
        return const Disease(
          name: 'Downy Mildew',
          severity: 'High',
          image: '',
          description:
              'A disease that commonly causes yellow patches and gray growth underneath leaves. Avoid overhead watering, remove infected leaves, and keep foliage dry.',
        );

      case 'mosaic_virus':
      case 'mosaic virus':
        return const Disease(
          name: 'Mosaic Virus',
          severity: 'High',
          image: '',
          description:
              'A viral disease that may cause yellow-green mosaic patterns, distorted leaves, and stunted growth. Remove infected plants and control insect carriers such as aphids.',
        );

      default:
        final displayName = rawDisease
            .replaceAll('_', ' ')
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map(
              (word) =>
                  '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
            )
            .join(' ');

        return Disease(
          name: displayName.isEmpty ? 'Unknown Result' : displayName,
          severity: 'Unknown',
          image: '',
          description:
              'The system detected this condition, but detailed information is not yet available. Consult an agricultural expert for verification.',
        );
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _hasError = true);
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);

      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await ApiService.predictDisease(imageFile);

      if (!mounted) return;

      if (result == null) {
        _showMessageDialog(
          title: 'Unable to Analyze',
          message:
              'The image could not be analyzed. Please try again.',
          icon: Icons.wifi_off,
          iconColor: Colors.red,
        );
        return;
      }

      final diseaseName =
          result['disease']?.toString() ?? 'Unknown Result';

      final confidenceValue = result['confidence'];
      final confidence = confidenceValue is num
          ? confidenceValue.toDouble()
          : double.tryParse(confidenceValue.toString()) ?? 0.0;

      if (diseaseName.toLowerCase() == 'not_squash_leaf') {
        _showMessageDialog(
          title: 'Not a Squash Leaf',
          message:
              'The uploaded image is not recognized as a squash leaf. Please try another image.',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange,
        );
        return;
      }

      if (confidence < confidenceThreshold) {
        _showLowConfidenceDialog(
          imageFile: imageFile,
          disease: diseaseName,
          confidence: confidence,
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            disease: _createDisease(diseaseName),
            confidence: confidence,
            scannedImage: imageFile,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showMessageDialog(
        title: 'Analysis Error',
        message: 'Something went wrong while analyzing the image.\n\n$error',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _takePhotoOrAnalyzeGallery() async {
    if (_isAnalyzing) return;

    if (_capturedImage != null) {
      await _analyzeImage(_capturedImage!);
      return;
    }

    try {
      if (_controller == null || !_controller!.value.isInitialized) return;

      final image = await _controller!.takePicture();
      final imageFile = File(image.path);

      if (!mounted) return;
      setState(() => _capturedImage = imageFile);

      await _analyzeImage(imageFile);
    } catch (_) {
      if (!mounted) return;

      _showMessageDialog(
        title: 'Camera Error',
        message: 'Unable to capture the image.',
        icon: Icons.camera_alt_outlined,
        iconColor: Colors.red,
      );
    }
  }

  void _retakePhoto() {
    setState(() => _capturedImage = null);
  }

  void _showLowConfidenceDialog({
    required File imageFile,
    required String disease,
    required double confidence,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Low Confidence'),
        content: Text(
          'The system is not confident about this result.\n\n'
          'System Prediction: $disease\n'
          'Confidence: ${confidence.toStringAsFixed(2)}%\n\n'
          'Would you like to send it to an agriculturist for verification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _submitForExpertReview(
                imageFile: imageFile,
                aiPrediction: disease,
                confidence: confidence,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF179E43),
            ),
            child: const Text(
              'Send for Review',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForExpertReview({
    required File imageFile,
    required String aiPrediction,
    required double confidence,
  }) async {
    if (_isSubmittingReview) return;

    final farmerNameController = TextEditingController();
    final municipalityController = TextEditingController();
    final contactController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Farmer Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: farmerNameController,
                decoration: const InputDecoration(labelText: 'Farmer Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: municipalityController,
                decoration: const InputDecoration(labelText: 'Municipality'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Number'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final valid = farmerNameController.text.trim().isNotEmpty &&
                  municipalityController.text.trim().isNotEmpty &&
                  contactController.text.trim().isNotEmpty;

              if (valid) Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF179E43),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) {
      farmerNameController.dispose();
      municipalityController.dispose();
      contactController.dispose();
      return;
    }

    setState(() => _isSubmittingReview = true);

    try {
      await ExpertReviewService.submitReview(
        imageFile: imageFile,
        aiPrediction: aiPrediction,
        confidence: confidence,
        farmerName: farmerNameController.text.trim(),
        municipality: municipalityController.text.trim(),
        contactNumber: contactController.text.trim(),
      );

      if (!mounted) return;

      _showMessageDialog(
        title: 'Submitted for Review',
        message:
            'The image was sent to an agriculturist for expert verification.',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessageDialog(
        title: 'Submission Failed',
        message: 'Unable to send the image for expert review.\n\n$error',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    } finally {
      farmerNameController.dispose();
      municipalityController.dispose();
      contactController.dispose();

      if (mounted) {
        setState(() => _isSubmittingReview = false);
      }
    }
  }

  void _showMessageDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 45),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildPreview() {
    if (_capturedImage != null) {
      return Positioned.fill(
        child: Image.file(
          _capturedImage!,
          fit: BoxFit.cover,
        ),
      );
    }

    return Positioned.fill(child: CameraPreview(_controller!));
  }

  @override
  Widget build(BuildContext context) {
    final hasFrozenImage = _capturedImage != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError
          ? const Center(
              child: Text(
                'Camera not available',
                style: TextStyle(color: Colors.white),
              ),
            )
          : !_isReady
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF179E43),
                  ),
                )
              : Stack(
                  children: [
                    _buildPreview(),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: const EdgeInsets.only(
                            left: 8,
                            top: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.48),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Back',
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 70,
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          Text(
                            widget.galleryImage != null
                                ? 'Uploaded Leaf'
                                : hasFrozenImage
                                    ? 'Captured Leaf'
                                    : 'Scan Leaf',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black87,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasFrozenImage
                                ? 'Analyze this image or take another photo'
                                : 'Keep one squash leaf clear and centered',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black87,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isAnalyzing || _isSubmittingReview)
                      Positioned(
                        top: 145,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF179E43),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _isSubmittingReview
                                      ? 'Submitting for review...'
                                      : 'Analyzing squash leaf...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasFrozenImage && widget.galleryImage == null)
                            GestureDetector(
                              onTap: _retakePhoto,
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF179E43),
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: Color(0xFF179E43),
                                  size: 30,
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: _isAnalyzing
                                ? null
                                : _takePhotoOrAnalyzeGallery,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                color: const Color(0xFF179E43),
                              ),
                              child: Icon(
                                hasFrozenImage
                                    ? Icons.search
                                    : Icons.camera_alt,
                                color: Colors.white,
                                size: 31,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
