import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/sound_effect.dart';
import '../services/supabase_service.dart';

class AddSoundScreen extends StatefulWidget {
  final SoundEffect? soundToEdit;

  const AddSoundScreen({super.key, this.soundToEdit});

  @override
  State<AddSoundScreen> createState() => _AddSoundScreenState();
}

class _AddSoundScreenState extends State<AddSoundScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  final _idController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _cooldownController = TextEditingController(text: '3');

  String _soundType = 'effect'; // 'effect' ou 'ambient'
  double _volume = 1.0;
  String _selectedThemeColor = '#8C62FF';

  File? _selectedAudioFile;
  String? _audioFileName;

  File? _selectedVideoFile;
  String? _videoFileName;

  // Controladores de gravação e áudio
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlayingPreview = false;
  String? _recordedPath;
  bool _isSaving = false;

  static const Color bgColor = Color(0xFF131429);
  static const Color cardColor = Color(0xFF20223D);
  static const Color cardLightColor = Color(0xFF2C2E4E);
  static const Color accentCyan = Color(0xFF38C3FF);
  static const Color accentPink = Color(0xFFFF5EA1);
  static const Color accentPurple = Color(0xFF8C62FF);

  final List<String> _colorOptions = [
    '#8C62FF', // Roxo
    '#38C3FF', // Ciano
    '#FF5EA1', // Rosa
    '#FFB800', // Amarelo/Dourado
    '#00E676', // Verde Esmeralda
    '#FF5722', // Laranja
    '#E91E63', // Carmesim
  ];

  @override
  void initState() {
    super.initState();
    if (widget.soundToEdit != null) {
      final s = widget.soundToEdit!;
      _idController.text = s.name;
      _keywordsController.text = s.keywords.join(', ');
      _cooldownController.text = s.cooldownSeconds.toString();
      _soundType = s.soundType;
      _volume = s.volume;
      _selectedThemeColor = s.themeColor;
      _audioFileName = s.audioFile;
      _videoFileName = s.videoUrl;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _keywordsController.dispose();
    _cooldownController.dispose();
    _audioRecorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return accentPurple;
    }
  }

  // Selecionar arquivo de áudio local
  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAudioFile = File(result.files.single.path!);
        _audioFileName = result.files.single.name;
        _recordedPath = null;
      });
    }
  }

  // Selecionar arquivo de vídeo curto associado
  Future<void> _pickVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'webm', 'mov', 'mkv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideoFile = File(result.files.single.path!);
        _videoFileName = result.files.single.name;
      });
    }
  }

  // Iniciar Gravação de Voz
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/temp_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordedPath = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de microfone não concedida.'),
            backgroundColor: accentPink,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar gravação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Parar Gravação de Voz
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordedPath = path;
          _selectedAudioFile = File(path);
          _audioFileName =
              'Voz gravada (${path.split(Platform.pathSeparator).last})';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao parar gravação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Testar/Tocar a prévia do som gravado
  Future<void> _playPreview() async {
    final path = _recordedPath ?? _selectedAudioFile?.path ?? _audioFileName;
    if (path == null) return;
    try {
      if (_isPlayingPreview) {
        await _previewPlayer.stop();
        setState(() => _isPlayingPreview = false);
      } else {
        Source source;
        if (path.startsWith('http')) {
          source = UrlSource(path);
        } else if (path.startsWith('/') ||
            path.contains('custom_audios') ||
            path.contains('temp_rec')) {
          source = DeviceFileSource(path);
        } else {
          source = AssetSource('audio/$path');
        }

        await _previewPlayer.setVolume(_volume);
        await _previewPlayer.play(source);
        setState(() => _isPlayingPreview = true);
        _previewPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingPreview = false);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reproduzir áudio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Salvar o novo efeito sonoro / música ambiente
  Future<void> _saveCustomSound() async {
    if (_idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, digite o nome do som.'),
            backgroundColor: accentPink),
      );
      return;
    }

    if (_soundType == 'effect' && _keywordsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Informe ao menos uma palavra-chave para o efeito sonoro.'),
            backgroundColor: accentPink),
      );
      return;
    }

    if (_selectedAudioFile == null && _audioFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Grave ou selecione um arquivo de áudio.'),
            backgroundColor: accentPink),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalAudioUrl = _audioFileName ?? '';
      String? finalVideoUrl = _videoFileName;

      // 1. Upload de Áudio se houver novo arquivo selecionado
      if (_selectedAudioFile != null) {
        if (_supabaseService.isConfigured) {
          final uploadedAudio = await _supabaseService.uploadAudio(
              _selectedAudioFile!,
              customName: _idController.text.trim());
          if (uploadedAudio != null) {
            finalAudioUrl = uploadedAudio;
          }
        }

        // Salva cópia local permanente no aplicativo
        if (!finalAudioUrl.startsWith('http')) {
          final appDir = await getApplicationDocumentsDirectory();
          final customAudioDir = Directory('${appDir.path}/custom_audios');
          if (!await customAudioDir.exists()) {
            await customAudioDir.create(recursive: true);
          }
          final ext = _selectedAudioFile!.path.split('.').last;
          final savedFileName =
              '${DateTime.now().millisecondsSinceEpoch}_${_idController.text.trim().replaceAll(' ', '_')}.$ext';
          final savedFile = await _selectedAudioFile!
              .copy('${customAudioDir.path}/$savedFileName');
          finalAudioUrl = savedFile.path;
        }
      }

      // 2. Upload de Vídeo se houver vídeo selecionado
      if (_selectedVideoFile != null) {
        if (_supabaseService.isConfigured) {
          final uploadedVideo = await _supabaseService.uploadVideo(
              _selectedVideoFile!,
              customName: _idController.text.trim());
          if (uploadedVideo != null) {
            finalVideoUrl = uploadedVideo;
          }
        }

        if (finalVideoUrl == null || !finalVideoUrl.startsWith('http')) {
          final appDir = await getApplicationDocumentsDirectory();
          final customVideoDir = Directory('${appDir.path}/custom_videos');
          if (!await customVideoDir.exists()) {
            await customVideoDir.create(recursive: true);
          }
          final ext = _selectedVideoFile!.path.split('.').last;
          final savedFileName =
              'vid_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final savedFile = await _selectedVideoFile!
              .copy('${customVideoDir.path}/$savedFileName');
          finalVideoUrl = savedFile.path;
        }
      }

      final newEffect = SoundEffect(
        id: widget.soundToEdit?.id ??
            'som_${DateTime.now().millisecondsSinceEpoch}',
        name: _idController.text.trim(),
        keywords: _keywordsController.text
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList(),
        audioFile: finalAudioUrl,
        videoUrl: finalVideoUrl,
        cooldownSeconds: int.tryParse(_cooldownController.text) ?? 3,
        isCustom: true,
        soundType: _soundType,
        volume: _volume,
        themeColor: _selectedThemeColor,
      );

      final saved = await _supabaseService.saveSoundEffect(newEffect);

      if (mounted) {
        Navigator.pop(context, saved);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar som: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.soundToEdit == null ? 'Novo Som / Música' : 'Editar Som',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de Som (Efeito Sonoro vs Música Ambiente)
            const Text(
              'Tipo de Áudio:',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        '⚡ Efeito Sonoro\n(Disparo por voz)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    selected: _soundType == 'effect',
                    selectedColor: accentPurple,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                        color: _soundType == 'effect'
                            ? Colors.white
                            : Colors.grey),
                    onSelected: (selected) {
                      if (selected) setState(() => _soundType = 'effect');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Text(
                        '🎵 Música de Fundo\n(Ambiência contínua)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    selected: _soundType == 'ambient',
                    selectedColor: accentCyan,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(
                        color: _soundType == 'ambient'
                            ? const Color(0xFF131429)
                            : Colors.grey),
                    onSelected: (selected) {
                      if (selected) setState(() => _soundType = 'ambient');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Nome do Efeito
            const Text(
              'Nome do Som / Trilha',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _idController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _soundType == 'effect'
                    ? 'Ex: Rugido do Monstro, Espada...'
                    : 'Ex: Chuva na Floresta, Noite Mágica...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 16),

            // Palavras-chave (se for efeito sonoro)
            if (_soundType == 'effect') ...[
              const Text(
                'Palavras-chave e Sinônimos (Separadas por vírgula)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dica: Adicione sinônimos para o mesmo efeito (ex: "dragão, monstro, bicho, rugiu").',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _keywordsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'monstro, rugiu, rugido, bravo, bicho',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Seção de Áudio (Gravar ou Importar)
            const Text(
              'Arquivo de Áudio',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardLightColor),
              ),
              child: Column(
                children: [
                  if (_audioFileName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.audio_file_rounded,
                            color: accentCyan, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _audioFileName!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                              _isPlayingPreview
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: accentPink,
                              size: 30),
                          onPressed: _playPreview,
                        ),
                      ],
                    ),
                    const Divider(color: cardLightColor, height: 24),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                _isRecording ? Colors.red : accentCyan,
                            side: BorderSide(
                                color: _isRecording ? Colors.red : accentCyan),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic_rounded),
                          label:
                              Text(_isRecording ? 'Gravando...' : 'Gravar Voz'),
                          onPressed:
                              _isRecording ? _stopRecording : _startRecording,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: cardLightColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.folder_open_rounded,
                              color: accentPurple),
                          label: const Text('Importar'),
                          onPressed: _pickAudioFile,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Seção de Vídeo Curto / Animação Visual (Opcional)
            const Text(
              'Vídeo Curto / Efeito Visual (Opcional)',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Um vídeo curto (1-3s) que pisca ou toca na tela quando o som é disparado!',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardLightColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.movie_filter_rounded,
                      color: accentPink, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _videoFileName ?? 'Nenhum vídeo selecionado',
                      style: TextStyle(
                        color:
                            _videoFileName != null ? Colors.white : Colors.grey,
                        fontSize: 13,
                        fontWeight: _videoFileName != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_videoFileName != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _selectedVideoFile = null;
                          _videoFileName = null;
                        });
                      },
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardLightColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _pickVideoFile,
                    child: const Text('Escolher Vídeo'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Controle de Volume Individual
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Volume Individual deste Som:',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_volume * 100).toInt()}%',
                  style: const TextStyle(
                      color: accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ],
            ),
            Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: accentCyan,
              inactiveColor: cardLightColor,
              onChanged: (val) {
                setState(() => _volume = val);
              },
            ),

            const SizedBox(height: 16),

            // Seletor de Cor Temática
            const Text(
              'Cor Temática do Efeito:',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _colorOptions.map((hex) {
                final isSelected = _selectedThemeColor == hex;
                final color = _parseColor(hex);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedThemeColor = hex);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),

            if (_soundType == 'effect') ...[
              const SizedBox(height: 20),
              // Cooldown
              const Text(
                'Tempo de Espera (Cooldown em segundos)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cooldownController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '3',
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 6,
                ),
                onPressed: _isSaving ? null : _saveCustomSound,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.soundToEdit == null
                            ? 'Salvar Som / Efeito'
                            : 'Atualizar Som',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
