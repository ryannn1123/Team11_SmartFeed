import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

final String _groqKey = dotenv.env['GROQ_API_KEY']!;
const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
const _groqModel = 'llama-3.3-70b-versatile';

const _systemPrompt =
    'You are PetBot, a warm, friendly pet assistant for SmartFeed. '
    'Be emotional, caring, and simple. Use emojis like 🐾 🐶 🐱. '
    'Give short helpful answers. Always suggest vet for serious issues.';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class FloatingChatbot extends StatefulWidget {
  const FloatingChatbot({super.key});

  @override
  State<FloatingChatbot> createState() => _FloatingChatbotState();
}

class _FloatingChatbotState extends State<FloatingChatbot>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  bool _loading = false;

  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);

    _messages.add(ChatMessage(
      text: "Hi! I'm PetBot 🐾 I’m here to help your furry friend 💕",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _anim.forward() : _anim.reverse();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _loading = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final msgs = [
        {'role': 'system', 'content': _systemPrompt},
        ..._messages.map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
      ];

      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: jsonEncode({
          'model': _groqModel,
          'messages': msgs,
          'temperature': 0.7,
        }),
      );

      final data = jsonDecode(res.body);
      final reply = data['choices'][0]['message']['content'];

      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Oops 🐾 $e", isUser: false));
      });
    }

    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_open)
          ScaleTransition(
            scale: _scale,
            alignment: Alignment.bottomRight,
            child: Container(
              width: 330,
              height: 470,
              margin: const EdgeInsets.only(bottom: 75, right: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1F6), Color(0xFFEAF6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                  )
                ],
              ),
              child: Column(
                children: [
                  // 🐾 Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFA6C1), Color(0xFF9AD0FF)],
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Text("🐾", style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "PetBot",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _toggle,
                          icon: const Icon(Icons.close, color: Colors.white),
                        )
                      ],
                    ),
                  ),

                  // 💬 Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(10),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          return const _Typing();
                        }

                        final m = _messages[i];
                        return Align(
                          alignment: m.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            constraints:
                                const BoxConstraints(maxWidth: 240),
                            decoration: BoxDecoration(
                              color: m.isUser
                                  ? const Color(0xFFFFA6C1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(
                                color:
                                    m.isUser ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ✏️ Input
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Ask PetBot 🐶",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFA6C1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pets, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 🐾 Floating Paw Button
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: const Color(0xFFFFA6C1),
          child: Icon(_open ? Icons.close : Icons.pets),
        ),
      ],
    );
  }
}

class _Typing extends StatefulWidget {
  const _Typing();

  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
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
      builder: (_, __) {
        return Row(
          children: List.generate(3, (i) {
            final v = (_c.value * 3 - i).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.all(2),
              width: 6,
              height: 6 + (v * 6),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA6C1),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}