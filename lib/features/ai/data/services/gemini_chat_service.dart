import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../shared/models/chat_message.dart';

class GeminiException implements Exception {
  GeminiException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ChatService {
  bool get isConfigured;

  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    List<PendingChatAttachment> attachments,
  });
}

/// Calls Gemini from the Flutter app. Chat never goes through the Job Sensei API.
class GeminiChatService implements ChatService {
  GeminiChatService({http.Client? client}) : _client = client ?? http.Client();

  /// `gemini-2.0-flash` was shut down in June 2026.
  static const _fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];

  final http.Client _client;
  static String? _workingModel;

  @override
  bool get isConfigured => AppConfig.isGeminiConfigured;

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    List<PendingChatAttachment> attachments = const [],
  }) async {
    if (!isConfigured) {
      return _offlineReply(message, attachments);
    }

    final inline = attachments.where(_supportsInlineData).toList();
    final skipped = attachments.where((item) => !_supportsInlineData(item));
    final skippedNote = skipped.isEmpty
        ? ''
        : ' The user also attached ${skipped.map((item) => item.name).join(', ')} '
            'but those files could not be sent (unsupported type or missing bytes). '
            'Give useful advice from the filename only.';

    final contents = history
        .where((item) => item.text.trim().isNotEmpty)
        .map(
          (item) => {
            'role': item.author == MessageAuthor.user ? 'user' : 'model',
            'parts': [
              {'text': item.text},
            ],
          },
        )
        .toList();

    final prompt = message.trim().isEmpty
        ? 'Please review the attached file and give career-focused feedback.'
        : message.trim();

    contents.add({
      'role': 'user',
      'parts': [
        {'text': '$prompt$skippedNote'},
        ...inline.map(
          (attachment) => {
            'inline_data': {
              'mime_type': attachment.mimeType,
              'data': base64Encode(attachment.bytes!),
            },
          },
        ),
      ],
    });

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {
            'text': 'You are Job Sensei (Momo), a concise and encouraging '
                'career coach. Give practical, ethical job-search advice. '
                'When a file is attached, explain what you reviewed and never '
                'claim to have read unsupported file content. '
                'Write in plain text only. Do not use markdown: no asterisks, '
                'no bold, no italic, no # headings, no backticks, no ** or __. '
                'Use short paragraphs and numbered lists like 1. 2. 3. '
                'If you need a list, start lines with a dash and a space.',
          },
        ],
      },
      'contents': contents,
    });

    try {
      return await _generateWithFallback(body);
    } on GeminiException {
      rethrow;
    } on TimeoutException {
      throw GeminiException(
        'Gemini timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw GeminiException(
        'Could not reach Gemini. Check your internet connection.',
      );
    } on FormatException {
      throw GeminiException('Gemini sent a response this app could not read.');
    }
  }

  Future<String> _generateWithFallback(String body) async {
    final models = <String>[
      if (_workingModel != null) _workingModel!,
      AppConfig.geminiModel,
      ..._fallbackModels,
    ];
    final tried = <String>{};
    http.Response? lastNotFound;

    for (final model in models) {
      if (!tried.add(model)) continue;
      final response = await _postModel(model, body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _workingModel = model;
        return _textFrom(response.body);
      }
      if (response.statusCode == 404) {
        lastNotFound = response;
        continue;
      }
      throw GeminiException(
        _messageForHttp(response.statusCode, response.body),
      );
    }

    throw GeminiException(
      _messageForHttp(lastNotFound?.statusCode ?? 404, lastNotFound?.body ?? ''),
    );
  }

  Future<http.Response> _postModel(String model, String body) {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );
    return _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AppConfig.geminiApiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));
  }

  String _textFrom(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    final content =
        candidates?.firstOrNull?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts
        ?.map((part) {
          if (part is Map<String, dynamic>) {
            return part['text'] as String? ?? '';
          }
          return '';
        })
        .join()
        .trim();
    if (text == null || text.isEmpty) {
      throw GeminiException('Gemini returned an empty response. Try again.');
    }
    return _toPlainText(text);
  }

  /// Strips markdown so chat bubbles never show **bold**, `code`, or # headings.
  String _toPlainText(String input) {
    var text = input.replaceAll('\r\n', '\n');
    text = text.replaceAll(RegExp(r'```[\w-]*\n?'), '');
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match[1]!);
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    text = text.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'),
      (match) => match[1]!.trim(),
    );
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (match) => match[1]!,
    );
    text = text.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (match) => match[1]!);
    text = text.replaceAllMapped(
      RegExp(r'\*\*\*([^*]+)\*\*\*'),
      (match) => match[1]!,
    );
    text = text.replaceAllMapped(RegExp(r'___([^_]+)___'), (match) => match[1]!);
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match[1]!);
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (match) => match[1]!);
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'),
      (match) => match[1]!,
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<!_)_([^_\n]+)_(?!_)'),
      (match) => match[1]!,
    );
    text = text.replaceAll(RegExp(r'^>\s?', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ');
    text = text.replaceAll('**', '');
    text = text.replaceAll('__', '');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  String _messageForHttp(int statusCode, String body) {
    final apiMessage = _apiErrorMessage(body);
    switch (statusCode) {
      case 400:
        return apiMessage ??
            'Gemini rejected that request. Try a shorter message.';
      case 401:
      case 403:
        return 'Gemini rejected the API key. Create a Gemini API key at '
            'https://aistudio.google.com/apikey and put it in .env as GEMINI_API_KEY.';
      case 404:
        return apiMessage ??
            'No Gemini chat model is available for this key. Create a Google AI Studio '
            'key at https://aistudio.google.com/apikey (it should start with AIza).';
      case 429:
        return 'Gemini rate limit reached. Wait a moment and try again.';
      default:
        return apiMessage ??
            'Gemini request failed ($statusCode). Please try again.';
    }
  }

  String? _apiErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['error'] is Map) {
        final message = data['error']['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  bool _supportsInlineData(PendingChatAttachment attachment) {
    if (attachment.bytes == null || attachment.bytes!.isEmpty) return false;
    return attachment.mimeType.startsWith('image/') ||
        attachment.mimeType == 'application/pdf' ||
        attachment.mimeType == 'text/plain';
  }

  String _offlineReply(
    String message,
    List<PendingChatAttachment> attachments,
  ) {
    final normalized = message.toLowerCase();
    if (attachments.isNotEmpty) {
      final names = attachments.map((item) => item.name).join(', ');
      return 'I can see $names on this device, but I cannot analyze the file '
          'until you add GEMINI_API_KEY to the .env file in the project root. '
          'Tell me what you want reviewed: impact, clarity, or interview fit.';
    }
    if (normalized.contains('interview')) {
      return 'Let\'s prepare in three steps: study the role, write five STAR '
          'stories from your experience, and practice a 60-second introduction. '
          'Would you like me to create questions for your target role?';
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
    return 'I am running in offline coach mode because GEMINI_API_KEY is missing '
        'from the .env file. I can still help with resumes, interviews, and '
        'skill-gap planning. Tell me your target role and the challenge you are facing.';
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
