import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../theme.dart';
import 'chat_models.dart';
import 'chat_repository.dart';
import 'chatbot_service.dart';
import 'search_engine.dart';

// ── Language option ───────────────────────────────────────────────────────────

class _Lang {
  final String code;
  final String label;
  final String flag;
  const _Lang(this.code, this.label, this.flag);
}

const _kLangs = [
  _Lang('en', 'English', '🇬🇧'),
  _Lang('hi', 'हिंदी', '🇮🇳'),
  _Lang('kn', 'ಕನ್ನಡ', '🇮🇳'),
  _Lang('ta', 'தமிழ்', '🇮🇳'),
  _Lang('te', 'తెలుగు', '🇮🇳'),
];

// ── Quick suggestion prompts ──────────────────────────────────────────────────

const _kSuggestions = [
  '🌾 How to grow rice?',
  '🌽 Maize fertilizer schedule',
  '🦠 Rice blast disease control',
  '🚜 Best time to sow wheat?',
  '🌱 Sugarcane pest management',
  '💧 Drip irrigation for vegetables',
];

// ── Page ──────────────────────────────────────────────────────────────────────

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _repo = ChatRepository();
  final _engine = SearchEngine();
  final _service = ChatbotService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _uuid = const Uuid();

  List<KnowledgeEntry> _entries = [];
  List<Conversation> _history = [];
  Conversation? _current;
  bool _sending = false;
  bool _initialising = true;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _init() async {
    await Future.wait([_loadKnowledgeBase(), _loadHistory()]);
    if (_current == null && mounted) {
      _startNewConversation(save: false);
    }
    if (mounted) setState(() => _initialising = false);
  }

  Future<void> _loadKnowledgeBase() async {
    final entries = <KnowledgeEntry>[];
    for (final (path, emoji, cat) in [
      ('assets/knowledge_base/crops.json', '🌾', 'Crops'),
      ('assets/knowledge_base/crop_diseases.json', '🦠', 'Crop Diseases'),
    ]) {
      try {
        final raw = await rootBundle.loadString(path);
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;
        for (final item in items) {
          final m = item as Map<String, dynamic>;
          entries.add(KnowledgeEntry(
            id: _uuid.v4(),
            category: cat,
            categoryEmoji: emoji,
            keywords: List<String>.from(m['keywords'] as List),
            answers: {'en': m['answer'] as String},
          ));
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _loadHistory() async {
    final convs = await _repo.loadConversations();
    if (!mounted) return;
    setState(() {
      _history = convs;
      if (convs.isNotEmpty) _current = convs.first;
    });
  }

  void _startNewConversation({bool save = true}) {
    final greeting = ChatMessage(
      id: _uuid.v4(),
      content:
          'Hello! 👋 I am KrishiMithra AI.\n\n'
          'I can help you with:\n'
          '• Crop cultivation & best practices\n'
          '• Disease & pest identification\n'
          '• Fertilizer & irrigation advice\n'
          '• Market & weather insights\n\n'
          'Ask me anything about farming!',
      isUser: false,
      timestamp: DateTime.now(),
    );
    final conv = Conversation(
      id: _uuid.v4(),
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [greeting],
    );
    setState(() {
      _current = conv;
      _history.insert(0, conv);
    });
    if (save) _repo.saveConversation(conv);
  }

  void _switchConversation(Conversation conv) {
    setState(() => _current = conv);
    Navigator.of(context).pop(); // close drawer
    _scrollToBottom();
  }

  Future<void> _deleteConversation(Conversation conv) async {
    await _repo.deleteConversation(conv.id);
    setState(() {
      _history.removeWhere((c) => c.id == conv.id);
      if (_current?.id == conv.id) {
        _current = _history.isNotEmpty ? _history.first : null;
        if (_current == null) _startNewConversation(save: false);
      }
    });
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;

    _ctrl.clear();

    var conv = _current!;

    // Auto-title on first user message
    if (conv.messages.length == 1) {
      final title = text.length > 45 ? '${text.substring(0, 45)}…' : text;
      conv = conv.copyWith(title: title, updatedAt: DateTime.now());
    }

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    conv = conv.copyWith(
      messages: [...conv.messages, userMsg],
      updatedAt: DateTime.now(),
    );

    setState(() {
      _current = conv;
      _sending = true;
      _syncHistory(conv);
    });
    _scrollToBottom();

    // ── Answer resolution ─────────────────────────────────────────────────
    String reply;
    String? matchedCategory;

    final match = _engine.search(text, _entries);
    if (match != null) {
      matchedCategory = '${match.categoryEmoji} ${match.category}';
      if (_lang == 'en') {
        reply = match.getAnswer('en');
      } else {
        reply = await _service.getBotReplyWithContext(
            text, _lang, match.getAnswer('en'));
      }
    } else {
      reply = await _service.getBotReply(text, _lang);
    }

    final botMsg = ChatMessage(
      id: _uuid.v4(),
      content: reply,
      isUser: false,
      timestamp: DateTime.now(),
      matchedCategory: matchedCategory,
    );

    conv = _current!.copyWith(
      messages: [..._current!.messages, botMsg],
      updatedAt: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _current = conv;
      _sending = false;
      _syncHistory(conv);
    });

    await _repo.saveConversation(conv);
    _scrollToBottom();
  }

  void _syncHistory(Conversation conv) {
    final idx = _history.indexWhere((c) => c.id == conv.id);
    if (idx >= 0) {
      _history[idx] = conv;
    } else {
      _history.insert(0, conv);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : const Color(0xFFF0F7F0),
      drawer: _buildHistoryDrawer(cs, isDark),
      appBar: _buildAppBar(cs),
      body: _initialising
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(child: _buildMessageList(cs, isDark)),
              if (_sending) _buildTypingIndicator(cs),
              _buildInputBar(cs, isDark),
            ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(ColorScheme cs) {
    return AppBar(
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('KrishiMithra AI',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        Text('Powered by Gemini',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
      ]),
      actions: [
        // Language picker
        PopupMenuButton<String>(
          initialValue: _lang,
          tooltip: 'Language',
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _kLangs.firstWhere((l) => l.code == _lang).flag,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          onSelected: (code) => setState(() => _lang = code),
          itemBuilder: (_) => _kLangs
              .map((l) => PopupMenuItem<String>(
                    value: l.code,
                    child: Row(children: [
                      Text(l.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(l.label),
                      if (l.code == _lang) ...[
                        const Spacer(),
                        Icon(Icons.check, size: 16, color: cs.primary),
                      ],
                    ]),
                  ))
              .toList(),
        ),
        // History button
        Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.white),
          tooltip: 'Chat history',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── History Drawer ────────────────────────────────────────────────────────

  Widget _buildHistoryDrawer(ColorScheme cs, bool isDark) {
    return Drawer(
      child: Column(children: [
        DrawerHeader(
          decoration: BoxDecoration(color: cs.primary),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Chat History',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startNewConversation();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _history.isEmpty
              ? Center(
                  child: Text('No previous chats',
                      style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final conv = _history[i];
                    final isActive = conv.id == _current?.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive
                            ? cs.primary
                            : cs.primaryContainer,
                        radius: 18,
                        child: Icon(Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color:
                                isActive ? Colors.white : cs.onPrimaryContainer),
                      ),
                      title: Text(
                        conv.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13),
                      ),
                      subtitle: Text(
                        '${conv.messages.length} messages',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                      selected: isActive,
                      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 18, color: cs.error),
                        onPressed: () => _deleteConversation(conv),
                      ),
                      onTap: () => _switchConversation(conv),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  // ── Messages list ─────────────────────────────────────────────────────────

  Widget _buildMessageList(ColorScheme cs, bool isDark) {
    final msgs = _current?.messages ?? [];

    if (msgs.length <= 1) {
      return _buildEmptyState(msgs, cs, isDark);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: msgs.length,
      itemBuilder: (_, i) => _MessageBubble(
        message: msgs[i],
        isDark: isDark,
        cs: cs,
        onLongPress: () => _copyMessage(msgs[i].content),
      ),
    );
  }

  Widget _buildEmptyState(
      List<ChatMessage> msgs, ColorScheme cs, bool isDark) {
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        // Greeting bubble
        if (msgs.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _MessageBubble(
                message: msgs.first,
                isDark: isDark,
                cs: cs,
                onLongPress: () => _copyMessage(msgs.first.content),
              ),
            ),
          ),
        // Quick suggestions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
            child: Text('Try asking:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _SuggestionChip(
                label: _kSuggestions[i],
                onTap: () => _send(_kSuggestions[i]),
              ),
              childCount: _kSuggestions.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
            ),
          ),
        ),
      ],
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 4),
      child: Row(children: [
        _BotAvatar(cs: cs, size: 28),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: KMShadow.card,
          ),
          child: const _TypingDots(),
        ),
      ]),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              enabled: !_sending,
              decoration: InputDecoration(
                hintText: 'Ask about crops, diseases, farming…',
                hintStyle: TextStyle(
                    fontSize: 14, color: cs.onSurfaceVariant),
                filled: true,
                fillColor: isDark
                    ? KMColors.backgroundDark
                    : const Color(0xFFF0F7F0),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _sending ? Colors.grey.shade300 : cs.primary,
              child: IconButton(
                icon: Icon(Icons.send_rounded,
                    color: _sending ? Colors.grey : Colors.white, size: 20),
                onPressed: _sending ? null : _send,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Message copied'),
          duration: Duration(seconds: 1)),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.cs,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _BotAvatar(cs: cs, size: 30),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // KB source badge
                  if (!isUser && message.matchedCategory != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: KMColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: KMColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.menu_book_rounded,
                            size: 11, color: KMColors.primary),
                        const SizedBox(width: 4),
                        Text(message.matchedCategory!,
                            style: const TextStyle(
                                fontSize: 10,
                                color: KMColors.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  // Bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? cs.primary
                          : (isDark ? KMColors.cardDark : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 2),
                        bottomRight: Radius.circular(isUser ? 2 : 16),
                      ),
                      boxShadow: KMShadow.card,
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isUser ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ),
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Text(
                      _fmt(message.timestamp),
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }
}

// ── Bot avatar ────────────────────────────────────────────────────────────────

class _BotAvatar extends StatelessWidget {
  final ColorScheme cs;
  final double size;
  const _BotAvatar({required this.cs, required this.size});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primaryContainer,
      child: Icon(Icons.eco_rounded,
          size: size * 0.55, color: cs.onPrimaryContainer),
    );
  }
}

// ── Suggestion chip ───────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: cs.primary.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ── Typing dots animation ─────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.28;
          final t = ((_c.value - delay).clamp(0.0, 0.45) / 0.45);
          final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KMColors.primary.withValues(alpha: opacity),
            ),
          );
        }),
      ),
    );
  }
}
