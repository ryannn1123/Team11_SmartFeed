import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

final String _groqKey = dotenv.env['GROQ_API_KEY']!;
const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
const _groqModel = 'openai/gpt-oss-20b';
const _systemPrompt =

    'You are PetBot, an AI assistant for the SmartFeed pet feeding system. Only answer questions related to pets, pet care, feeding, SmartFeed, and the features of this application. If the user asks about unrelated topics such as programming, mathematics, general knowledge, or other subjects, politely explain that you can only help with pet and SmartFeed-related questions.'
    'Give short helpful answers. Always suggest vet for serious issues.'
    'Be emotional, caring, and simple. '
    'Be friendly pet assistant for SmartFeed.';
   
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

  // Custom Palette Hexes from provided image
  static const Color _coralPink = Color(0xFFFF8C7A);
  static const Color _softPeach = Color(0xFFFFB399);
  static const Color _creamLight = Color(0xFFFFF5CC);

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

    // Check if Groq returned an error
    if (res.statusCode != 200) {
      final errorMessage =
          data['error']?['message'] ?? 'Unknown Groq API error';

      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry 🐾 I couldn't respond right now.\n\n$errorMessage",
            isUser: false,
          ),
        );
      });

      return;
    }

    // Get the AI response
    final reply = data['choices']?[0]?['message']?['content'];

    if (reply == null || reply.toString().trim().isEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry 🐾 I didn't receive a response from PetBot.",
            isUser: false,
          ),
        );
      });

      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: reply.toString(),
          isUser: false,
        ),
      );
    });
  } catch (e) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "Oops 🐾 Something went wrong. Please try again.",
          isUser: false,
        ),
      );
    });
  } finally {
    setState(() => _loading = false);
    _scrollToBottom();
  }
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
                  colors: [_creamLight, Color(0xFFFFFDF9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
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
                        colors: [_coralPink, _softPeach],
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
                          return const _Typing(dotColor: _coralPink);
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
                                  ? _coralPink
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
                              color: _coralPink,
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
          backgroundColor: _coralPink,
          foregroundColor: Colors.white,
          child: Icon(_open ? Icons.close : Icons.pets),
        ),
      ],
    );
  }

  void _scrollToBottom() {}
}

class _Typing extends StatefulWidget {
  final Color dotColor;
  const _Typing({this.dotColor = const Color(0xFFFF8C7A)});

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
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}