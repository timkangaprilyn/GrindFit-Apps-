import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceCoach extends ChangeNotifier {
  VoiceCoach._();
  static final instance = VoiceCoach._();
  FlutterTts? _tts;
  bool enabled = false;
  double volume = 0.8;
  String? error;
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('voice-coach') ?? false;
    volume = prefs.getDouble('voice-volume') ?? 0.8;
  }

  Future<void> configure({bool? on, double? loudness}) async {
    enabled = on ?? enabled;
    volume = (loudness ?? volume).clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice-coach', enabled);
    await prefs.setDouble('voice-volume', volume);
    if (!enabled) await stop();
    notifyListeners();
  }

  Future<void> say(String text) async {
    if (!enabled) return;
    try {
      _tts ??= FlutterTts();
      await _tts!.setLanguage('en-PH');
      await _tts!.setVolume(volume);
      await _tts!.setSpeechRate(0.45);
      await _tts!.stop();
      await _tts!.speak(text);
      error = null;
    } catch (_) {
      error = 'Voice is unavailable on this device. The on-screen timer is still active.';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {
      /* A device may have no TTS engine. */
    }
  }
}
