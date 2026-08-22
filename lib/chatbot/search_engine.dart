import 'chat_models.dart';

// ── Search engine ─────────────────────────────────────────────────────────────
//
// Matches user queries against the local knowledge base.
// Only single-word keywords are used for matching to avoid false positives
// from multi-word phrases (e.g. "dryland farming" ≠ "farming").
// Queries about market prices, weather, government schemes, etc. are
// intentionally skipped so they go to Groq for better answers.

class SearchEngine {
  // Minimum fraction of query tokens that must exactly match KB keywords.
  // 0.5 = at least 50% of tokens must match.
  static const double _minScore = 0.5;

  // If any of these words appear in the query, skip the KB entirely.
  // These topics have no useful KB entry and should go straight to Groq.
  static const Set<String> _skipTopics = {
    'price', 'prices', 'cost', 'costs', 'market', 'rate', 'rates',
    'value', 'rupee', 'rupees', 'money', 'income', 'profit', 'earn',
    'weather', 'rain', 'rainfall', 'temperature', 'forecast', 'humidity',
    'scheme', 'schemes', 'loan', 'loans', 'insurance', 'subsidy',
    'government', 'policy', 'regulation', 'law',
    'sell', 'selling', 'buy', 'buying', 'export', 'import', 'trade',
    'labour', 'labor', 'worker', 'salary', 'wage',
    'rent', 'hire', 'machine', 'tractor', 'equipment',
  };

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

  /// Returns the best-matching [KnowledgeEntry] for [query], or null if:
  /// - the score is below [_minScore], or
  /// - the query contains a skip-topic word.
  KnowledgeEntry? search(String query, List<KnowledgeEntry> entries) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return null;

    // Skip KB for topics it cannot answer well
    if (tokens.any((t) => _skipTopics.contains(t))) return null;

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

  /// All matching entries ranked by score (for multi-answer scenarios).
  List<KnowledgeEntry> searchAll(
    String query,
    List<KnowledgeEntry> entries, {
    int limit = 3,
  }) {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return [];
    if (tokens.any((t) => _skipTopics.contains(t))) return [];

    final scored = <_Scored>[];
    for (final entry in entries) {
      final s = _score(tokens, entry);
      if (s >= _minScore) scored.add(_Scored(entry, s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.entry).toList();
  }

  /// Scores a query against one KB entry using exact single-word matching.
  ///
  /// Only single-word keywords are used. Multi-word phrases (e.g. "dryland
  /// farming", "yellow leaves") are excluded to avoid false partial matches
  /// like token "farming" matching keyword phrase "dryland farming".
  double _score(List<String> tokens, KnowledgeEntry entry) {
    if (tokens.isEmpty) return 0;

    // Collect only single-word keywords (no spaces)
    final singleWordKws = <String>{};
    for (final kw in entry.keywords) {
      final lower = kw.toLowerCase();
      if (!lower.contains(' ')) singleWordKws.add(lower);
    }

    if (singleWordKws.isEmpty) return 0;

    double hits = 0;
    for (final token in tokens) {
      if (singleWordKws.contains(token)) hits += 1.0;
    }

    return hits / tokens.length;
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
