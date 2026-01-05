import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/story_info.dart';

/// Claymorphism-styled story card with gradient and layered shadows.
class StoryCard extends StatelessWidget {
  final StoryInfo story;
  final VoidCallback onTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              story.primaryColor,
              story.secondaryColor.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: story.secondaryColor.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            // Outer shadow (claymorphism)
            BoxShadow(
              color: AppColors.shadowOuter.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // Secondary shadow for depth
            BoxShadow(
              color: AppColors.shadowInner.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    story.title,
                    style: AppTypography.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.play_circle_filled,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
