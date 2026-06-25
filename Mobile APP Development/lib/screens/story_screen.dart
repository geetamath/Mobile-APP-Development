import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/story_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/buddy_character.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/quiz_widget.dart';
import '../widgets/story_card.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyProvider);
    final notifier = ref.read(storyProvider.notifier);
    final quizAsync = ref.watch(quizProvider);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  BuddyCharacter(mood: state.buddyMood),
                  const SizedBox(height: 8),
                  _buildBuddyLabel(state),
                  const SizedBox(height: 24),
                  StoryCard(
                    storyText: StoryNotifier.kStoryText,
                    phase: state.storyPhase,
                  ),
                  const SizedBox(height: 16),
                  if (state.errorMessage != null)
                    _buildErrorBanner(state.errorMessage!, notifier),
                  const SizedBox(height: 8),
                  _buildActionButton(state, notifier),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: state.quizVisible
                        ? quizAsync.when(
                            data: (question) => QuizWidget(
                              key: const ValueKey('quiz'),
                              question: question,
                            ),
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, __) => const SizedBox.shrink(
                              key: ValueKey('quiz-error'),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-quiz')),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          ConfettiOverlay(isActive: state.isCorrect),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F0FF),
            Color(0xFFFFF8F0),
            Color(0xFFF0FFF4),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _buildDecoCircle(160, AppColors.primaryLight.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _buildDecoCircle(200, AppColors.secondary.withOpacity(0.07)),
          ),
          Positioned(
            top: 200,
            left: -30,
            child: _buildDecoCircle(100, AppColors.pinkAccent.withOpacity(0.06)),
          ),
        ],
      ),
    );
  }

  Widget _buildDecoCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✨', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'Peblo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.headphones_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildBuddyLabel(StoryState state) {
    String label;
    switch (state.buddyMood) {
      case BuddyMood.happy:
        label = "Pip is so happy for you! 🎉";
        break;
      case BuddyMood.excited:
        label = "Pip is reading the story! 📖";
        break;
      default:
        label = "Hi! I'm Pip, your Story Buddy!";
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        label,
        key: ValueKey(label),
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMedium,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorBanner(String message, StoryNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: notifier.dismissError,
            child: const Icon(Icons.close, color: AppColors.accent, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(StoryState state, StoryNotifier notifier) {
    final bool isLoading = state.storyPhase == StoryPhase.loading;
    final bool isPlaying = state.storyPhase == StoryPhase.playing;
    final bool isDone = state.storyPhase == StoryPhase.complete;

    String label;
    IconData icon;
    Color color;

    if (isDone) {
      label = 'Story Complete! ✓';
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
    } else if (isPlaying) {
      label = 'Listening...';
      icon = Icons.volume_up_rounded;
      color = AppColors.primary;
    } else if (isLoading) {
      label = 'Preparing...';
      icon = Icons.hourglass_top_rounded;
      color = AppColors.secondary;
    } else {
      label = 'Read Me a Story!';
      icon = Icons.play_circle_filled_rounded;
      color = AppColors.primary;
    }

    return GestureDetector(
      onTap: (isPlaying || isLoading || isDone) ? null : notifier.readStory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDone
                ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                : isPlaying || isLoading
                    ? [color.withOpacity(0.7), color.withOpacity(0.5)]
                    : [color, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
