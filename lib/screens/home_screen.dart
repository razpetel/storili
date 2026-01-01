import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../models/story_info.dart';
import '../widgets/capy_welcome.dart';
import '../widgets/story_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Storili',
          style: AppTypography.appTitle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: AppColors.secondary,
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Capy welcome area
              const Expanded(
                flex: 3,
                child: CapyWelcome(),
              ),
              const SizedBox(height: 24),
              // Story card
              Expanded(
                flex: 5,
                child: StoryCard(
                  story: availableStories.first,
                  onTap: () => context.go('/story/${availableStories.first.id}'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
