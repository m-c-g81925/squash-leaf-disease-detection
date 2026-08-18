import 'package:flutter/material.dart';

class AnalyzingOverlay extends StatelessWidget {
  final bool isAnalyzing;
  final bool isSubmittingReview;

  const AnalyzingOverlay({
    super.key,
    required this.isAnalyzing,
    required this.isSubmittingReview,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAnalyzing && !isSubmittingReview) {
      return const SizedBox.shrink();
    }

    return Positioned(
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
          borderRadius: BorderRadius.circular(16),
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
                isSubmittingReview
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
    );
  }
}