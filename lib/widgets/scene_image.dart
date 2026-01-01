import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Displays a scene image with Ken Burns animation and crossfade transitions.
class SceneImage extends StatefulWidget {
  final Uint8List? imageBytes;
  final bool isLoading;

  const SceneImage({
    super.key,
    required this.imageBytes,
    required this.isLoading,
  });

  @override
  State<SceneImage> createState() => _SceneImageState();
}

class _SceneImageState extends State<SceneImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // 5% zoom
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.imageBytes != null) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SceneImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.imageBytes != oldWidget.imageBytes) {
      if (widget.imageBytes != null) {
        _controller.forward(from: 0);
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Container(
        key: const ValueKey('loading'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown.shade100,
              Colors.brown.shade200,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.imageBytes == null) {
      return Container(
        key: const ValueKey('placeholder'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown.shade100,
              Colors.brown.shade200,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_stories,
            size: 64,
            color: Colors.brown,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      key: ValueKey(widget.imageBytes.hashCode),
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Image.memory(
        widget.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
