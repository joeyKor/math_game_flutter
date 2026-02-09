import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/widgets/avatar_display.dart';
import 'package:math/services/tts_service.dart';

class MathDialog extends StatefulWidget {
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
  State<MathDialog> createState() => _MathDialogState();
}

class _MathDialogState extends State<MathDialog> {
  @override
  void initState() {
    super.initState();
    _handleTts();
  }

  void _handleTts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      if (user.isTtsEnabled) {
        // Filter out Korean characters to keep the English accent pure
        String text = '${widget.title}. ${widget.message ?? ''}';
        // Regex for Korean characters (Hangul syllables, Jamo, etc.)
        final speakText = text.replaceAll(
          RegExp(
            r'[\u1100-\u11FF\u3130-\u318F\uA960-\uA97F\uAC00-\uD7AF\uD7B0-\uD7FF]',
          ),
          '',
        );

        if (speakText.trim().isNotEmpty) {
          TtsService().speak(speakText);
        }
      }
    });
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
            color: widget.isSuccess
                ? AppColors.accent.withOpacity(0.5)
                : Colors.redAccent.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.isSuccess ? AppColors.accent : Colors.redAccent)
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
                    color:
                        (widget.isSuccess ? AppColors.accent : Colors.redAccent)
                            .withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          (widget.isSuccess
                                  ? AppColors.accent
                                  : Colors.redAccent)
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
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.message != null)
              Consumer<UserProvider>(
                builder: (context, user, child) {
                  final personalizedMessage =
                      '${user.username}님, ${widget.message}';
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
            if (widget.content != null) widget.content!,
            const SizedBox(height: 30),
            // Action Button
            if (widget.showConfirm)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    TtsService().stop();
                    Navigator.pop(context);
                    if (widget.onConfirm != null) widget.onConfirm!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isSuccess
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
