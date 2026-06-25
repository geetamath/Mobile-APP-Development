import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_model.dart';
import '../providers/story_provider.dart';
import '../theme/app_theme.dart';
import 'answer_option_button.dart';

class QuizWidget extends ConsumerStatefulWidget {
  final QuizQuestion question;

  const QuizWidget({super.key, required this.question});

  @override
  ConsumerState<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends ConsumerState<QuizWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, GlobalKey<AnswerOptionButtonState>> _optionKeys = {};
  int _lastWrongCount = 0;
  String? _lastWrongOption;

  @override
  void initState() {
    super.initState();

    for (final opt in widget.question.options) {
      _optionKeys[opt] = GlobalKey<AnswerOptionButtonState>();
    }

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic));

    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyProvider);
    final notifier = ref.read(storyProvider.notifier);

    if (!state.quizVisible) return const SizedBox.shrink();

    if (state.wrongAttemptCount > _lastWrongCount &&
        state.lastTappedOption != null &&
        state.lastTappedOption != widget.question.answer) {
      _lastWrongCount = state.wrongAttemptCount;
      _lastWrongOption = state.lastTappedOption;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _optionKeys[_lastWrongOption]?.currentState?.triggerShake();
      });
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: state.isCorrect
                  ? AppColors.success
                  : AppColors.primary.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: state.isCorrect
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuizHeader(state.isCorrect),
              const SizedBox(height: 14),
              Text(
                widget.question.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(widget.question.options.length, (index) {
                final option = widget.question.options[index];
                final isCorrect = state.isCorrect &&
                    option == widget.question.answer;
                final isWrong = !state.isCorrect &&
                    state.lastTappedOption == option &&
                    option != widget.question.answer;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnswerOptionButton(
                    key: _optionKeys[option],
                    option: option,
                    isCorrect: isCorrect,
                    isWrong: isWrong,
                    isDisabled: state.isCorrect,
                    onTap: () => notifier.selectOption(
                      option,
                      widget.question.answer,
                    ),
                  ),
                );
              }),
              if (state.isCorrect) ...[
                const SizedBox(height: 8),
                _buildSuccessBanner(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizHeader(bool isCorrect) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCorrect
                ? AppColors.success.withOpacity(0.1)
                : AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.star_rounded : Icons.quiz_rounded,
                size: 14,
                color: isCorrect ? AppColors.success : AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                isCorrect ? 'Brilliant!' : 'Quick Quiz',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppColors.success : AppColors.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${widget.question.options.length} choices',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amazing! You got it right!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  "Pip's gear was Blue — great memory!",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
