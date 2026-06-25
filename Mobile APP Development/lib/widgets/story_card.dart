import 'package:flutter/material.dart';
import '../providers/story_provider.dart';
import '../theme/app_theme.dart';

class StoryCard extends StatelessWidget {
  final String storyText;
  final StoryPhase phase;

  const StoryCard({super.key, required this.storyText, required this.phase});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor(),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _borderColor().withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Story Time',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            storyText,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _borderColor() {
    switch (phase) {
      case StoryPhase.playing:
        return AppColors.primary;
      case StoryPhase.complete:
        return AppColors.success;
      default:
        return Colors.transparent;
    }
  }

  Widget _buildStatusChip() {
    switch (phase) {
      case StoryPhase.loading:
        return _StatusChip(
          icon: Icons.hourglass_top_rounded,
          label: 'Preparing...',
          color: AppColors.secondary,
          animated: true,
        );
      case StoryPhase.playing:
        return _StatusChip(
          icon: Icons.volume_up_rounded,
          label: 'Reading...',
          color: AppColors.primary,
          animated: true,
        );
      case StoryPhase.complete:
        return _StatusChip(
          icon: Icons.check_circle_rounded,
          label: 'Done!',
          color: AppColors.success,
          animated: false,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StatusChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool animated;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.animated,
  });

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animated) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, _) {
        return Opacity(
          opacity: widget.animated ? _opacityAnim.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 13, color: widget.color),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
