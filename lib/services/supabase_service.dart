import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sound_effect.dart';
import '../models/story.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Credenciais padrão do Supabase fornecidas
  static const String defaultUrl = 'https://rjrnqhpnlalivrxllzls.supabase.co';
  static const String defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqcm5xaHBubGFsaXZyeGxsemxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA4NzE4ODAsImV4cCI6MjEwNjQ0Nzg4MH0.fuQaYMsLgzT-s4GWsPmEcjFb4cblmflMc8Btw-OTPLU';

  static const String _prefUrlKey = 'supabase_url';
  static const String _prefAnonKey = 'supabase_anon_key';
  static const String _localSoundsCacheKey = 'soundkid_local_sounds';
  static const String _localStoriesCacheKey = 'soundkid_local_stories';

  bool _isInitialized = false;
  String? _currentUrl;
  String? _currentAnonKey;

  bool get isConfigured => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inicializa o cliente Supabase com credenciais salvas ou padrões
  Future<void> init({String? url, String? anonKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetUrl = url ?? prefs.getString(_prefUrlKey) ?? defaultUrl;
      final targetAnonKey =
          anonKey ?? prefs.getString(_prefAnonKey) ?? defaultAnonKey;

      if (targetUrl.trim().isEmpty || targetAnonKey.trim().isEmpty) {
        debugPrint('Supabase: URL ou AnonKey vazios.');
        _isInitialized = false;
        return;
      }

      // Se já estiver inicializado com os mesmos parâmetros
      if (_isInitialized &&
          _currentUrl == targetUrl.trim() &&
          _currentAnonKey == targetAnonKey.trim()) {
        return;
      }

      // Se já foi inicializado anteriormente pelo Supabase.instance
      try {
        if (Supabase.instance.client.rest.headers.isNotEmpty &&
            _currentUrl == targetUrl.trim()) {
          _isInitialized = true;
          return;
        }
      } catch (_) {
        // Ainda não inicializado, prossegue
      }

      await Supabase.initialize(
        url: targetUrl.trim(),
        // ignore: deprecated_member_use
        anonKey: targetAnonKey.trim(),
        debug: kDebugMode,
      );

      _currentUrl = targetUrl.trim();
      _currentAnonKey = targetAnonKey.trim();
      _isInitialized = true;
      debugPrint('Supabase conectado com sucesso em: $targetUrl');
    } catch (e) {
      debugPrint('Aviso ao inicializar Supabase: $e');
      // Se já estava inicializado no Supabase.instance mas deu erro de chamada duplicada
      try {
        if (Supabase.instance.client.rest.headers.isNotEmpty) {
          _isInitialized = true;
          return;
        }
      } catch (_) {}
      _isInitialized = false;
    }
  }

  /// Retorna as credenciais ativas
  Future<Map<String, String>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_prefUrlKey) ?? defaultUrl;
    final anonKey = prefs.getString(_prefAnonKey) ?? defaultAnonKey;
    return {'url': url, 'anonKey': anonKey};
  }

  /// Atualiza as credenciais e reinicializa a conexão
  Future<bool> updateConfig(String url, String anonKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUrlKey, url.trim());
      await prefs.setString(_prefAnonKey, anonKey.trim());

      await init(url: url.trim(), anonKey: anonKey.trim());
      return _isInitialized;
    } catch (e) {
      debugPrint('Erro ao atualizar configurações do Supabase: $e');
      return false;
    }
  }

  /// Restaura as credenciais padrão do projeto
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUrlKey);
    await prefs.remove(_prefAnonKey);
    await init(url: defaultUrl, anonKey: defaultAnonKey);
  }

  // ===========================================================================
  // EFEITOS SONOROS (sound_effects)
  // ===========================================================================

  /// Busca efeitos sonoros da nuvem (com fallback de cache local e sons padrão)
  Future<List<SoundEffect>> getSoundEffects(
      {List<SoundEffect> fallbackDefaults = const []}) async {
    List<SoundEffect> result = [];

    if (_isInitialized && client != null) {
      try {
        final response = await client!
            .from('sound_effects')
            .select()
            .order('created_at', ascending: false);

        final List<dynamic> data = response as List<dynamic>;
        final cloudSounds = data
            .map((json) => SoundEffect.fromJson(json as Map<String, dynamic>))
            .toList();

        if (cloudSounds.isNotEmpty) {
          result = cloudSounds;
          // Atualiza cache local
          await _saveSoundsToLocalCache(result);
        }
      } catch (e) {
        debugPrint('Erro ao buscar efeitos do Supabase (usando fallback): $e');
      }
    }

    // Se estiver offline ou a nuvem estiver vazia, usa o cache local
    if (result.isEmpty) {
      result = await _loadSoundsFromLocalCache();
    }

    // Mescla com sons padrões caso a lista esteja vazia ou falte algum default
    if (fallbackDefaults.isNotEmpty) {
      final existingIds = result.map((e) => e.id).toSet();
      final existingNames = result.map((e) => e.name.toLowerCase()).toSet();

      for (final def in fallbackDefaults) {
        if (!existingIds.contains(def.id) &&
            !existingNames.contains(def.name.toLowerCase())) {
          result.add(def);
        }
      }
    }

    return result;
  }

  /// Salva ou atualiza um efeito sonoro no Supabase e no cache local
  Future<SoundEffect> saveSoundEffect(SoundEffect effect) async {
    SoundEffect savedEffect = effect;

    if (_isInitialized && client != null) {
      try {
        final mapData = effect.toSupabaseMap();
        final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(effect.id);

        Map<String, dynamic> responseData;
        if (isUuid) {
          mapData['id'] = effect.id;
          responseData = await client!
              .from('sound_effects')
              .upsert(mapData)
              .select()
              .single();
        } else {
          responseData = await client!
              .from('sound_effects')
              .insert(mapData)
              .select()
              .single();
        }

        savedEffect = SoundEffect.fromJson(responseData);
      } catch (e) {
        debugPrint('Erro ao salvar efeito no Supabase: $e');
      }
    }

    await _updateSoundInLocalCache(savedEffect);
    return savedEffect;
  }

  /// Remove um efeito sonoro
  Future<bool> deleteSoundEffect(String id) async {
    bool success = true;

    if (_isInitialized && client != null) {
      try {
        final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(id);

        if (isUuid) {
          await client!.from('sound_effects').delete().eq('id', id);
        }
      } catch (e) {
        debugPrint('Erro ao excluir efeito sonoro no Supabase: $e');
        success = false;
      }
    }

    await _removeSoundFromLocalCache(id);
    return success;
  }

  // ===========================================================================
  // UPLOAD DE ARQUIVOS (STORAGE)
  // ===========================================================================

  /// Faz upload de arquivo de áudio no bucket 'sound_effects'
  Future<String?> uploadAudio(File file, {String? customName}) async {
    if (!_isInitialized || client == null) return null;

    try {
      final ext = file.path.split('.').last;
      final cleanName = (customName ?? 'som')
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .toLowerCase();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$cleanName.$ext';

      await client!.storage.from('sound_effects').upload(fileName, file);
      final publicUrl =
          client!.storage.from('sound_effects').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Erro no upload de áudio: $e');
      return null;
    }
  }

  /// Faz upload de vídeo no bucket 'video_effects'
  Future<String?> uploadVideo(File file, {String? customName}) async {
    if (!_isInitialized || client == null) return null;

    try {
      final ext = file.path.split('.').last;
      final cleanName = (customName ?? 'video')
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .toLowerCase();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$cleanName.$ext';

      await client!.storage.from('video_effects').upload(fileName, file);
      final publicUrl =
          client!.storage.from('video_effects').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Erro no upload de vídeo: $e');
      return null;
    }
  }

  // ===========================================================================
  // HISTÓRIAS (stories & story_sounds)
  // ===========================================================================

  /// Busca todas as histórias
  Future<List<Story>> getStories() async {
    List<Story> stories = [];

    if (_isInitialized && client != null) {
      try {
        final storiesResponse = await client!
            .from('stories')
            .select()
            .order('created_at', ascending: false);

        final List<dynamic> storiesData = storiesResponse as List<dynamic>;

        // Busca todas as relações story_sounds
        final List<dynamic> relationsData =
            await client!.from('story_sounds').select();
        final Map<String, List<String>> soundMap = {};
        for (final item in relationsData) {
          final sId = item['story_id']?.toString() ?? '';
          final soundId = item['sound_id']?.toString() ?? '';
          if (sId.isNotEmpty && soundId.isNotEmpty) {
            soundMap.putIfAbsent(sId, () => []).add(soundId);
          }
        }

        stories = storiesData.map((json) {
          final sId = (json['id'] ?? '').toString();
          return Story.fromJson(json as Map<String, dynamic>,
              soundIds: soundMap[sId] ?? []);
        }).toList();

        await _saveStoriesToLocalCache(stories);
      } catch (e) {
        debugPrint('Erro ao buscar histórias no Supabase: $e');
      }
    }

    if (stories.isEmpty) {
      stories = await _loadStoriesFromLocalCache();
    }

    return stories;
  }

  /// Salva história (insere/atualiza na tabela stories e sincroniza story_sounds)
  Future<Story> saveStory(Story story) async {
    Story savedStory = story;

    if (_isInitialized && client != null) {
      try {
        final mapData = story.toSupabaseMap();
        final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(story.id);

        Map<String, dynamic> resData;
        if (isUuid) {
          mapData['id'] = story.id;
          resData =
              await client!.from('stories').upsert(mapData).select().single();
        } else {
          resData =
              await client!.from('stories').insert(mapData).select().single();
        }

        final newStoryId = resData['id'].toString();

        // Sincroniza tabela pivô story_sounds
        await client!.from('story_sounds').delete().eq('story_id', newStoryId);
        if (story.soundIds.isNotEmpty) {
          final insertRelations = story.soundIds
              .map((sid) => {
                    'story_id': newStoryId,
                    'sound_id': sid,
                  })
              .toList();
          await client!.from('story_sounds').insert(insertRelations);
        }

        savedStory = Story.fromJson(resData, soundIds: story.soundIds);
      } catch (e) {
        debugPrint('Erro ao salvar história no Supabase: $e');
      }
    }

    await _updateStoryInLocalCache(savedStory);
    return savedStory;
  }

  /// Exclui uma história
  Future<bool> deleteStory(String id) async {
    bool success = true;

    if (_isInitialized && client != null) {
      try {
        final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(id);

        if (isUuid) {
          await client!.from('stories').delete().eq('id', id);
        }
      } catch (e) {
        debugPrint('Erro ao excluir história no Supabase: $e');
        success = false;
      }
    }

    await _removeStoryFromLocalCache(id);
    return success;
  }

  // ===========================================================================
  // MÉTODOS DE CACHE LOCAL (SharedPreferences)
  // ===========================================================================

  Future<void> _saveSoundsToLocalCache(List<SoundEffect> sounds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sounds.map((s) => s.toJson()).toList();
      await prefs.setString(_localSoundsCacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar sons no cache local: $e');
    }
  }

  Future<List<SoundEffect>> _loadSoundsFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_localSoundsCacheKey);
      if (str == null || str.isEmpty) return [];
      final List<dynamic> list = jsonDecode(str);
      return list
          .map((item) => SoundEffect.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erro ao ler sons do cache local: $e');
      return [];
    }
  }

  Future<void> _updateSoundInLocalCache(SoundEffect effect) async {
    final list = await _loadSoundsFromLocalCache();
    final index = list.indexWhere((e) => e.id == effect.id);
    if (index >= 0) {
      list[index] = effect;
    } else {
      list.insert(0, effect);
    }
    await _saveSoundsToLocalCache(list);
  }

  Future<void> _removeSoundFromLocalCache(String id) async {
    final list = await _loadSoundsFromLocalCache();
    list.removeWhere((e) => e.id == id);
    await _saveSoundsToLocalCache(list);
  }

  Future<void> _saveStoriesToLocalCache(List<Story> stories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = stories.map((s) => s.toJson()).toList();
      await prefs.setString(_localStoriesCacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar histórias no cache local: $e');
    }
  }

  Future<List<Story>> _loadStoriesFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_localStoriesCacheKey);
      if (str == null || str.isEmpty) return [];
      final List<dynamic> list = jsonDecode(str);
      return list
          .map((item) => Story.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erro ao ler histórias do cache local: $e');
      return [];
    }
  }

  Future<void> _updateStoryInLocalCache(Story story) async {
    final list = await _loadStoriesFromLocalCache();
    final index = list.indexWhere((s) => s.id == story.id);
    if (index >= 0) {
      list[index] = story;
    } else {
      list.insert(0, story);
    }
    await _saveStoriesToLocalCache(list);
  }

  Future<void> _removeStoryFromLocalCache(String id) async {
    final list = await _loadStoriesFromLocalCache();
    list.removeWhere((s) => s.id == id);
    await _saveStoriesToLocalCache(list);
  }
}
