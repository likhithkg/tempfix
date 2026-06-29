import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiPlantAssistantPage extends StatefulWidget {
  const AiPlantAssistantPage({super.key});
  @override
  State<AiPlantAssistantPage> createState() =>
      _AiPlantAssistantPageState();
}

class _AiPlantAssistantPageState extends State<AiPlantAssistantPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  final List<_Msg> _msgs = [];
  bool _loading = false;

  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final _quickPrompts = [
    '🌞 Best plants for sunny balcony',
    '🏠 Low-maintenance indoor plants',
    '🍅 Vegetables for small garden',
    '🌧️ Plants for rainy season',
    '🐛 Organic pest control tips',
    '💧 Drought-resistant plants',
    '🌸 Flowering plants for home garden',
    '🍃 Air purifying plants',
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
      text: '🌿 Hello! I\'m your AI Plant Advisor.\n\n'
          'I can help you with:\n'
          '• Plant recommendations for your climate\n'
          '• Seasonal planting advice\n'
          '• Care instructions & watering schedules\n'
          '• Pest control & disease prevention\n'
          '• Companion planting tips\n\n'
          'Ask me anything about plants! 🌱',
      isBot: true,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final q = text.trim();
    _ctrl.clear();
    _focus.unfocus();
    setState(() {
      _msgs.add(_Msg(text: q, isBot: false));
      _loading = true;
    });
    _scrollBottom();

    try {
      final key = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (key.isEmpty) {
        _addBot('⚠️ AI service not configured. Add GEMINI_API_KEY to .env');
        return;
      }

      final resp = await http.post(
        Uri.parse('$_url?key=$key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'You are an expert Indian plant nursery advisor '
                      'and agricultural specialist.\n'
                      'You help farmers and gardeners choose the right plants.\n'
                      'Give practical, specific advice relevant to Indian climate, '
                      'seasons (Kharif/Rabi/Zaid), and farming practices.\n'
                      'Keep responses clear, concise and actionable.\n'
                      'When recommending plants, mention:\n'
                      '- Best season to plant\n'
                      '- Sunlight & water needs\n'
                      '- Expected time to harvest/bloom\n'
                      '- Care tips\n\n'
                      'User question: $q'
                }
              ]
            }
          ]
        }),
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final reply =
            decoded['candidates']?[0]?['content']?['parts']?[0]?['text']
                    ?.toString()
                    .trim() ??
                'Sorry, I could not generate a response.';
        _addBot(reply);
      } else {
        _addBot('⚠️ AI server error (${resp.statusCode}). Please try again.');
      }
    } catch (e) {
      _addBot('⚠️ Connection error. Please check your internet and try again.');
    }
  }

  void _addBot(String text) {
    if (mounted) {
      setState(() {
        _msgs.add(_Msg(text: text, isBot: true));
        _loading = false;
      });
      _scrollBottom();
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Text('🤖', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Plant Advisor',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Powered by Gemini AI',
                style: TextStyle(fontSize: 9.5, color: Colors.white70)),
          ]),
        ]),
        elevation: 0,
      ),
      body: Column(children: [
        // Quick prompts
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            itemCount: _quickPrompts.length,
            itemBuilder: (_, i) {
              final p = _quickPrompts[i];
              return GestureDetector(
                onTap: () => _send(p),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                  ),
                  child: Text(p,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32))),
                ),
              );
            },
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (_loading && i == _msgs.length) {
                return _TypingIndicator();
              }
              final m = _msgs[i];
              return _MsgBubble(msg: m);
            },
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(
              12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3))
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onSubmitted: _send,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Ask about plants, care, season...',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _send(_ctrl.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _loading
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _loading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Msg {
  final String text;
  final bool isBot;
  _Msg({required this.text, required this.isBot});
}

class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  const _MsgBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isBot
              ? Colors.white
              : const Color(0xFF2E7D32),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
            bottomRight: Radius.circular(msg.isBot ? 16 : 4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: msg.isBot ? const Color(0xFF1B1B1B) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );
    _anims = List.generate(3, (i) {
      Future.delayed(Duration(milliseconds: i * 150),
          () => mounted ? _ctrls[i].forward() : null);
      return Tween<double>(begin: 0, end: 1).animate(_ctrls[i]);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07), blurRadius: 6)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _anims[i],
              builder: (_, __) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7 + _anims[i].value * 4,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFBDBDBD),
                    const Color(0xFF2E7D32),
                    _anims[i].value,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
