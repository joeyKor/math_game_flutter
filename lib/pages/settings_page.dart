import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/widgets/math_dialog.dart';
import 'package:math/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _controller = TextEditingController(text: user.username);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final color = Theme.of(context).primaryColor;
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [config.gradientStart, config.gradientEnd],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Name',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).cardTheme.color?.withOpacity(0.3),
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.person_rounded, color: accent),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // TTS Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).cardTheme.color?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volume_up_rounded, color: accent),
                            const SizedBox(width: 12),
                            const Text(
                              'English TTS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: context.watch<UserProvider>().isTtsEnabled,
                          onChanged: (val) {
                            context.read<UserProvider>().setTtsEnabled(val);
                          },
                          activeThumbColor: accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Vibration Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).cardTheme.color?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vibration_rounded, color: accent),
                            const SizedBox(width: 12),
                            const Text(
                              'Vibration Feedback',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: context
                              .watch<UserProvider>()
                              .isVibrationEnabled,
                          onChanged: (val) {
                            context.read<UserProvider>().setVibrationEnabled(
                              val,
                            );
                          },
                          activeThumbColor: accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<UserProvider>().updateUsername(
                          _controller.text,
                        );
                        MathDialog.show(
                          context,
                          title: 'PROFILE UPDATED',
                          message: '환영합니다! 이제부터 이 이름으로 불러드릴게요.',
                        );
                        // Removed SnackBar as it's redundant with the dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: GestureDetector(
                      onLongPress: () async {
                        final passController = TextEditingController();
                        final isAuthorized = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: config.gradientEnd,
                            title: const Text(
                              'Master Reset',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Enter reset password to clear all data:',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: passController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: const TextStyle(
                                      color: Colors.white24,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white10,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (passController.text == '9891') {
                                    Navigator.pop(ctx, true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invalid Password'),
                                      ),
                                    );
                                    Navigator.pop(ctx, false);
                                  }
                                },
                                child: const Text(
                                  'Confirm Reset',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isAuthorized == true) {
                          context.read<UserProvider>().resetData();
                          _controller.text = 'Learner';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All data has been reset.'),
                            ),
                          );
                        }
                      },
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Long press to unlock reset option',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          'Reset All Data',
                          style: TextStyle(color: Colors.red.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
