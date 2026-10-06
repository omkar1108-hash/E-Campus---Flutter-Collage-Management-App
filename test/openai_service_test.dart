import 'dart:convert';

import 'package:e_campus/models/content.dart';
import 'package:e_campus/services/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

OpenAiService svc(MockClient c, {String key = 'sk-test'}) =>
    OpenAiService(apiKey: key, model: 'test-model', client: c);

void main() {
  final turns = [const AiTurn('user', 'What is a stack?')];

  test('sends model, system prompt, history and bearer token', () async {
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': '  A LIFO structure.  '}}
            ]
          }),
          200);
    });

    final answer = await svc(client).reply(turns);

    expect(answer, 'A LIFO structure.');
    expect(seen.headers['Authorization'], 'Bearer sk-test');
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect(body['model'], 'test-model');
    final msgs = body['messages'] as List;
    expect(msgs.first['role'], 'system');
    expect(msgs.last, {'role': 'user', 'content': 'What is a stack?'});
  });

  test('throws a helpful error when no API key is set', () {
    final client = MockClient((_) async => http.Response('', 200));
    expect(svc(client, key: '').reply(turns), throwsA(isA<AiException>()));
  });

  test('surfaces the API error message on non-200', () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({'error': {'message': 'Invalid API key'}}), 401));
    await expectLater(
      svc(client).reply(turns),
      throwsA(isA<AiException>().having((e) => e.message, 'message', 'Invalid API key')),
    );
  });

  test('handles a non-JSON body', () {
    final client = MockClient((_) async => http.Response('<html>bad gateway</html>', 502));
    expect(svc(client).reply(turns), throwsA(isA<AiException>()));
  });

  test('handles an empty choices list', () {
    final client = MockClient((_) async => http.Response(jsonEncode({'choices': []}), 200));
    expect(svc(client).reply(turns), throwsA(isA<AiException>()));
  });

  test('maps network failure to a friendly error', () {
    final client = MockClient((_) async => throw http.ClientException('offline'));
    expect(
      svc(client).reply(turns),
      throwsA(isA<AiException>().having((e) => e.message, 'message', contains('connection'))),
    );
  });
}
