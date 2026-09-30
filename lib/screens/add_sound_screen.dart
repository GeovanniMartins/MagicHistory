import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sound_effect.dart';

class AddSoundScreen extends StatefulWidget {
  const AddSoundScreen({Key? key}) : super(key: key);

  @override
  State<AddSoundScreen> createState() => _AddSoundScreenState();
}

class _AddSoundScreenState extends State<AddSoundScreen> {
  final _idController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _cooldownController = TextEditingController(text: '3');

  File? _selectedFile;
  String? _fileName;

  static const Color bgColor = Color(0xFF131429);
  static const Color cardColor = Color(0xFF20223D);
  static const Color cardLightColor = Color(0xFF2C2E4E);
  static const Color accentCyan = Color(0xFF38C3FF);
  static const Color accentPink = Color(0xFFFF5EA1);
  static const Color accentPurple = Color(0xFF8C62FF);

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveCustomSound() async {
    if (_idController.text.trim().isEmpty ||
        _keywordsController.text.trim().isEmpty ||
        _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Preencha o nome, as palavras-chave e selecione um áudio.'),
          backgroundColor: accentPink,
        ),
      );
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final customAudioDir = Directory('${appDir.path}/custom_audios');

      if (!await customAudioDir.exists()) {
        await customAudioDir.create(recursive: true);
      }

      final savedFileName = '${_idController.text.trim().toLowerCase()}.mp3';
      final savedFile =
          await _selectedFile!.copy('${customAudioDir.path}/$savedFileName');

      final newEffect = SoundEffect(
        id: _idController.text.trim().toLowerCase(),
        keywords: _keywordsController.text
            .split(',')
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList(),
        audioFile: savedFile.path,
        cooldownSeconds: int.tryParse(_cooldownController.text) ?? 3,
      );

      Navigator.pop(context, newEffect);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar áudio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor:
            Colors.white, // Define a cor do texto do título como branco
        iconTheme: const IconThemeData(
            color: Colors.white), // Define o ícone de voltar como branco
        title: const Text(
          'Novo Efeito Sonoro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nome do Efeito (Ex: Assobio)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Digite o nome...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Palavras-chave (Separadas por vírgula)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _keywordsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'assobio, assobiou, assobiando',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tempo de Pausa / Cooldown (segundos)',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cooldownController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickAudioFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardLightColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentCyan.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audio_file_rounded,
                          color: accentCyan, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fileName ?? 'Selecionar arquivo de áudio (.mp3)',
                          style: TextStyle(
                            color:
                                _fileName != null ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveCustomSound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Salvar Efeito',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
