import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_models.dart';

// ── Conversation persistence (Firestore) ──────────────────────────────────────
//
// Collection: km_chatbot/{uid}/conversations/{convId}
// Each document stores the full conversation (title + messages array).
// Max 20 conversations per user; older ones auto-pruned.

class ChatRepository {
  static const String _root = 'km_chatbot';
  static const int _maxConversations = 20;
  static const int _maxMessages = 100;

  CollectionReference<Map<String, dynamic>>? _col() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection(_root)
        .doc(uid)
        .collection('conversations');
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> saveConversation(Conversation conv) async {
    final col = _col();
    if (col == null) return;
    // Trim to max messages before saving
    final trimmed = conv.messages.length > _maxMessages
        ? conv.copyWith(messages: conv.messages.sublist(conv.messages.length - _maxMessages))
        : conv;
    await col.doc(conv.id).set(trimmed.toMap());
  }

  Future<List<Conversation>> loadConversations() async {
    final col = _col();
    if (col == null) return [];
    final snap = await col
        .orderBy('updatedAt', descending: true)
        .limit(_maxConversations)
        .get();
    return snap.docs
        .map((d) => Conversation.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> deleteConversation(String convId) async {
    final col = _col();
    if (col == null) return;
    await col.doc(convId).delete();
  }

  /// Prune oldest conversations when limit exceeded.
  Future<void> pruneIfNeeded() async {
    final col = _col();
    if (col == null) return;
    final snap = await col.orderBy('updatedAt', descending: true).get();
    if (snap.docs.length <= _maxConversations) return;
    final toDelete = snap.docs.sublist(_maxConversations);
    final batch = FirebaseFirestore.instance.batch();
    for (final d in toDelete) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
