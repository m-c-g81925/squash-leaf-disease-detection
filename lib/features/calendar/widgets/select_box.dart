import 'package:flutter/material.dart';

class SelectBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const SelectBox({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black54,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF179E43),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}