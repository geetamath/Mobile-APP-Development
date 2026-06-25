import 'package:flutter/material.dart';
import '../providers/story_provider.dart';
import '../theme/app_theme.dart';

class BuddyCharacter extends StatefulWidget {
  final BuddyMood mood;

  const BuddyCharacter({super.key, required this.mood});

  @override
  State<BuddyCharacter> createState() => _BuddyCharacterState();
}

class _BuddyCharacterState extends State<BuddyCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bobController;
  late AnimationController _happyController;
  late Animation<double> _bobAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _happyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _happyController, curve: Curves.easeOut));

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _happyController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(BuddyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == BuddyMood.happy && oldWidget.mood != BuddyMood.happy) {
      _happyController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    _happyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bobController, _happyController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bobAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildRobot(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRobot() {
    final isHappy = widget.mood == BuddyMood.happy;
    final isExcited = widget.mood == BuddyMood.excited;

    return SizedBox(
      width: 140,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildGlow(isHappy, isExcited),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAntenna(isExcited || isHappy),
              _buildHead(isHappy, isExcited),
              const SizedBox(height: 4),
              _buildBody(),
              _buildLegs(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(bool isHappy, bool isExcited) {
    Color glowColor = isHappy
        ? AppColors.success.withOpacity(0.25)
        : isExcited
            ? AppColors.secondary.withOpacity(0.2)
            : AppColors.primaryLight.withOpacity(0.15);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor,
      ),
    );
  }

  Widget _buildAntenna(bool active) {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.textMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Positioned(
            top: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.secondary : AppColors.primaryLight,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHead(bool isHappy, bool isExcited) {
    return Container(
      width: 80,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEye(isHappy, isExcited),
              const SizedBox(width: 16),
              _buildEye(isHappy, isExcited),
            ],
          ),
          const SizedBox(height: 8),
          _buildMouth(isHappy),
        ],
      ),
    );
  }

  Widget _buildEye(bool isHappy, bool isExcited) {
    if (isHappy) {
      return CustomPaint(
        size: const Size(18, 12),
        painter: _HappyEyePainter(),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 18,
      height: isExcited ? 18 : 14,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: AppColors.skyBlue.withOpacity(0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildMouth(bool isHappy) {
    return CustomPaint(
      size: const Size(36, 14),
      painter: _MouthPainter(isHappy: isHappy),
    );
  }

  Widget _buildBody() {
    return Container(
      width: 66,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBodyButton(AppColors.secondary),
          const SizedBox(width: 6),
          _buildBodyButton(AppColors.pinkAccent),
          const SizedBox(width: 6),
          _buildBodyButton(AppColors.success),
        ],
      ),
    );
  }

  Widget _buildBodyButton(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildLegs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLeg(),
        const SizedBox(width: 20),
        _buildLeg(),
      ],
    );
  }

  Widget _buildLeg() {
    return Container(
      width: 14,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
    );
  }
}

class _MouthPainter extends CustomPainter {
  final bool isHappy;
  const _MouthPainter({required this.isHappy});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isHappy) {
      path.moveTo(4, 4);
      path.quadraticBezierTo(size.width / 2, size.height + 4, size.width - 4, 4);
    } else {
      path.moveTo(4, size.height - 4);
      path.quadraticBezierTo(size.width / 2, 2, size.width - 4, size.height - 4);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MouthPainter oldDelegate) => oldDelegate.isHappy != isHappy;
}

class _HappyEyePainter extends CustomPainter {
  const _HappyEyePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width / 2, -size.height / 2, size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
