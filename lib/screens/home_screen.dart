import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/sound_effect.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';
import 'add_sound_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechService _speechService = SpeechService();
  final AudioService _audioService = AudioService();

  List<SoundEffect> _effects = [];
  String _wordsSpoken = '';
  String _lastTriggered = '';
  bool _isListening = false;

  static const Color bgColor = Color(0xFF131429);
  static const Color cardColor = Color(0xFF20223D);
  static const Color cardLightColor = Color(0xFF2C2E4E);
  static const Color accentCyan = Color(0xFF38C3FF);
  static const Color accentPink = Color(0xFFFF5EA1);
  static const Color accentPurple = Color(0xFF8C62FF);

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Permission.microphone.request();
    await _loadConfiguration();
    await _speechService.initialize();
  }

  Future<void> _loadConfiguration() async {
    final String response =
        await rootBundle.loadString('assets/config/sounds_config.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _effects = data.map((item) => SoundEffect.fromJson(item)).toList();
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _wordsSpoken = text;
          });
          _evaluateSpeech(text);
        },
      );
    }
  }

  void _evaluateSpeech(String text) async {
    final matchedEffect = _speechService.checkKeywords(text, _effects);
    if (matchedEffect != null) {
      bool played = await _audioService.playSoundEffect(matchedEffect);
      if (played) {
        setState(() {
          _lastTriggered = matchedEffect.id.toUpperCase();
        });
      }
    }
  }

  Future<void> _openAddSoundScreen() async {
    final newEffect = await Navigator.push<SoundEffect>(
      context,
      MaterialPageRoute(builder: (context) => const AddSoundScreen()),
    );

    if (newEffect != null) {
      setState(() {
        _effects.add(newEffect);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Efeito "${newEffect.id}" cadastrado com sucesso!'),
          backgroundColor: accentPurple,
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SoundKid',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            // Substituição do ícone de fone pela imagem customizada
            Image.asset(
              'assets/images/header_icon.png',
              width: 28,
              height: 28,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: accentCyan, size: 30),
            tooltip: 'Adicionar Novo Som',
            onPressed: _openAddSoundScreen,
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined,
                color: accentPink, size: 30),
            tooltip: 'Parar Todos os Sons',
            onPressed: () async {
              await _audioService.stopAllSounds();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todos os sons foram parados.'),
                  duration: Duration(seconds: 1),
                  backgroundColor: cardLightColor,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Mesclar Sons
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardLightColor, width: 1.5),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.layers_rounded, color: accentCyan, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Mesclar Sons',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _audioService.mixSounds,
                      activeColor: accentCyan,
                      activeTrackColor: accentCyan.withOpacity(0.3),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: cardLightColor,
                      onChanged: (val) {
                        setState(() {
                          _audioService.mixSounds = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Área de Texto Capturado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor, cardLightColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.graphic_eq : Icons.mic_none,
                          color: _isListening ? accentPink : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening
                              ? 'Escutando a história...'
                              : 'Microfone Pausado',
                          style: TextStyle(
                            color: _isListening ? accentPink : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _wordsSpoken.isEmpty
                          ? 'Toque no microfone e leia a história...'
                          : '"$_wordsSpoken"',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_lastTriggered.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentPurple, width: 1),
                        ),
                        child: Text(
                          'Efeito ativado: $_lastTriggered',
                          style: const TextStyle(
                            color: accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Efeitos Disponíveis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_effects.length} sons',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Lista de Sons com Imagem Personalizada
              Expanded(
                child: ListView.builder(
                  itemCount: _effects.length,
                  itemBuilder: (context, index) {
                    final effect = _effects[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: cardLightColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentPurple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // Substituição do ícone de som pela imagem nos cartões
                            child: Image.asset(
                              'assets/images/sound_card_icon.png',
                              width: 26,
                              height: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  effect.id.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Palavras: ${effect.keywords.join(", ")}',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause_circle_filled_rounded,
                                color: accentPink, size: 28),
                            tooltip: 'Parar ${effect.id}',
                            onPressed: () async {
                              await _audioService.stopSound(effect.id);
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardLightColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${effect.cooldownSeconds}s',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onTap: _toggleListening,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _isListening
                  ? [accentPink, Colors.redAccent]
                  : [accentCyan, accentPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (_isListening ? accentPink : accentCyan).withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
