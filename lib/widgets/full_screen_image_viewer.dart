// lib/widgets/full_screen_image_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

/// Full-screen image viewer with swipe navigation.
class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<Uint8List> images;
  final int initialIndex;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    HapticFeedback.selectionClick();
  }

  void _dismiss() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  double get _dismissScale => (1 - (_dragOffset.abs() / 300)).clamp(0.8, 1.0);
  double get _dismissOpacity => (1 - (_dragOffset.abs() / 200)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final isSingleImage = widget.images.length == 1;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() => _dragOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset.abs() > 100 ||
              details.primaryVelocity!.abs() > 800) {
            _dismiss();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Stack(
          children: [
            // Main image
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                scale: _dismissScale,
                child: Opacity(
                  opacity: _dismissOpacity,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: isSingleImage
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: Hero(
                          tag: index == widget.initialIndex
                              ? 'celebration_image_$index'
                              : 'no_hero_$index',
                          child: Image.memory(
                            widget.images[index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Close button (top-left, always visible)
            Positioned(
              top: padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Thumbnail strip (bottom, multiple images only)
            if (!isSingleImage)
              Positioned(
                bottom: padding.bottom + 16,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.images.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected ? Colors.white : Colors.white38,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                widget.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppColors.primary),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
