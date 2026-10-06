import 'package:flutter/material.dart';
import '../models/sound_effect.dart';

class HelperModeView extends StatelessWidget {
  final List<SoundEffect> effects;
  final Function(SoundEffect) onPlayEffect;

  const HelperModeView({
    super.key,
    required this.effects,
    required this.onPlayEffect,
  });

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF8C62FF);
    }
  }

  IconData _getIconForSound(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('chuva') ||
        lower.contains('tempestade') ||
        lower.contains('trovao')) {
      return Icons.thunderstorm_rounded;
    } else if (lower.contains('trem') || lower.contains('locomotiva')) {
      return Icons.train_rounded;
    } else if (lower.contains('espada') ||
        lower.contains('duelo') ||
        lower.contains('luta')) {
      return Icons.sports_kabaddi_rounded;
    } else if (lower.contains('monstro') ||
        lower.contains('dragao') ||
        lower.contains('rugido')) {
      return Icons.pets_rounded;
    } else if (lower.contains('vento') || lower.contains('ar')) {
      return Icons.air_rounded;
    } else if (lower.contains('fogo') || lower.contains('fogueira')) {
      return Icons.local_fire_department_rounded;
    } else if (lower.contains('passaro') || lower.contains('ave')) {
      return Icons.flutter_dash_rounded;
    } else if (lower.contains('floresta') || lower.contains('arvore')) {
      return Icons.park_rounded;
    } else if (lower.contains('magia') ||
        lower.contains('feitico') ||
        lower.contains('estrela')) {
      return Icons.auto_awesome_rounded;
    } else if (lower.contains('risada') || lower.contains('gargalhada')) {
      return Icons.sentiment_very_satisfied_rounded;
    } else {
      return Icons.music_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playableEffects = effects.where((e) => !e.isAmbient).toList();

    if (playableEffects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_rounded, size: 64, color: Colors.white30),
            SizedBox(height: 12),
            Text(
              'Nenhum som disponível no momento!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        itemCount: playableEffects.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (context, index) {
          final effect = playableEffects[index];
          final color = _parseColor(effect.themeColor);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onPlayEffect(effect),
              borderRadius: BorderRadius.circular(22),
              splashColor: color.withValues(alpha: 0.4),
              highlightColor: color.withValues(alpha: 0.2),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.35),
                      const Color(0xFF20223D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: color.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForSound(effect.name),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        effect.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
