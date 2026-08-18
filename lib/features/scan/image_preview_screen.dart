import 'package:flutter/material.dart';
import 'dart:io';


class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;

  const ImagePreviewScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview")),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}