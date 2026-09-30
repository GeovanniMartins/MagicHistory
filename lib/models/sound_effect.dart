class SoundEffect {
  final String id;
  final List<String> keywords;
  final String audioFile;
  final int cooldownSeconds;

  SoundEffect({
    required this.id,
    required this.keywords,
    required this.audioFile,
    required this.cooldownSeconds,
  });

  factory SoundEffect.fromJson(Map<String, dynamic> json) {
    return SoundEffect(
      id: json['id'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      audioFile: json['audioFile'] as String,
      cooldownSeconds: json['cooldownSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keywords': keywords,
      'audioFile': audioFile,
      'cooldownSeconds': cooldownSeconds,
    };
  }
}
