import 'dart:convert';

import 'package:http/http.dart' as http;

abstract interface class ChatService {
  Future<String> sendMessage(String message);
}

class GeminiChatService implements ChatService {
  GeminiChatService({http.Client? client}) : _client = client ?? http.Client();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final http.Client _client;

  @override
  Future<String> sendMessage(String message) async {
    if (_apiKey.isEmpty) return _demoReply(message);

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.0-flash:generateContent?key=$_apiKey',
    );
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {
                  'text':
                      'You are Job Sensei, a concise and encouraging career '
                          'coach. Give practical, ethical job-search advice.',
                },
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': message},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini request failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    final content =
        candidates?.firstOrNull?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.firstOrNull?['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }
    return text.trim();
  }

  String _demoReply(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('interview')) {
      return 'Let\'s prepare in three steps: study the role, write five STAR '
          'stories from your experience, and practice a 60-second introduction. '
          'Would you like me to create interview questions for your target role?';
    }
    if (normalized.contains('resume') || normalized.contains('cv')) {
      return 'Start each bullet with a strong action verb, describe what you did, '
          'and finish with a measurable result. Tailor the top third of the resume '
          'to the job description and keep the formatting ATS-friendly.';
    }
    if (normalized.contains('skill')) {
      return 'Choose one high-impact gap first, complete a small project with it, '
          'then document the result on your resume. Your Skill Gap tab can help '
          'you decide which skill should come first.';
    }
    return 'I can help with resumes, interviews, career planning, skill gaps, and '
        'job-search strategy. Tell me your target role and the challenge you are '
        'facing, and we will turn it into a practical next step.';
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
