import 'package:audioplayers/audioplayers.dart';
import '../models/sound_effect.dart';

class AudioService {
  final Map<String, AudioPlayer> _activePlayers = {};
  final Map<String, DateTime> _lastPlayedTimes = {};
  bool mixSounds = false;

  Future<bool> playSoundEffect(SoundEffect effect) async {
    final now = DateTime.now();
    final lastTime = _lastPlayedTimes[effect.id];

    if (lastTime != null &&
        now.difference(lastTime).inSeconds < effect.cooldownSeconds) {
      return false; // Ainda está em cooldown
    }

    _lastPlayedTimes[effect.id] = now;

    if (!mixSounds) {
      await stopAllSounds();
    }

    AudioPlayer player = _activePlayers[effect.id] ?? AudioPlayer();
    _activePlayers[effect.id] = player;

    await player.stop();

    // Se o caminho for absoluto ou de custom_audios, toca como arquivo do dispositivo
    if (effect.audioFile.startsWith('/') ||
        effect.audioFile.contains('custom_audios')) {
      await player.play(DeviceFileSource(effect.audioFile));
    } else {
      await player.play(AssetSource('audio/${effect.audioFile}'));
    }

    return true;
  }

  /// Para apenas o áudio de um efeito específico
  Future<void> stopSound(String effectId) async {
    final player = _activePlayers[effectId];
    if (player != null) {
      await player.stop();
    }
  }

  /// Para todos os áudios que estão sendo reproduzidos
  Future<void> stopAllSounds() async {
    for (var player in _activePlayers.values) {
      await player.stop();
    }
  }

  void dispose() {
    for (var player in _activePlayers.values) {
      player.dispose();
    }
    _activePlayers.clear();
  }
}
