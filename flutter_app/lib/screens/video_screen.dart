import 'package:flutter/material.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Video Screen - Sắp ra mắt!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
