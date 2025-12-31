import 'package:flutter/material.dart';

class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({super.key, required this.storyId});

  final String storyId;

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
