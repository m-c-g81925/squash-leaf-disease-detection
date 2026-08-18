import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF179E43),
        ),
      ),
    );
  }
}