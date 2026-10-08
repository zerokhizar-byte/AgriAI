import 'dart:convert';

import 'package:http/http.dart' as http;

class AgriAiAssistantResponse {
  final String text;

  const AgriAiAssistantResponse({
    required this.text,
  });
}

class AgriAiAssistantService {
  AgriAiAssistantService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _backendUrl =
      String.fromEnvironment('AGRIAI_API_URL');

  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static const String _geminiModel =
      String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  static const Duration _timeout =
      Duration(seconds: 35);

  Future<AgriAiAssistantResponse> sendMessage({
    required String question,
    required List<AgriAiChatTurn> history,
    String? weatherContext,
  }) async {
    final String cleanQuestion = question.trim();

    if (cleanQuestion.isEmpty) {
      throw const AgriAiAssistantException(
        'Please enter a question.',
      );
    }

    if (_backendUrl.trim().isNotEmpty) {
      return _sendToBackend(
        question: cleanQuestion,
        history: history,
        weatherContext: weatherContext,
      );
    }

    if (_geminiApiKey.trim().isNotEmpty) {
      return _sendToGemini(
        question: cleanQuestion,
        history: history,
        weatherContext: weatherContext,
      );
    }

    throw const AgriAiAssistantException(
      'AgriAI AI service is not configured yet. '
      'Set AGRIAI_API_URL for the secure backend, or '
      'GEMINI_API_KEY for development testing.',
    );
  }

  Future<AgriAiAssistantResponse> _sendToBackend({
    required String question,
    required List<AgriAiChatTurn> history,
    String? weatherContext,
  }) async {
    final Uri uri = Uri.parse(_backendUrl);

    final Map<String, dynamic> payload =
        <String, dynamic>{
      'message': question,
      'history': history
          .map((AgriAiChatTurn turn) => turn.toJson())
          .toList(),
      'context': <String, dynamic>{
        'weather': weatherContext ?? '',
        'assistant': 'AgriAI',
        'domain': 'precision agriculture',
      },
    };

    try {
      final http.Response response =
          await _client
              .post(
                uri,
                headers: const <String, String>{
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(payload),
              )
              .timeout(_timeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw AgriAiAssistantException(
          'AI server returned HTTP ${response.statusCode}.',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const AgriAiAssistantException(
          'AI server returned an invalid response.',
        );
      }

      final String text = _extractText(decoded);

      if (text.isEmpty) {
        throw const AgriAiAssistantException(
          'AI server returned an empty response.',
        );
      }

      return AgriAiAssistantResponse(text: text);
    } on AgriAiAssistantException {
      rethrow;
    } catch (error) {
      throw AgriAiAssistantException(
        'Unable to connect to the AgriAI AI service: $error',
      );
    }
  }

  Future<AgriAiAssistantResponse> _sendToGemini({
    required String question,
    required List<AgriAiChatTurn> history,
    String? weatherContext,
  }) async {
    final Uri uri = Uri.parse(
      'https://generativelanguage.googleapis.com/'
      'v1beta/models/$_geminiModel:generateContent',
    );

    final List<Map<String, dynamic>> contents =
        <Map<String, dynamic>>[];

    for (final AgriAiChatTurn turn in history) {
      if (turn.text.trim().isEmpty) {
        continue;
      }

      contents.add(
        <String, dynamic>{
          'role': turn.role == AgriAiChatRole.user
              ? 'user'
              : 'model',
          'parts': <Map<String, String>>[
            <String, String>{
              'text': turn.text.trim(),
            },
          ],
        },
      );
    }

    contents.add(
      <String, dynamic>{
        'role': 'user',
        'parts': <Map<String, String>>[
          <String, String>{
            'text': question,
          },
        ],
      },
    );

    final String weather = weatherContext?.trim() ?? '';

    final String systemInstruction = '''
You are AgriAI, an agriculture-focused AI assistant for farmers.

Give practical, clear farming guidance about crops, soil, irrigation,
fertilizer, pests, disease and weather. Use simple language suitable for
farmers. Ask for missing crop, growth stage, soil or location details when
they materially affect the answer.

Never invent measurements, diagnoses, pesticide doses, or guaranteed yields.
For pesticide or fertilizer recommendations, remind the user to follow local
label directions, crop registration, soil tests and local agricultural
guidance. Distinguish general guidance from advice that requires a local
agronomist or laboratory test.

Keep answers concise but useful. Do not claim that you personally inspected
a crop unless an image was actually provided.

Current Home weather context:
${weather.isEmpty ? 'Not available.' : weather}
''';

    final Map<String, dynamic> payload =
        <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, String>>[
          <String, String>{
            'text': systemInstruction,
          },
        ],
      },
      'contents': contents,
      'generationConfig': <String, dynamic>{
        'temperature': 0.35,
        'maxOutputTokens': 700,
      },
    };

    try {
      final http.Response response =
          await _client
              .post(
                uri,
                headers: <String, String>{
                  'Content-Type': 'application/json',
                  'x-goog-api-key': _geminiApiKey.trim(),
                },
                body: jsonEncode(payload),
              )
              .timeout(_timeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String detail = '';

        try {
          final dynamic errorBody = jsonDecode(response.body);

          if (errorBody is Map<String, dynamic>) {
            final dynamic error = errorBody['error'];

            if (error is Map<String, dynamic>) {
              detail = '${error['message'] ?? ''}'.trim();
            }
          }
        } catch (_) {}

        throw AgriAiAssistantException(
          detail.isEmpty
              ? 'Gemini returned HTTP ${response.statusCode}.'
              : detail,
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const AgriAiAssistantException(
          'Gemini returned an invalid response.',
        );
      }

      final String text = _extractGeminiText(decoded);

      if (text.isEmpty) {
        throw const AgriAiAssistantException(
          'Gemini returned an empty response.',
        );
      }

      return AgriAiAssistantResponse(text: text);
    } on AgriAiAssistantException {
      rethrow;
    } catch (error) {
      throw AgriAiAssistantException(
        'Unable to reach the AI service: $error',
      );
    }
  }

  String _extractText(Map<String, dynamic> data) {
    for (final String value in <String>[
      '${data['text'] ?? ''}',
      '${data['response'] ?? ''}',
      '${data['answer'] ?? ''}',
      '${data['message'] ?? ''}',
    ]) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  String _extractGeminiText(Map<String, dynamic> data) {
    final dynamic candidates = data['candidates'];

    if (candidates is! List) {
      return '';
    }

    for (final dynamic candidate in candidates) {
      if (candidate is! Map) {
        continue;
      }

      final dynamic content = candidate['content'];

      if (content is! Map) {
        continue;
      }

      final dynamic parts = content['parts'];

      if (parts is! List) {
        continue;
      }

      final StringBuffer buffer = StringBuffer();

      for (final dynamic part in parts) {
        if (part is Map) {
          final String partText = '${part['text'] ?? ''}';

          if (partText.trim().isNotEmpty) {
            if (buffer.isNotEmpty) {
              buffer.write('\n');
            }

            buffer.write(partText.trim());
          }
        }
      }

      final String result = buffer.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  void dispose() {
    _client.close();
  }
}

enum AgriAiChatRole {
  user,
  assistant,
}

class AgriAiChatTurn {
  final AgriAiChatRole role;
  final String text;

  const AgriAiChatTurn({
    required this.role,
    required this.text,
  });

  Map<String, String> toJson() {
    return <String, String>{
      'role': role == AgriAiChatRole.user
          ? 'user'
          : 'assistant',
      'text': text,
    };
  }
}

class AgriAiAssistantException implements Exception {
  final String message;

  const AgriAiAssistantException(this.message);

  @override
  String toString() => message;
}
