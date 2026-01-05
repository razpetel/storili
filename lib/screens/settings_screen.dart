import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Reset Story Progress'),
            subtitle: const Text('Start all stories fresh'),
            onTap: () {
              // TODO: Show confirmation dialog
            },
          ),
          // Debug section (only in debug builds)
          if (kDebugMode) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Debug',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.celebration, color: Colors.orange),
              title: const Text('Test Celebration'),
              subtitle: const Text('5 test images, real TTS'),
              onTap: () => context.go('/debug/celebration'),
            ),
            ListTile(
              leading: const Icon(Icons.celebration_outlined, color: Colors.grey),
              title: const Text('Test Celebration (Mock)'),
              subtitle: const Text('5 test images, silent fallback'),
              onTap: () => context.go('/debug/celebration?mock=true'),
            ),
          ],
        ],
      ),
    );
  }
}
