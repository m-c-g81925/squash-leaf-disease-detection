import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final EdgeInsetsGeometry padding;

  const LoadingIndicator({
    super.key,
    this.message,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
            if (message != null &&
                message!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}