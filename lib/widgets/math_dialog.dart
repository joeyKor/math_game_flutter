import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/widgets/avatar_display.dart';

class MathDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final bool isSuccess;
  final VoidCallback? onConfirm;
  final bool showConfirm;

  const MathDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.isSuccess = true,
    this.onConfirm,
    this.showConfirm = true,
  });

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    bool isSuccess = true,
    VoidCallback? onConfirm,
    bool showConfirm = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MathDialog(
        title: title,
        message: message,
        content: content,
        isSuccess: isSuccess,
        onConfirm: onConfirm,
        showConfirm: showConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSuccess
                ? AppColors.accent.withOpacity(0.5)
                : Colors.redAccent.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSuccess ? AppColors.accent : Colors.redAccent)
                  .withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<UserProvider>(
              builder: (context, user, child) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isSuccess ? AppColors.accent : Colors.redAccent)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isSuccess ? AppColors.accent : Colors.redAccent)
                          .withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: AvatarDisplay(avatar: user.currentAvatar, size: 60),
                );
              },
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (message != null)
              Consumer<UserProvider>(
                builder: (context, user, child) {
                  final personalizedMessage = '${user.username}님, $message';
                  return Text(
                    personalizedMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  );
                },
              ),
            if (content != null) content!,
            const SizedBox(height: 30),
            // Action Button
            if (showConfirm)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onConfirm != null) onConfirm!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess
                        ? AppColors.accent
                        : Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'GOT IT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2,
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
