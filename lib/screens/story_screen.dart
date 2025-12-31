import 'package:flutter/material.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // TODO: Show exit confirmation
          },
        ),
      ),
      body: Center(
        child: Text(storyId),
      ),
    );
  }
}
