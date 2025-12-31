import 'package:flutter/material.dart';

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
        ],
      ),
    );
  }
}
