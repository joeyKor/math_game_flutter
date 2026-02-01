import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

class AvatarDisplay extends StatefulWidget {
  final String avatar;
  final double size;
  final Color? color;

  const AvatarDisplay({
    super.key,
    required this.avatar,
    this.size = 24,
    this.color,
  });

  @override
  State<AvatarDisplay> createState() => _AvatarDisplayState();
}

class _AvatarDisplayState extends State<AvatarDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isAsset =>
      widget.avatar.contains('/') || widget.avatar.contains('.');

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final auraColor = user.highestAchievementColor;
    final isAuraEnabled = user.isAuraEnabled;

    Widget avatarWidget;
    if (_isAsset) {
      avatarWidget = Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          widget.avatar,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.account_circle,
              size: widget.size,
              color: widget.color ?? Colors.white.withOpacity(0.5),
            );
          },
        ),
      );
    } else {
      avatarWidget = Text(
        widget.avatar,
        style: TextStyle(fontSize: widget.size),
      );
    }

    if (!isAuraEnabled || auraColor == Colors.transparent) {
      return avatarWidget;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: auraColor.withOpacity(0.4 * _pulseAnimation.value),
                blurRadius: 15 * _pulseAnimation.value,
                spreadRadius: 5 * _pulseAnimation.value,
              ),
              BoxShadow(
                color: auraColor.withOpacity(0.2 * _pulseAnimation.value),
                blurRadius: 25 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: avatarWidget,
    );
  }
}
