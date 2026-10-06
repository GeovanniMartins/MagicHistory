import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/sound_effect.dart';
import '../models/story.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';
import '../services/supabase_service.dart';
import '../widgets/visual_effect_overlay.dart';
import '../widgets/helper_mode_view.dart';
import '../widgets/supabase_config_dialog.dart';
import 'add_sound_screen.dart';
import 'story_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final AudioService _audioService = AudioService();
  final SupabaseService _supabaseService = SupabaseService();

  List<SoundEffect> _allEffects = [];
  List<Story> _stories = [];
  Story? _selectedStory; // null significa "Todas as Histórias"

  String _wordsSpoken = '';
  String _lastTriggered = '';
  bool _isListening = false;
  SoundEffect? _currentVisualEffect;

  int _selectedTab =
      0; // 0: Modo Leitura (Microfone), 1: Modo Ajudante (Criança)

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
    await _supabaseService.init();
    await _loadData();
    await _speechService.initialize();
  }

  Future<void> _loadData() async {
    // 1. Carrega efeitos sonoros padrões de assets
    List<SoundEffect> defaultSounds = [];
    try {
      final String response =
          await rootBundle.loadString('assets/config/sounds_config.json');
      final List<dynamic> data = json.decode(response);
      defaultSounds = data.map((item) => SoundEffect.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Aviso ao carregar sounds_config.json: $e');
    }

    // 2. Busca todos os sons via SupabaseService (com fallback local/defaults)
    final fetchedSounds =
        await _supabaseService.getSoundEffects(fallbackDefaults: defaultSounds);
    final fetchedStories = await _supabaseService.getStories();

    setState(() {
      _allEffects = fetchedSounds;
      _stories = fetchedStories;
    });
  }

  /// Retorna os sons filtrados pela história ativa
  List<SoundEffect> get _activeEffects {
    if (_selectedStory == null) {
      return _allEffects;
    }
    return _allEffects
        .where((e) => _selectedStory!.soundIds.contains(e.id))
        .toList();
  }

  /// Sons de efeito pontuais da história ativa
  List<SoundEffect> get _activePointEffects {
    return _activeEffects.where((e) => !e.isAmbient).toList();
  }

  /// Músicas de ambiência / fundo disponíveis
  List<SoundEffect> get _ambientSounds {
    return _allEffects.where((e) => e.isAmbient).toList();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Permissão de microfone necessária para escutar a história.'),
                backgroundColor: accentPink,
              ),
            );
          }
          return;
        }
      }

      setState(() => _isListening = true);
      bool success = await _speechService.startListening(
        onResult: (text) {
          if (mounted) {
            setState(() {
              _wordsSpoken = text;
            });
            _evaluateSpeech(text);
          }
        },
      );

      if (!success && mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Reconhecimento de voz indisponível ou desativado no aparelho.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _evaluateSpeech(String text) async {
    // Avalia apenas dentro dos sons pertencentes à história ativa
    final matchedEffect = _speechService.checkKeywords(text, _activeEffects);
    if (matchedEffect != null) {
      _triggerSoundEffect(matchedEffect);
    }
  }

  /// Executa som + efeito visual (vídeo ou animação)
  void _triggerSoundEffect(SoundEffect effect) async {
    bool played = await _audioService.playSoundEffect(effect);
    if (played && mounted) {
      setState(() {
        _lastTriggered = effect.name.toUpperCase();
        _currentVisualEffect = effect;
      });
    }
  }

  void _onStorySelected(Story? story) {
    setState(() {
      _selectedStory = story;
    });

    // Se a história tiver som ambiente vinculado, toca automaticamente
    if (story?.ambientSoundId != null) {
      final ambSound = _allEffects.firstWhere(
        (e) => e.id == story!.ambientSoundId,
        orElse: () => _allEffects.first,
      );
      if (ambSound.isAmbient) {
        _audioService.playAmbient(ambSound);
      }
    }
  }

  Future<void> _openAddSoundScreen({SoundEffect? soundToEdit}) async {
    final result = await Navigator.push<SoundEffect>(
      context,
      MaterialPageRoute(
          builder: (context) => AddSoundScreen(soundToEdit: soundToEdit)),
    );

    if (result != null) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Som "${result.name}" salvo com sucesso!'),
            backgroundColor: accentPurple,
          ),
        );
      }
    }
  }

  Future<void> _openStoryManager() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryManagerScreen(
          stories: _stories,
          availableSounds: _allEffects,
          onStoriesUpdated: (updated) {
            setState(() {
              _stories = updated;
              if (_selectedStory != null) {
                _selectedStory = _stories.firstWhere(
                  (s) => s.id == _selectedStory!.id,
                  orElse: () => _stories.first,
                );
              }
            });
          },
        ),
      ),
    );
  }

  void _showVolumeDialog(SoundEffect effect) {
    double tempVol = effect.volume;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setVolState) => AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Volume de "${effect.name}"',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(tempVol * 100).toInt()}%',
                  style: const TextStyle(
                      color: accentCyan,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              Slider(
                value: tempVol,
                min: 0.0,
                max: 1.0,
                activeColor: accentCyan,
                onChanged: (v) {
                  setVolState(() => tempVol = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentPurple),
              onPressed: () async {
                final updated = effect.copyWith(volume: tempVol);
                await _supabaseService.saveSoundEffect(updated);
                await _loadData();
                if (mounted) Navigator.pop(ctx);
              },
              child:
                  const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _associateVideoDirectly(SoundEffect effect) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'webm', 'mov'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      String finalVideoUrl = file.path;

      if (_supabaseService.isConfigured) {
        final uploaded =
            await _supabaseService.uploadVideo(file, customName: effect.name);
        if (uploaded != null) finalVideoUrl = uploaded;
      }

      final updated = effect.copyWith(videoUrl: finalVideoUrl);
      await _supabaseService.saveSoundEffect(updated);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Vídeo associado a "${effect.name}"!'),
              backgroundColor: accentPurple),
        );
      }
    }
  }

  void _deleteSoundEffect(SoundEffect effect) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title:
            const Text('Excluir Som?', style: TextStyle(color: Colors.white)),
        content: Text('Deseja remover "${effect.name}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentPink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabaseService.deleteSoundEffect(effect.id);
      await _loadData();
    }
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return accentPurple;
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
                  color: Colors.white),
            ),
            const SizedBox(width: 8),
            Image.asset('assets/images/header_icon.png', width: 28, height: 28),
          ],
        ),
        actions: [
          // Conexão Supabase
          IconButton(
            icon: Icon(
              Icons.cloud_done_rounded,
              color: _supabaseService.isConfigured ? accentCyan : Colors.grey,
              size: 26,
            ),
            tooltip: _supabaseService.isConfigured
                ? 'Supabase Conectado'
                : 'Configurar Supabase',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) =>
                    SupabaseConfigDialog(onConfigured: () => _loadData()),
              );
            },
          ),
          // Botão Adicionar Som
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: accentCyan, size: 28),
            tooltip: 'Adicionar Novo Som',
            onPressed: () => _openAddSoundScreen(),
          ),
          // Parar Todos os Sons
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined,
                color: accentPink, size: 28),
            tooltip: 'Parar Todos os Sons',
            onPressed: () async {
              await _audioService.stopAllSounds();
              setState(() {
                _wordsSpoken = '';
                _lastTriggered = '';
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todos os sons foram parados.'),
                    duration: Duration(seconds: 1),
                    backgroundColor: cardLightColor,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 1. Barra de Seleção de História / Livro (Presets)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories_rounded,
                          color: accentCyan, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Opção "Todas as Histórias"
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: const Text('🌟 Todas as Histórias'),
                                  selected: _selectedStory == null,
                                  selectedColor: accentPurple,
                                  backgroundColor: cardColor,
                                  labelStyle: TextStyle(
                                    color: _selectedStory == null
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                    fontWeight: _selectedStory == null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (_) => _onStorySelected(null),
                                ),
                              ),
                              // Lista de Histórias Criadas
                              ..._stories.map((story) {
                                final isSelected =
                                    _selectedStory?.id == story.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(story.title),
                                    selected: isSelected,
                                    selectedColor: accentPurple,
                                    backgroundColor: cardColor,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (_) => _onStorySelected(story),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded,
                            color: accentCyan, size: 22),
                        tooltip: 'Gerenciar Livros / Histórias',
                        onPressed: _openStoryManager,
                      ),
                    ],
                  ),
                ),

                // 2. Seletor de Modo (Leitura com Voz vs Modo Ajudante da Criança)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? accentPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.mic_rounded,
                                      size: 18,
                                      color: _selectedTab == 0
                                          ? Colors.white
                                          : Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modo Leitura (Voz)',
                                    style: TextStyle(
                                      color: _selectedTab == 0
                                          ? Colors.white
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? accentPink
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.smart_toy_rounded,
                                      size: 18,
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modo Ajudante (Criança)',
                                    style: TextStyle(
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Player de Música Ambiente / Fundo (Se houver som ambiente ativo ou disponível)
                if (_ambientSounds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: accentCyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _audioService.isAmbientPlaying
                                ? Icons.graphic_eq_rounded
                                : Icons.music_note_rounded,
                            color: accentCyan,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _audioService.currentAmbient?.id ??
                                    _ambientSounds.first.id,
                                dropdownColor: cardColor,
                                isDense: true,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                items: _ambientSounds.map((amb) {
                                  return DropdownMenuItem(
                                    value: amb.id,
                                    child: Text('Trilha: ${amb.name}',
                                        overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final sound = _ambientSounds
                                        .firstWhere((e) => e.id == val);
                                    _audioService.playAmbient(sound);
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _audioService.isAmbientPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: accentCyan,
                              size: 28,
                            ),
                            tooltip: _audioService.isAmbientPlaying
                                ? 'Pausar Trilha'
                                : 'Tocar Trilha',
                            onPressed: () async {
                              if (_audioService.currentAmbient == null &&
                                  _ambientSounds.isNotEmpty) {
                                await _audioService
                                    .playAmbient(_ambientSounds.first);
                              } else {
                                await _audioService.toggleAmbient();
                              }
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // 4. Conteúdo Principal baseado no Modo Selecionado
                Expanded(
                  child: _selectedTab == 1
                      ? HelperModeView(
                          effects: _activeEffects,
                          onPlayEffect: (effect) => _triggerSoundEffect(effect),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Área de Reconhecimento de Fala
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cardColor,
                                      cardLightColor.withValues(alpha: 0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isListening
                                              ? Icons.graphic_eq
                                              : Icons.mic_none,
                                          color: _isListening
                                              ? accentPink
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isListening
                                              ? 'Escutando a história...'
                                              : 'Microfone Pausado',
                                          style: TextStyle(
                                            color: _isListening
                                                ? accentPink
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _wordsSpoken.isEmpty
                                          ? 'Toque no microfone e leia a história normalmente...'
                                          : '"$_wordsSpoken"',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_lastTriggered.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accentPurple.withValues(
                                              alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border:
                                              Border.all(color: accentPurple),
                                        ),
                                        child: Text(
                                          'Efeito disparado: $_lastTriggered',
                                          style: const TextStyle(
                                            color: accentCyan,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedStory == null
                                        ? 'Efeitos Disponíveis (${_activePointEffects.length})'
                                        : 'Sons de "${_selectedStory!.title}" (${_activePointEffects.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_allEffects.length} total',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Lista de Sons com 3 Pontinhos e Personalização
                              Expanded(
                                child: _activePointEffects.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Nenhum efeito sonoro cadastrado nesta história.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding:
                                            const EdgeInsets.only(bottom: 90),
                                        itemCount: _activePointEffects.length,
                                        itemBuilder: (context, index) {
                                          final effect =
                                              _activePointEffects[index];
                                          final themeColor =
                                              _parseColor(effect.themeColor);

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: themeColor.withValues(
                                                      alpha: 0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _triggerSoundEffect(
                                                          effect),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          themeColor.withValues(
                                                              alpha: 0.18),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      effect.videoUrl != null
                                                          ? Icons
                                                              .videocam_rounded
                                                          : Icons
                                                              .volume_up_rounded,
                                                      color: themeColor,
                                                      size: 22,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            effect.name
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          if (effect.videoUrl !=
                                                                  null &&
                                                              effect.videoUrl!
                                                                  .isNotEmpty)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: accentPink
                                                                    .withValues(
                                                                        alpha:
                                                                            0.2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                              ),
                                                              child: const Text(
                                                                'VÍDEO',
                                                                style: TextStyle(
                                                                    color:
                                                                        accentPink,
                                                                    fontSize: 9,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Gatilhos: ${effect.keywords.join(", ")}',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade400,
                                                          fontSize: 11,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Botão Play/Testar
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.play_arrow_rounded,
                                                      color: accentCyan,
                                                      size: 26),
                                                  tooltip: 'Tocar Som',
                                                  onPressed: () =>
                                                      _triggerSoundEffect(
                                                          effect),
                                                ),
                                                // Menu de 3 Pontinhos
                                                PopupMenuButton<String>(
                                                  icon: const Icon(
                                                      Icons.more_vert_rounded,
                                                      color: Colors.grey),
                                                  color:
                                                      const Color(0xFF2C2E4E),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14)),
                                                  onSelected: (action) {
                                                    if (action == 'edit') {
                                                      _openAddSoundScreen(
                                                          soundToEdit: effect);
                                                    } else if (action ==
                                                        'video') {
                                                      _associateVideoDirectly(
                                                          effect);
                                                    } else if (action ==
                                                        'volume') {
                                                      _showVolumeDialog(effect);
                                                    } else if (action ==
                                                        'delete') {
                                                      _deleteSoundEffect(
                                                          effect);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'video',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .movie_creation_outlined,
                                                              color: accentPink,
                                                              size: 18),
                                                          SizedBox(width: 10),
                                                          Text(
                                                              'Associar Vídeo Curto',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      13)),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'volume',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .tune_rounded,
                                                              color: accentCyan,
                                                              size: 18),
                                                          SizedBox(width: 10),
                                                          Text('Ajustar Volume',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      13)),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .edit_rounded,
                                                              color: Colors
                                                                  .amberAccent,
                                                              size: 18),
                                                          SizedBox(width: 10),
                                                          Text(
                                                              'Editar Detalhes',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      13)),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .delete_outline_rounded,
                                                              color: Colors
                                                                  .redAccent,
                                                              size: 18),
                                                          SizedBox(width: 10),
                                                          Text('Excluir Som',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .redAccent,
                                                                  fontSize:
                                                                      13)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
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
              ],
            ),
          ),

          // 5. Overlay Visual (Flash / Glow / Vídeo Curto)
          if (_currentVisualEffect != null)
            VisualEffectOverlay(
              effect: _currentVisualEffect!,
              onDismiss: () {
                setState(() => _currentVisualEffect = null);
              },
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedTab == 0
          ? GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [accentPink, Colors.redAccent]
                        : [accentPurple, accentCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? accentPink : accentPurple)
                          .withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            )
          : null,
    );
  }
}
