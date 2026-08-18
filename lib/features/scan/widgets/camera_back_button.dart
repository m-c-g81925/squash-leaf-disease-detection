import 'package:flutter/material.dart';

class CameraBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CameraBackButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}