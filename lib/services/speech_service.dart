import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/sound_effect.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (errorNotification) => print('Erro Speech: $errorNotification'),
      onStatus: (status) => print('Status Speech: $status'),
    );
    return _isAvailable;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required Function(String words) onResult,
  }) async {
    if (!_isAvailable) {
      bool ready = await initialize();
      if (!ready) return;
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords.toLowerCase());
      },
      listenFor: const Duration(hours: 1),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      localeId: 'pt_BR',
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  SoundEffect? checkKeywords(String text, List<SoundEffect> effects) {
    for (var effect in effects) {
      for (var keyword in effect.keywords) {
        if (text.contains(keyword.toLowerCase())) {
          return effect;
        }
      }
    }
    return null;
  }
}
