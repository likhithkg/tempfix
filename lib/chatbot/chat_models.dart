import 'package:cloud_firestore/cloud_firestore.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? matchedCategory;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.matchedCategory,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String? ?? '',
        content: m['content'] as String? ?? '',
        isUser: m['isUser'] as bool? ?? false,
        timestamp: m['timestamp'] is Timestamp
            ? (m['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        matchedCategory: m['matchedCategory'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': Timestamp.fromDate(timestamp),
        if (matchedCategory != null) 'matchedCategory': matchedCategory,
      };
}

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory Conversation.fromMap(String id, Map<String, dynamic> m) {
    final raw = (m['messages'] as List<dynamic>?) ?? [];
    return Conversation(
      id: id,
      title: m['title'] as String? ?? 'Conversation',
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: m['updatedAt'] is Timestamp
          ? (m['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      messages: raw
          .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'messages': messages.map((m) => m.toMap()).toList(),
      };

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messages: messages ?? this.messages,
      );
}

class KnowledgeEntry {
  final String id;
  final String category;
  final String categoryEmoji;
  final List<String> keywords;
  final Map<String, String> answers;

  const KnowledgeEntry({
    required this.id,
    required this.category,
    required this.categoryEmoji,
    required this.keywords,
    required this.answers,
  });

  /// Returns the answer for [langCode], falling back to English.
  String getAnswer(String langCode) =>
      answers[langCode] ?? answers['en'] ?? 'No answer available.';
}
