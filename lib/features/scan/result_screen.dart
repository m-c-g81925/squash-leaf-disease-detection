import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/scan_history_service.dart';
import '../../models/disease_model.dart';

class ResultScreen extends StatefulWidget {
  final Disease disease;

  // FastAPI already returns a percentage, such as 98.25.
  final double confidence;
  final File? scannedImage;

  const ResultScreen({
    super.key,
    required this.disease,
    required this.confidence,
    this.scannedImage,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  static const Color _primaryColor = Color(0xFF179E43);

  static const Color _backgroundColor = Color(0xFFF6F7F5);

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return const Color(0xFF68736B);
    }
  }

  Future<void> _saveResult() async {
    if (_isSaving || _isSaved) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ScanHistoryService.saveScan(
        disease: widget.disease.name,
        confidence: widget.confidence,
        severity: widget.disease.severity,
        description: widget.disease.description,
        imagePath: widget.scannedImage?.path ?? '',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      _showMessage(
        'Scan result saved successfully.',
        _primaryColor,
      );

    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to save result: $error',
        Colors.red,
      );
    }
  }

  void _showMessage(
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color severityColor =
        _severityColor(widget.disease.severity);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Scan result',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2923),
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _ResultImage(
                scannedImage: widget.scannedImage,
                assetImagePath: widget.disease.image,
              ),
              const SizedBox(height: 20),
              _ResultInformationCard(
                diseaseName: widget.disease.name,
                confidence: widget.confidence,
                severity: widget.disease.severity,
                severityColor: severityColor,
                description: widget.disease.description,
              ),
              const SizedBox(height: 20),
              _SaveResultButton(
                isSaving: _isSaving,
                isSaved: _isSaved,
                onPressed: _saveResult,
              ),
              const SizedBox(height: 12),
              _ScanAgainButton(
                isDisabled: _isSaving,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultImage extends StatelessWidget {
  final File? scannedImage;
  final String assetImagePath;

  const _ResultImage({
    required this.scannedImage,
    required this.assetImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: scannedImage != null
          ? Image.file(
              scannedImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const _ImagePlaceholder();
              },
            )
          : assetImagePath.isNotEmpty
              ? Image.asset(
                  assetImagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const _ImagePlaceholder();
                  },
                )
              : const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.eco,
        size: 70,
        color: Color(0xFF179E43),
      ),
    );
  }
}

class _ResultInformationCard extends StatelessWidget {
  final String diseaseName;
  final double confidence;
  final String severity;
  final Color severityColor;
  final String description;

  const _ResultInformationCard({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.severityColor,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diseaseName,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Confidence: ${confidence.toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Severity: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                severity,
                style: TextStyle(
                  color: severityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: const Color(0xFF68736B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveResultButton extends StatelessWidget {
  final bool isSaving;
  final bool isSaved;
  final VoidCallback onPressed;

  const _SaveResultButton({
    required this.isSaving,
    required this.isSaved,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSaving || isSaved ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF179E43),
          disabledBackgroundColor: isSaved
              ? Colors.green.shade300
              : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isSaving
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(
                isSaved
                    ? Icons.check_circle
                    : Icons.save_outlined,
                color: Colors.white,
              ),
        label: Text(
          isSaving
              ? 'Saving Result...'
              : isSaved
                  ? 'Result Saved'
                  : 'Save result',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ScanAgainButton extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onPressed;

  const _ScanAgainButton({
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF179E43),
          side: const BorderSide(
            color: Color(0xFF179E43),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.refresh),
        label: const Text(
          'Scan again',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
