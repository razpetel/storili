import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Welcome header featuring Capy the capybara.
/// Placeholder implementation for MVP.
class CapyWelcome extends StatelessWidget {
  const CapyWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Capy placeholder - will be replaced with illustration
          Icon(
            Icons.pets,
            size: 64,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready for a story?',
            style: AppTypography.body.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
