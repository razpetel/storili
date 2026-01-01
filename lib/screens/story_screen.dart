import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/story_provider.dart';
import '../widgets/scene_image.dart';
import '../services/image_cache.dart' as image_cache;
import '../providers/services.dart';

class StoryScreen extends ConsumerWidget {
  final String storyId;

  const StoryScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyProvider(storyId));
    final notifier = ref.read(storyProvider(storyId).notifier);
    final imageCache = ref.watch(imageCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Story: $storyId'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showEndDialog(context, notifier),
        ),
      ),
      body: _buildBody(context, state, notifier, imageCache),
    );
  }

  Widget _buildBody(BuildContext context, StoryState state, StoryNotifier notifier, image_cache.ImageCache imageCache) {
    switch (state.sessionStatus) {
      case StorySessionStatus.idle:
        return _buildIdleState(notifier);
      case StorySessionStatus.loading:
        return _buildLoadingState();
      case StorySessionStatus.active:
        return _buildActiveState(context, state, notifier, imageCache);
      case StorySessionStatus.ending:
        return _buildLoadingState(message: 'Ending story...');
      case StorySessionStatus.ended:
        return _buildEndedState();
      case StorySessionStatus.error:
        return _buildErrorState(state, notifier);
    }
  }

  Widget _buildIdleState(StoryNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ready to start your adventure?',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => notifier.startStory(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Story'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState({String message = 'Getting ready...'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildActiveState(BuildContext context, StoryState state, StoryNotifier notifier, image_cache.ImageCache imageCache) {
    final imageBytes = state.currentImageIndex != null
        ? imageCache.get(state.currentImageIndex!)
        : null;

    return Column(
      children: [
        // Scene image (use Flexible to allow it to shrink)
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SceneImage(
              imageBytes: imageBytes,
              isLoading: state.isImageLoading,
            ),
          ),
        ),

        // Speaking indicator
        if (state.isAgentSpeaking)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volume_up, color: Colors.blue),
                SizedBox(width: 8),
                Text('Capy is talking...'),
              ],
            ),
          ),

        // Action cards
        if (state.suggestedActions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: state.suggestedActions.map((action) {
                return ActionCard(
                  action: action,
                  onTap: () => notifier.selectAction(action),
                  opacity: state.isAgentSpeaking ? 0.5 : 1.0,
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEndedState() {
    return const Center(
      child: Text(
        'Story complete!',
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildErrorState(StoryState state, StoryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => notifier.startStory(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndDialog(BuildContext context, StoryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Story?'),
        content: const Text('Are you sure you want to end the story early?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              notifier.endStory();
              context.go('/'); // Navigate to home
            },
            child: const Text('End Now'),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String action;
  final VoidCallback onTap;
  final double opacity;

  const ActionCard({
    super.key,
    required this.action,
    required this.onTap,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: opacity == 1.0 ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text(
              action,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
