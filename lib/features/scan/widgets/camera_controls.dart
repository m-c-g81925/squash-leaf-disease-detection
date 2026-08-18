import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final bool hasFrozenImage;
  final bool fromGallery;
  final bool isAnalyzing;
  final VoidCallback onRetake;
  final VoidCallback onCaptureOrAnalyze;

  const CameraControls({
    super.key,
    required this.hasFrozenImage,
    required this.fromGallery,
    required this.isAnalyzing,
    required this.onRetake,
    required this.onCaptureOrAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasFrozenImage && !fromGallery)
            GestureDetector(
              onTap: isAnalyzing ? null : onRetake,
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
            onTap: isAnalyzing ? null : onCaptureOrAnalyze,
            child: Opacity(
              opacity: isAnalyzing ? 0.6 : 1,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  color: const Color(0xFF179E43),
                ),
                child: Icon(
                  hasFrozenImage
                      ? Icons.search
                      : Icons.camera_alt,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}