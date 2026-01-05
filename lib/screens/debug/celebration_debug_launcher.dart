import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/services.dart';
import '../../utils/test_image_generator.dart';

/// Debug launcher that sets up test data and navigates to CelebrationScreen.
///
/// This screen:
/// 1. Generates 5 colored test images
/// 2. Populates the ImageCache
/// 3. Navigates to CelebrationScreen with a test summary
///
/// Used for testing and debugging the celebration flow without
/// completing an actual story.
class CelebrationDebugLauncher extends ConsumerStatefulWidget {
  const CelebrationDebugLauncher({
    super.key,
    this.useMockTts = false,
    this.imageCount = 5,
  });

  /// If true, uses a short summary that triggers silent TTS fallback.
  /// If false, uses full summary for real TTS testing.
  final bool useMockTts;

  /// Number of test images to generate (1-10).
  final int imageCount;

  @override
  ConsumerState<CelebrationDebugLauncher> createState() =>
      _CelebrationDebugLauncherState();
}

class _CelebrationDebugLauncherState
    extends ConsumerState<CelebrationDebugLauncher> {
  String _status = 'Initializing...';
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupAndNavigate();
  }

  Future<void> _setupAndNavigate() async {
    try {
      // Step 1: Clear any existing images
      setState(() {
        _status = 'Clearing cache...';
        _progress = 0.1;
      });

      final imageCache = ref.read(imageCacheProvider);
      imageCache.clear();

      // Step 2: Generate test images
      setState(() {
        _status = 'Generating test images...';
        _progress = 0.2;
      });

      final count = widget.imageCount.clamp(1, 10);
      for (var i = 0; i < count; i++) {
        final color = TestImageGenerator.sceneColors[
            i % TestImageGenerator.sceneColors.length];

        setState(() {
          _status = 'Generating image ${i + 1}/$count...';
          _progress = 0.2 + (0.6 * (i / count));
        });

        final imageBytes = await TestImageGenerator.generateColoredImage(
          color,
          size: 512,
        );
        imageCache.store(i, Uint8List.fromList(imageBytes));
      }

      // Step 3: Prepare summary
      setState(() {
        _status = 'Preparing celebration...';
        _progress = 0.9;
      });

      final summary = widget.useMockTts
          ? CelebrationTestData.shortSummary
          : CelebrationTestData.summary;

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _status = 'Launching celebration!';
        _progress = 1.0;
      });

      // Step 4: Navigate to celebration screen
      if (mounted) {
        context.go(
          '/celebration/${CelebrationTestData.storyId}',
          extra: summary,
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Celebration Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _error != null ? _buildError() : _buildLoading(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Status text
        Text(
          _status,
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Config info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildConfigRow('Images', '${widget.imageCount}'),
              _buildConfigRow(
                'TTS Mode',
                widget.useMockTts ? 'Mock (silent)' : 'Real API',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'Setup Failed',
          style: AppTypography.appTitle,
        ),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _error = null;
              _progress = 0;
            });
            _setupAndNavigate();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
