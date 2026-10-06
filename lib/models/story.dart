class Story {
  final String id;
  final String title;
  final String? description;
  final String? ambientSoundId;
  final List<String> soundIds;
  final DateTime? createdAt;

  Story({
    required this.id,
    required this.title,
    this.description,
    this.ambientSoundId,
    this.soundIds = const [],
    this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json, {List<String>? soundIds}) {
    return Story(
      id: (json['id'] ?? 'story_${DateTime.now().millisecondsSinceEpoch}').toString(),
      title: (json['title'] ?? 'Sem Título').toString(),
      description: json['description']?.toString(),
      ambientSoundId: json['ambient_sound_id']?.toString() ?? json['ambientSoundId']?.toString(),
      soundIds: soundIds ??
          (json['sound_ids'] != null
              ? List<String>.from((json['sound_ids'] as List).map((e) => e.toString()))
              : (json['soundIds'] != null
                  ? List<String>.from((json['soundIds'] as List).map((e) => e.toString()))
                  : [])),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ambient_sound_id': ambientSoundId,
      'ambientSoundId': ambientSoundId,
      'sound_ids': soundIds,
      'soundIds': soundIds,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'title': title,
      'description': description,
      'ambient_sound_id': ambientSoundId,
    };
  }

  Story copyWith({
    String? id,
    String? title,
    String? description,
    String? ambientSoundId,
    List<String>? soundIds,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ambientSoundId: ambientSoundId ?? this.ambientSoundId,
      soundIds: soundIds ?? this.soundIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

