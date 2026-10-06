class SoundEffect {
  final String id;
  final String name;
  final List<String> keywords;
  final String audioFile; // URL remota, caminho de arquivo local ou asset
  final String? videoUrl; // URL ou caminho local de vídeo curto associado
  final int cooldownSeconds;
  final bool isCustom;
  final String soundType; // 'effect' (efeito sonoro) ou 'ambient' (música/ambiente de fundo)
  final double volume; // 0.0 a 1.0
  final String themeColor; // Ex: '#38C3FF', '#FF5EA1', '#8C62FF', '#FFB800'
  final DateTime? createdAt;

  SoundEffect({
    required this.id,
    String? name,
    required this.keywords,
    required this.audioFile,
    this.videoUrl,
    this.cooldownSeconds = 3,
    this.isCustom = true,
    this.soundType = 'effect',
    this.volume = 1.0,
    this.themeColor = '#8C62FF',
    this.createdAt,
  }) : name = name ?? id;

  bool get isAmbient => soundType == 'ambient';

  factory SoundEffect.fromJson(Map<String, dynamic> json) {
    return SoundEffect(
      id: (json['id'] ?? json['name'] ?? 'som_${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: (json['name'] ?? json['id'] ?? 'Sem Nome').toString(),
      keywords: json['keywords'] != null
          ? List<String>.from((json['keywords'] as List).map((e) => e.toString()))
          : [],
      audioFile: (json['audio_url'] ?? json['audioFile'] ?? '').toString(),
      videoUrl: json['video_url']?.toString() ?? json['videoUrl']?.toString(),
      cooldownSeconds: (json['cooldown_seconds'] ?? json['cooldownSeconds'] ?? 3) as int,
      isCustom: (json['is_custom'] ?? json['isCustom'] ?? true) as bool,
      soundType: (json['sound_type'] ?? json['soundType'] ?? 'effect').toString(),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      themeColor: (json['theme_color'] ?? json['themeColor'] ?? '#8C62FF').toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'keywords': keywords,
      'audioFile': audioFile,
      'audio_url': audioFile,
      'videoUrl': videoUrl,
      'video_url': videoUrl,
      'cooldownSeconds': cooldownSeconds,
      'cooldown_seconds': cooldownSeconds,
      'isCustom': isCustom,
      'is_custom': isCustom,
      'soundType': soundType,
      'sound_type': soundType,
      'volume': volume,
      'themeColor': themeColor,
      'theme_color': themeColor,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'name': name,
      'keywords': keywords,
      'audio_url': audioFile,
      'video_url': videoUrl,
      'cooldown_seconds': cooldownSeconds,
      'is_custom': isCustom,
      'sound_type': soundType,
      'volume': volume,
      'theme_color': themeColor,
    };
  }

  SoundEffect copyWith({
    String? id,
    String? name,
    List<String>? keywords,
    String? audioFile,
    String? videoUrl,
    int? cooldownSeconds,
    bool? isCustom,
    String? soundType,
    double? volume,
    String? themeColor,
    DateTime? createdAt,
  }) {
    return SoundEffect(
      id: id ?? this.id,
      name: name ?? this.name,
      keywords: keywords ?? this.keywords,
      audioFile: audioFile ?? this.audioFile,
      videoUrl: videoUrl ?? this.videoUrl,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      isCustom: isCustom ?? this.isCustom,
      soundType: soundType ?? this.soundType,
      volume: volume ?? this.volume,
      themeColor: themeColor ?? this.themeColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
