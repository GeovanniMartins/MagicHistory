import 'package:flutter/material.dart';
import '../models/sound_effect.dart';
import '../models/story.dart';
import '../services/supabase_service.dart';

class StoryManagerScreen extends StatefulWidget {
  final List<Story> stories;
  final List<SoundEffect> availableSounds;
  final Function(List<Story>) onStoriesUpdated;

  const StoryManagerScreen({
    super.key,
    required this.stories,
    required this.availableSounds,
    required this.onStoriesUpdated,
  });

  @override
  State<StoryManagerScreen> createState() => _StoryManagerScreenState();
}

class _StoryManagerScreenState extends State<StoryManagerScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late List<Story> _stories;

  static const Color bgColor = Color(0xFF131429);
  static const Color cardColor = Color(0xFF20223D);
  static const Color cardLightColor = Color(0xFF2C2E4E);
  static const Color accentCyan = Color(0xFF38C3FF);
  static const Color accentPink = Color(0xFFFF5EA1);
  static const Color accentPurple = Color(0xFF8C62FF);

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.stories);
  }

  void _openStoryEditor([Story? storyToEdit]) async {
    final titleController =
        TextEditingController(text: storyToEdit?.title ?? '');
    final descController =
        TextEditingController(text: storyToEdit?.description ?? '');
    String? selectedAmbientId = storyToEdit?.ambientSoundId;
    List<String> selectedSoundIds = List.from(storyToEdit?.soundIds ?? []);

    final ambientSounds =
        widget.availableSounds.where((s) => s.isAmbient).toList();
    final effectSounds =
        widget.availableSounds.where((s) => !s.isAmbient).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        storyToEdit == null
                            ? 'Nova História'
                            : 'Editar História',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Título
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Título da História',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: cardLightColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Descrição
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Descrição (opcional)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: cardLightColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Som de Fundo Ambiente
                  const Text(
                    'Música de Fundo / Ambiência:',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedAmbientId,
                    dropdownColor: cardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardLightColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Nenhum (Sem som ambiente)',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      ...ambientSounds.map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setModalState(() => selectedAmbientId = val),
                  ),
                  const SizedBox(height: 20),

                  // Efeitos vinculados à história
                  const Text(
                    'Efeitos Sonoros Disponíveis na História:',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (effectSounds.isEmpty)
                    const Text('Nenhum efeito sonoro cadastrado.',
                        style: TextStyle(color: Colors.white38))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: effectSounds.map((eff) {
                        final isSelected = selectedSoundIds.contains(eff.id);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(eff.name),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: cardLightColor,
                          selectedColor: accentPurple,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedSoundIds.add(eff.id);
                              } else {
                                selectedSoundIds.remove(eff.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // Botão Salvar
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final navigator = Navigator.of(ctx);

                      final newStory = Story(
                        id: storyToEdit?.id ??
                            'story_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        ambientSoundId: selectedAmbientId,
                        soundIds: selectedSoundIds,
                      );

                      final saved = await _supabaseService.saveStory(newStory);
                      if (mounted) {
                        setState(() {
                          final idx =
                              _stories.indexWhere((s) => s.id == saved.id);
                          if (idx >= 0) {
                            _stories[idx] = saved;
                          } else {
                            _stories.insert(0, saved);
                          }
                        });
                        widget.onStoriesUpdated(_stories);
                        navigator.pop();
                      }
                    },
                    child: const Text('Salvar História',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteStory(Story story) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Excluir História?',
            style: TextStyle(color: Colors.white)),
        content: Text('Deseja excluir "${story.title}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentPink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabaseService.deleteStory(story.id);
      setState(() {
        _stories.removeWhere((s) => s.id == story.id);
      });
      widget.onStoriesUpdated(_stories);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gerenciar Histórias',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _stories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_stories_outlined,
                      size: 64, color: Colors.white30),
                  const SizedBox(height: 12),
                  const Text('Nenhuma história criada ainda!',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Primeira História'),
                    onPressed: () => _openStoryEditor(),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          color: accentCyan),
                    ),
                    title: Text(
                      story.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (story.description != null &&
                            story.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              story.description!,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 13),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentPurple.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${story.soundIds.length} sons vinculados',
                                style: const TextStyle(
                                    color: accentCyan, fontSize: 11),
                              ),
                            ),
                            if (story.ambientSoundId != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.surround_sound,
                                        size: 12, color: Colors.amber),
                                    SizedBox(width: 4),
                                    Text('Ambiente',
                                        style: TextStyle(
                                            color: Colors.amber, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.white70),
                          onPressed: () => _openStoryEditor(story),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: accentPink),
                          onPressed: () => _deleteStory(story),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentCyan,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () => _openStoryEditor(),
      ),
    );
  }
}
