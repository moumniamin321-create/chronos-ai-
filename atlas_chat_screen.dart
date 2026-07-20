import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_state.dart';
import '../../services/ai_service.dart';
import '../../services/voice_service.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  ChatMessage({required this.text, required this.fromUser});
}

class AtlasChatScreen extends StatefulWidget {
  final bool embedded;
  const AtlasChatScreen({super.key, this.embedded = false});

  @override
  State<AtlasChatScreen> createState() => _AtlasChatScreenState();
}

class _AtlasChatScreenState extends State<AtlasChatScreen> {
  final _aiService = AIService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'مرحبًا! أنا Atlas 🤖، مساعدك الشخصي لتنظيم وقتك.\n'
          'جرّب أن تخبرني مثلاً: "لدي امتحان بعد أسبوع وأريد الدراسة والرياضة"',
      fromUser: false,
    ),
  ];
  bool _sending = false;
  bool _listening = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, fromUser: true));
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();

    final user = context.read<AppState>().user;
    final reply = await _aiService.generateReply(
      text,
      today: DateTime.now(),
      wakeTime: user?.wakeTime ?? '07:00',
      sleepTime: user?.sleepTime ?? '23:00',
    );

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: reply.text, fromUser: false));
      _sending = false;
    });

    if (reply.generatedTasks.isNotEmpty) {
      await context.read<AppState>().awardXp(10);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await VoiceService.instance.stopListening();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await VoiceService.instance.listen(
      onResult: (text) {
        setState(() => _listening = false);
        if (text.trim().isNotEmpty) _send(text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _messages.length) {
                return const _TypingBubble();
              }
              return _MessageBubble(message: _messages[index]);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleVoice,
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? AppColors.accent : AppColors.textSecondary),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'اكتب رسالتك لـ Atlas...'),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Icon(Icons.smart_toy_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Atlas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Atlas')),
      body: body,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.surfaceVariant : AppColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? AppColors.textPrimary : Colors.white),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
        child: const SizedBox(
          width: 24,
          child: LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.white24),
        ),
      ),
    );
  }
}
