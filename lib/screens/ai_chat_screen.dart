import 'package:flutter/material.dart';

import '../config.dart';
import '../models/content.dart';
import '../services/openai_service.dart';
import '../widgets/common.dart';

/// Doubt-clearing chatbot backed by the ChatGPT (OpenAI) API.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.service});

  /// Injectable for tests; defaults to the real service.
  final OpenAiService? service;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <AiTurn>[];
  late final OpenAiService _ai = widget.service ??
      OpenAiService(apiKey: AppConfig.openAiApiKey, model: AppConfig.openAiModel);
  bool _waiting = false;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _text.text.trim();
    if (q.isEmpty || _waiting) return;
    _text.clear();
    setState(() {
      _turns.add(AiTurn('user', q));
      _waiting = true;
    });
    _scrollDown();
    try {
      // Keep the request small: send only the most recent turns.
      final history = _turns.length > 20 ? _turns.sublist(_turns.length - 20) : _turns;
      final answer = await _ai.reply(List.of(history));
      if (mounted) setState(() => _turns.add(AiTurn('assistant', answer)));
    } on AiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _waiting = false);
      _scrollDown();
    }
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (!_ai.isConfigured)
          MaterialBanner(
            content: const Text('AI is not configured: build with --dart-define=OPENAI_API_KEY=…'),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          child: _turns.isEmpty
              ? const EmptyState(
                  icon: Icons.smart_toy_outlined,
                  message: 'Ask me anything about your subjects.')
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _turns.length + (_waiting ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _turns.length) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Thinking…')),
                      );
                    }
                    final t = _turns[i];
                    final mine = t.role == 'user';
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.8),
                        decoration: BoxDecoration(
                          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SelectableText(t.content),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: 'Ask a question', border: OutlineInputBorder()),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton.filled(
                onPressed: _waiting ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
