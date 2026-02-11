import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  final FlutterTts _flutterTts = FlutterTts();

  factory TtsService() {
    return _instance;
  }

  TtsService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Initial language set
    await _flutterTts.setLanguage("en-US");

    // Web-specific handling: Voices are often loaded asynchronously
    // We try to find a native US voice multiple times if needed
    for (int i = 0; i < 3; i++) {
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null && voices.isNotEmpty) {
          dynamic selectedVoice;

          // Priority 1: Google/Premium US English
          for (var voice in voices) {
            final name = voice["name"].toString().toLowerCase();
            final locale = voice["locale"].toString().toLowerCase();
            if ((locale.contains("en-us") || locale.contains("en_us")) &&
                (name.contains("google") ||
                    name.contains("premium") ||
                    name.contains("natural"))) {
              selectedVoice = voice;
              break;
            }
          }

          // Priority 2: Any Microsoft/Native US English (David, Zira, etc.)
          if (selectedVoice == null) {
            for (var voice in voices) {
              final name = voice["name"].toString().toLowerCase();
              final locale = voice["locale"].toString().toLowerCase();
              if ((locale.contains("en-us") || locale.contains("en_us")) &&
                  (name.contains("microsoft") ||
                      name.contains("david") ||
                      name.contains("zira"))) {
                selectedVoice = voice;
                break;
              }
            }
          }

          // Priority 3: Any en-US voice
          if (selectedVoice == null) {
            for (var voice in voices) {
              final locale = voice["locale"].toString().toLowerCase();
              if (locale.contains("en-us") || locale.contains("en_us")) {
                selectedVoice = voice;
                break;
              }
            }
          }

          if (selectedVoice != null) {
            await _flutterTts.setVoice({
              "name": selectedVoice["name"],
              "locale": selectedVoice["locale"],
            });
            break; // Successfully found a voice
          }
        }
      } catch (e) {
        // Log or handle error silently
      }
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Wait for browser to load voices
    }

    await _flutterTts.setSpeechRate(0.45); // Slightly slower for better clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // Silent error for platform/plugin issues
    }
  }
}
