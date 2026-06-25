import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AnswerOptionButton extends StatefulWidget {
  final String option;
  final bool isCorrect;
  final bool isWrong;
  final bool isDisabled;
  final VoidCallback onTap;

  const AnswerOptionButton({
    super.key,
    required this.option,
    required this.isCorrect,
    required this.isWrong,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<AnswerOptionButton> createState() => AnswerOptionButtonState();
}

class AnswerOptionButtonState extends State<AnswerOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  void triggerShake() {
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.isCorrect) return AppColors.success;
    if (widget.isWrong) return AppColors.accent;
    return Colors.white;
  }

  Color get _borderColor {
    if (widget.isCorrect) return AppColors.success;
    if (widget.isWrong) return AppColors.accent;
    return AppColors.primary.withOpacity(0.2);
  }

  Color get _textColor {
    if (widget.isCorrect || widget.isWrong) return Colors.white;
    return AppColors.textDark;
  }

  IconData? get _trailingIcon {
    if (widget.isCorrect) return Icons.check_circle_rounded;
    if (widget.isWrong) return Icons.cancel_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: _borderColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ),
              if (_trailingIcon != null)
                Icon(_trailingIcon, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
