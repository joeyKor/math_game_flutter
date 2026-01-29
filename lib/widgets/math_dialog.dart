import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';

class MathDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback? onConfirm;

  const MathDialog({
    super.key,
    required this.title,
    required this.message,
    this.isSuccess = true,
    this.onConfirm,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    bool isSuccess = true,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MathDialog(
        title: title,
        message: message,
        isSuccess: isSuccess,
        onConfirm: onConfirm,
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
            // Icon Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isSuccess ? AppColors.accent : Colors.redAccent)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess
                    ? Icons.auto_awesome_rounded
                    : Icons.error_outline_rounded,
                color: isSuccess ? AppColors.accent : Colors.redAccent,
                size: 40,
              ),
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
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            // Action Button
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
