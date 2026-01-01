import 'package:flutter/material.dart';

/// Metadata for a story available in the app.
class StoryInfo {
  final String id;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;

  const StoryInfo({
    required this.id,
    required this.title,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

/// Available stories in the app.
/// Hardcoded for MVP; will load from manifests later.
const List<StoryInfo> availableStories = [
  StoryInfo(
    id: 'three-little-pigs',
    title: 'The Three Little Pigs',
    primaryColor: Color(0xFFF5E6D3), // Warm cream
    secondaryColor: Color(0xFF8B7355), // Soft brown
  ),
];
