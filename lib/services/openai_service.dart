import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/content.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Minimal client for the OpenAI Chat Completions API (ChatGPT).
class OpenAiService {
  OpenAiService({
    required this.apiKey,
    required this.model,
    http.Client? client,
    Uri? endpoint,
  })  : _client = client ?? http.Client(),
        _endpoint =
            endpoint ?? Uri.parse('https://api.openai.com/v1/chat/completions');

  static const systemPrompt =
      'You are E-Campus Assistant, a friendly study helper for college students. '
      'Explain concepts clearly and concisely, give short examples, and say so '
      'when you are unsure.';

  final String apiKey;
  final String model;
  final http.Client _client;
  final Uri _endpoint;

  bool get isConfigured => apiKey.isNotEmpty;

  /// Sends the conversation [history] (oldest first) and returns the reply.
  Future<String> reply(List<AiTurn> history) async {
    if (!isConfigured) {
      throw AiException(
        'The AI assistant is not configured. Build the app with '
        '--dart-define=OPENAI_API_KEY=<your key>.',
      );
    }
    final http.Response res;
    try {
      res = await _client
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                for (final t in history)
                  {'role': t.role, 'content': t.content},
              ],
            }),
          )
          .timeout(const Duration(seconds: 45));
    } on Exception {
      throw AiException('Could not reach the AI service. Check your connection.');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw AiException('Unexpected response from the AI service (${res.statusCode}).');
    }

    if (res.statusCode != 200) {
      final msg = (data['error'] as Map?)?['message'] as String?;
      throw AiException(msg ?? 'AI request failed (${res.statusCode}).');
    }
    final choices = data['choices'] as List?;
    final content = choices == null || choices.isEmpty
        ? null
        : ((choices.first as Map)['message'] as Map?)?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw AiException('The AI service returned an empty answer.');
    }
    return content.trim();
  }
}
