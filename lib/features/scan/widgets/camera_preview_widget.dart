import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final File? capturedImage;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    if (capturedImage != null) {
      return Positioned.fill(
        child: Image.file(
          capturedImage!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            );
          },
        ),
      );
    }

    if (controller == null ||
        !controller!.value.isInitialized) {
      return const Positioned.fill(
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF179E43),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: CameraPreview(controller!),
    );
  }
}