import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/sound_effect.dart';

class AudioService {
  final Map<String, AudioPlayer> _activePlayers = {};
  final Map<String, DateTime> _lastPlayedTimes = {};

  // Player dedicado para música e ambiência de fundo (loop contínuo)
  final AudioPlayer _ambientPlayer = AudioPlayer();
  SoundEffect? _currentAmbient;
  bool _isAmbientPlaying = false;
  double _ambientVolume = 0.4;

  bool mixSounds = true;

  SoundEffect? get currentAmbient => _currentAmbient;
  bool get isAmbientPlaying => _isAmbientPlaying;
  double get ambientVolume => _ambientVolume;

  Source _createSource(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return UrlSource(path);
    } else if (path.startsWith('/') ||
        path.contains('custom_audios') ||
        path.contains('temp_rec')) {
      return DeviceFileSource(path);
    } else {
      // Remove prefixo caso já contenha audio/
      final cleanPath =
          path.startsWith('audio/') ? path.replaceFirst('audio/', '') : path;
      return AssetSource('audio/$cleanPath');
    }
  }

  /// Toca um efeito sonoro (com cooldown, volume individual e suporte a sobreposição)
  Future<bool> playSoundEffect(SoundEffect effect) async {
    final now = DateTime.now();
    final lastTime = _lastPlayedTimes[effect.id];

    if (lastTime != null &&
        now.difference(lastTime).inSeconds < effect.cooldownSeconds) {
      return false; // Ainda está em cooldown
    }

    _lastPlayedTimes[effect.id] = now;

    if (!mixSounds) {
      await stopAllEffects();
    }

    try {
      AudioPlayer player = _activePlayers[effect.id] ?? AudioPlayer();
      _activePlayers[effect.id] = player;

      await player.stop();
      await player.setVolume(effect.volume.clamp(0.0, 1.0));
      await player.play(_createSource(effect.audioFile));
      return true;
    } catch (e) {
      debugPrint('Erro ao reproduzir efeito sonoro ${effect.id}: $e');
      return false;
    }
  }

  /// Inicia ou altera a música/som ambiente de fundo em loop
  Future<bool> playAmbient(SoundEffect ambientSound) async {
    try {
      if (_currentAmbient?.id == ambientSound.id && _isAmbientPlaying) {
        return true;
      }

      await _ambientPlayer.stop();
      _currentAmbient = ambientSound;

      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(_ambientVolume.clamp(0.0, 1.0));
      await _ambientPlayer.play(_createSource(ambientSound.audioFile));

      _isAmbientPlaying = true;
      return true;
    } catch (e) {
      debugPrint('Erro ao iniciar áudio ambiente: $e');
      _isAmbientPlaying = false;
      return false;
    }
  }

  /// Pausa ou retoma o áudio ambiente
  Future<void> toggleAmbient() async {
    if (_isAmbientPlaying) {
      await _ambientPlayer.pause();
      _isAmbientPlaying = false;
    } else if (_currentAmbient != null) {
      await _ambientPlayer.resume();
      _isAmbientPlaying = true;
    }
  }

  /// Para o som ambiente
  Future<void> stopAmbient() async {
    await _ambientPlayer.stop();
    _isAmbientPlaying = false;
    _currentAmbient = null;
  }

  /// Ajusta o volume do áudio ambiente
  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume.clamp(0.0, 1.0);
    if (_isAmbientPlaying) {
      await _ambientPlayer.setVolume(_ambientVolume);
    }
  }

  /// Para apenas o áudio de um efeito específico
  Future<void> stopSound(String effectId) async {
    final player = _activePlayers[effectId];
    if (player != null) {
      await player.stop();
    }
  }

  /// Para todos os efeitos pontuais (mantém o som ambiente ativo)
  Future<void> stopAllEffects() async {
    for (var player in _activePlayers.values) {
      await player.stop();
    }
  }

  /// Para tudo (efeitos e som ambiente)
  Future<void> stopAllSounds({bool stopAmbientToo = true}) async {
    await stopAllEffects();
    if (stopAmbientToo) {
      await stopAmbient();
    }
  }

  void dispose() {
    for (var player in _activePlayers.values) {
      player.dispose();
    }
    _activePlayers.clear();
    _ambientPlayer.dispose();
  }
}
