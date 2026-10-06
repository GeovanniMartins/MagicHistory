class TextMatcher {
  /// Verifica se alguma das palavras-chave está presente no texto transcrito
  static bool matches(String text, List<String> keywords) {
    if (keywords.isEmpty || text.trim().isEmpty) return false;

    final normalizedText = _normalize(text);
    final textWords = normalizedText.split(RegExp(r'\s+'));

    for (final kw in keywords) {
      final normalizedKw = _normalize(kw);
      if (normalizedKw.isEmpty) continue;

      // Se a palavra-chave tiver mais de uma palavra (ex: "era uma vez")
      if (normalizedKw.contains(' ')) {
        if (normalizedText.contains(normalizedKw)) {
          return true;
        }
      } else {
        // Para palavra única, checa correspondência exata de palavra ou contenção
        if (textWords.contains(normalizedKw) ||
            normalizedText.contains(normalizedKw)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Remove acentos, pontuações e converte para minúsculas
  static String _normalize(String input) {
    var output = input.toLowerCase();

    const withDia = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñç';
    const withoutDia = 'aaaaaaeeeeiiiiooooouuuuyync';

    for (int i = 0; i < withDia.length; i++) {
      output = output.replaceAll(withDia[i], withoutDia[i]);
    }

    // Substitui pontuações e caracteres especiais por espaços
    output = output.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // Remove espaços extras
    output = output.replaceAll(RegExp(r'\s+'), ' ').trim();

    return output;
  }
}
