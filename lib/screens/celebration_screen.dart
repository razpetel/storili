import 'package:flutter/material.dart';

class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({
    super.key,
    required this.storyId,
    required this.summary,
  });

  final String storyId;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Congratulations',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('You completed $storyId!'),
            const SizedBox(height: 8),
            Text('Summary: ${summary.substring(0, summary.length.clamp(0, 50))}...'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate home
              },
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}
