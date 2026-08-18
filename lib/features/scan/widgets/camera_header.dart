import 'package:flutter/material.dart';

class CameraHeader extends StatelessWidget {
  final bool hasFrozenImage;
  final bool fromGallery;

  const CameraHeader({
    super.key,
    required this.hasFrozenImage,
    required this.fromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 70,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Text(
            fromGallery
                ? 'Uploaded Leaf'
                : hasFrozenImage
                    ? 'Captured Leaf'
                    : 'Scan Leaf',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black54,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFrozenImage
                ? 'Tap analyze or retake'
                : 'Capture a clear squash leaf image',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black54,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}