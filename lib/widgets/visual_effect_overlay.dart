import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/sound_effect.dart';

class VisualEffectOverlay extends StatefulWidget {
  final SoundEffect effect;
  final VoidCallback onDismiss;

  const VisualEffectOverlay({
    super.key,
    required this.effect,
    required this.onDismiss,
  });

  @override
  State<VisualEffectOverlay> createState() => _VisualEffectOverlayState();
}

class _VisualEffectOverlayState extends State<VisualEffectOverlay>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _hasVideo = false;

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFF8C62FF);
    }
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.6, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.15, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.05)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.05, end: 0.8)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
    ]).animate(_animController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_animController);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });

    _initVideoOrAnimation();
  }

  Future<void> _initVideoOrAnimation() async {
    final vUrl = widget.effect.videoUrl;
    if (vUrl != null && vUrl.trim().isNotEmpty) {
      try {
        if (vUrl.startsWith('http://') || vUrl.startsWith('https://')) {
          _videoController = VideoPlayerController.networkUrl(Uri.parse(vUrl));
        } else {
          _videoController = VideoPlayerController.file(File(vUrl));
        }

        await _videoController!.initialize();
        if (mounted) {
          setState(() => _hasVideo = true);
          _videoController!.play();
          _videoController!.addListener(() {
            if (_videoController!.value.position >=
                _videoController!.value.duration) {
              widget.onDismiss();
            }
          });
          return;
        }
      } catch (e) {
        debugPrint('Erro ao reproduzir vídeo do efeito: $e');
      }
    }

    // Se não tiver vídeo ou falhar, roda a animação de pulso/glow
    _animController.forward();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(widget.effect.themeColor);

    if (_hasVideo &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return Positioned.fill(
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            color: Colors.black.withValues(alpha: 0.8),
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                color: themeColor.withValues(
                    alpha: 0.15 * _opacityAnimation.value),
                child: Center(
                  child: Opacity(
                    opacity: _opacityAnimation.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1E2038).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: themeColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.6),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: themeColor,
                                size: 54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.effect.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: themeColor,
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
