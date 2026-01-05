// lib/screens/celebration_screen.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../app/theme.dart';
import '../providers/celebration_provider.dart';
import '../providers/services.dart';
import '../utils/bytes_audio_source.dart';

/// Phase of the celebration reveal sequence.
enum CelebrationPhase { jingle, slideshow, gallery }

/// Celebration screen shown when a story is completed.
class CelebrationScreen extends ConsumerStatefulWidget {
  const CelebrationScreen({
    super.key,
    required this.storyId,
    required this.summary,
  });

  final String storyId;
  final String summary;

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Phase state
  CelebrationPhase _phase = CelebrationPhase.jingle;
  bool _jingleComplete = false;
  bool _ttsComplete = false;
  Uint8List? _ttsAudioBytes;
  bool _waitingForTts = false;

  // Slideshow state
  int _currentSlide = 0;
  Timer? _slideTimer;
  bool _showSkipButton = false;

  // Controllers
  late ConfettiController _confettiController;
  late AnimationController _kenBurnsController;
  AudioPlayer? _jinglePlayer;
  AudioPlayer? _voicePlayer;

  // Images from cache
  List<Uint8List> _images = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize controllers
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    );

    _kenBurnsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Load images from cache
    final imageCache = ref.read(imageCacheProvider);
    _images = imageCache.getAll();

    // Start celebration
    _startJingle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _jinglePlayer?.pause();
      _voicePlayer?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_phase == CelebrationPhase.jingle) {
        _jinglePlayer?.play();
      } else if (_phase == CelebrationPhase.slideshow) {
        _voicePlayer?.play();
      }
    }
  }

  Future<void> _startJingle() async {
    _confettiController.play();

    // TODO: Play actual jingle when asset is available
    // For now, simulate jingle duration
    await Future.delayed(const Duration(seconds: 2));

    _jingleComplete = true;
    _tryTransition();
  }

  void _onTtsComplete(Uint8List? audioBytes) {
    _ttsComplete = true;
    _ttsAudioBytes = audioBytes;
    _tryTransition();
  }

  void _tryTransition() {
    if (!mounted) return;

    if (!_jingleComplete) return;

    if (!_ttsComplete) {
      setState(() => _waitingForTts = true);
      return;
    }

    if (_phase != CelebrationPhase.jingle) return;

    _transitionToSlideshow();
  }

  Future<void> _transitionToSlideshow() async {
    if (_images.isEmpty) {
      // No images - skip to gallery
      _transitionToGallery();
      return;
    }

    setState(() {
      _phase = CelebrationPhase.slideshow;
      _waitingForTts = false;
    });

    // Calculate slide duration
    Duration slideDuration;
    if (_ttsAudioBytes != null) {
      _voicePlayer = AudioPlayer();
      await _voicePlayer!.setAudioSource(BytesAudioSource(_ttsAudioBytes!));
      final voiceDuration = _voicePlayer!.duration ?? const Duration(seconds: 10);
      slideDuration = Duration(
        milliseconds: (voiceDuration.inMilliseconds / _images.length)
            .clamp(2000, 5000)
            .toInt(),
      );
      _voicePlayer!.play();

      // Listen for voice completion
      _voicePlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_currentSlide >= _images.length - 1) {
            _transitionToGallery();
          }
        }
      });
    } else {
      slideDuration = const Duration(milliseconds: 3500);
    }

    // Start Ken Burns animation
    _kenBurnsController.repeat(reverse: true);

    // Start slide timer
    _startSlideTimer(slideDuration);
  }

  void _startSlideTimer(Duration interval) {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(interval, (timer) {
      if (_currentSlide < _images.length - 1) {
        setState(() => _currentSlide++);
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
        // Check if voice is still playing
        if (_voicePlayer?.playing != true) {
          _transitionToGallery();
        } else {
          setState(() => _showSkipButton = true);
        }
      }
    });
  }

  void _transitionToGallery() {
    _slideTimer?.cancel();
    _voicePlayer?.stop();
    _kenBurnsController.stop();
    _confettiController.stop();

    if (mounted) {
      setState(() => _phase = CelebrationPhase.gallery);
    }
  }

  void _onTapToSkip() {
    if (_phase == CelebrationPhase.slideshow) {
      HapticFeedback.mediumImpact();
      _transitionToGallery();
    }
  }

  void _navigateHome() {
    context.go('/');
  }

  void _playAgain() {
    context.go('/story/${widget.storyId}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _kenBurnsController.dispose();
    _slideTimer?.cancel();
    _jinglePlayer?.dispose();
    _voicePlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for TTS completion
    ref.listen(celebrationTtsProvider(widget.summary), (prev, next) {
      next.whenData(_onTtsComplete);
    });

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          GestureDetector(
            onTap: _phase == CelebrationPhase.slideshow ? _onTapToSkip : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildPhaseContent(),
            ),
          ),

          // Confetti layer
          if (_phase != CelebrationPhase.gallery && !reduceMotion)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [
                  AppColors.accent,
                  AppColors.shadowOuter,
                  AppColors.primary,
                  AppColors.secondary,
                ],
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    return switch (_phase) {
      CelebrationPhase.jingle => _buildJinglePhase(),
      CelebrationPhase.slideshow => _buildSlideshowPhase(),
      CelebrationPhase.gallery => _buildGalleryPhase(),
    };
  }

  Widget _buildJinglePhase() {
    return Center(
      key: const ValueKey('jingle'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Claymorphism card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowOuter,
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              'You did it!',
              style: AppTypography.appTitle.copyWith(fontSize: 32),
            ),
          ),

          // Loading indicator if waiting for TTS
          if (_waitingForTts) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlideshowPhase() {
    if (_images.isEmpty) {
      return const Center(child: Text('No images'));
    }

    return Center(
      key: const ValueKey('slideshow'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with Ken Burns
          AnimatedBuilder(
            animation: _kenBurnsController,
            builder: (context, child) {
              final scale = 1.0 + (_kenBurnsController.value * 0.05);
              return Transform.scale(scale: scale, child: child);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 280,
                height: 280,
                child: Image.memory(
                  _images[_currentSlide],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary,
                    child: const Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Progress dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_images.length, (index) {
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentSlide
                      ? AppColors.accent
                      : AppColors.shadowOuter,
                ),
              );
            }),
          ),

          // Skip button
          if (_showSkipButton) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _transitionToGallery,
              child: const Text('Skip'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryPhase() {
    return SafeArea(
      key: const ValueKey('gallery'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Capy + header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Capy placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'What a\nstory!',
                  style: AppTypography.appTitle.copyWith(fontSize: 28),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Thumbnail gallery
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullScreenViewer(index),
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Spacer(),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _navigateHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home),
                    const SizedBox(width: 8),
                    Text('Home', style: AppTypography.button),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _playAgain,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.secondary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.replay),
                    const SizedBox(width: 8),
                    Text('Play Again', style: AppTypography.button),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openFullScreenViewer(int index) {
    // TODO: Implement full-screen viewer in Task 9
    HapticFeedback.selectionClick();
  }
}
