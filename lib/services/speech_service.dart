import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/sound_effect.dart';
import 'text_matcher.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListeningExplicitly = false;
  Function(String words)? _onResultCallback;
  Function(String status)? onStatusChange;
  Function(String error)? onErrorOccurred;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (errorNotification) {
          debugPrint(
              'Erro Speech: ${errorNotification.errorMsg} (permanent: ${errorNotification.permanent})');
          onErrorOccurred?.call(errorNotification.errorMsg);
          if (_isListeningExplicitly && !errorNotification.permanent) {
            _restartListening();
          }
        },
        onStatus: (status) {
          debugPrint('Status Speech: $status');
          onStatusChange?.call(status);
          if (_isListeningExplicitly &&
              (status == 'notListening' || status == 'done')) {
            _restartListening();
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('Falha ao inicializar speech_to_text: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<bool> startListening({
    required Function(String words) onResult,
  }) async {
    _onResultCallback = onResult;
    _isListeningExplicitly = true;

    if (!_isAvailable) {
      bool ready = await initialize();
      if (!ready) {
        _isListeningExplicitly = false;
        return false;
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          localeId: 'pt_BR',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao iniciar speech listening: $e');
      _isListeningExplicitly = false;
      return false;
    }
  }

  void _restartListening() {
    if (!_isListeningExplicitly || _onResultCallback == null) return;
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (_isListeningExplicitly && !_speech.isListening) {
        try {
          await _speech.listen(
            onResult: (result) {
              if (result.recognizedWords.isNotEmpty) {
                _onResultCallback?.call(result.recognizedWords);
              }
            },
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation,
              partialResults: true,
              cancelOnError: false,
              localeId: 'pt_BR',
            ),
          );
        } catch (e) {
          debugPrint('Erro ao reiniciar listening: $e');
        }
      }
    });
  }

  Future<void> stopListening() async {
    _isListeningExplicitly = false;
    _onResultCallback = null;
    await _speech.stop();
  }

  /// Verifica palavras-chave com normalização de acentos e sinônimos via TextMatcher
  SoundEffect? checkKeywords(String text, List<SoundEffect> effects) {
    for (var effect in effects) {
      if (effect.isAmbient) {
        continue; // Sons de ambiente não disparam pontualmente por palavra
      }
      if (TextMatcher.matches(text, effect.keywords)) {
        return effect;
      }
    }
    return null;
  }
}
