import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps device speech recognition + text-to-speech so the Atlas chat
/// screen can offer voice input/output. Both run fully on-device via the
/// OS, with no external API and no cost.
class VoiceService {
  VoiceService._internal();
  static final VoiceService instance = VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;

  Future<bool> initSpeech() async {
    if (_speechReady) return true;
    _speechReady = await _speech.initialize();
    return _speechReady;
  }

  Future<void> listen({
    required void Function(String recognizedText) onResult,
    String localeId = 'ar-SA',
  }) async {
    final ready = await initSpeech();
    if (!ready) return;

    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() => _speech.stop();

  bool get isListening => _speech.isListening;

  Future<void> speak(String text) async {
    await _tts.setLanguage('ar-SA');
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }
}
