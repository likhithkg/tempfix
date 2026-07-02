import 'chat_models.dart';

// ── Search engine ─────────────────────────────────────────────────────────────

class SearchEngine {
  static const double _minScore = 0.18;

  static const List<String> _stopWords = [
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'must', 'can', 'i', 'my', 'me', 'we', 'our',
    'you', 'your', 'he', 'she', 'it', 'they', 'them', 'this', 'that',
    'these', 'those', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by',
    'from', 'up', 'about', 'into', 'and', 'but', 'or', 'not', 'so',
    'please', 'help', 'tell', 'know', 'want', 'need', 'use', 'good',
    'best', 'better', 'get', 'give', 'make', 'like', 'just', 'also',
    'than', 'then', 'when', 'where', 'how', 'what', 'which', 'who',
    'why', 'very', 'more', 'some', 'any', 'all', 'there', 'their',
    'here', 'even', 'each', 'other',
  ];

  /// Finds the single best-matching [KnowledgeEntry] for a user [query],
  /// or returns null if no entry clears the minimum score threshold.
  KnowledgeEntry? search(String query, List<KnowledgeEntry> entries) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return null;

    KnowledgeEntry? best;
    double bestScore = 0;

    for (final entry in entries) {
      final score = _score(tokens, entry);
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    return bestScore >= _minScore ? best : null;
  }

  /// Returns all matching entries ranked by score (for multi-answer scenarios).
  List<KnowledgeEntry> searchAll(
      String query, List<KnowledgeEntry> entries, {int limit = 3}) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return [];

    final scored = <_Scored>[];
    for (final entry in entries) {
      final s = _score(tokens, entry);
      if (s >= _minScore) scored.add(_Scored(entry, s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.entry).toList();
  }

  double _score(List<String> queryTokens, KnowledgeEntry entry) {
    if (queryTokens.isEmpty) return 0;

    double hits = 0;
    final kwLower = entry.keywords.map((k) => k.toLowerCase()).toList();

    for (final token in queryTokens) {
      bool matched = false;
      for (final kw in kwLower) {
        // Exact match gets full credit
        if (kw == token) {
          hits += 1.0;
          matched = true;
          break;
        }
        // Partial match (keyword contains token or vice versa) gets half credit
        if (!matched && (kw.contains(token) || token.contains(kw))) {
          hits += 0.5;
          matched = true;
          break;
        }
      }
      // Category name match
      if (!matched &&
          entry.category.toLowerCase().contains(token)) {
        hits += 0.3;
      }
    }

    return hits / queryTokens.length;
  }

  List<String> _tokenize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r"[^\w\s]"), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length > 2 && !_stopWords.contains(t))
      .toList();
}

class _Scored {
  final KnowledgeEntry entry;
  final double score;
  const _Scored(this.entry, this.score);
}
