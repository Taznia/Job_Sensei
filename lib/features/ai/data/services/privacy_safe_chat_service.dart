import '../../../../shared/models/chat_message.dart';
import 'gemini_chat_service.dart';

/// Local career coach used until backend-to-Gemini data forwarding is
/// explicitly enabled. It prevents API keys and chat payloads leaving Flutter.
class PrivacySafeChatService implements ChatService {
  @override
  bool get isConfigured => false;

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    List<PendingChatAttachment> attachments = const [],
  }) async {
    if (attachments.isNotEmpty) {
      return 'Your attachment remains on this device. Live file analysis is '
          'disabled until backend Gemini forwarding is approved.';
    }
    final normalized = message.toLowerCase();
    if (normalized.contains('interview')) {
      return 'Study the role, prepare five STAR stories, and practice a '
          'one-minute introduction. I can help you draft practice questions.';
    }
    if (normalized.contains('resume') || normalized.contains('cv')) {
      return 'Use action verbs, include measurable outcomes, and tailor the '
          'first half of the resume to the target job.';
    }
    if (normalized.contains('skill') || normalized.contains('learn')) {
      return 'Open a job, review its high-priority gaps, and start one '
          'published learning path before moving to the next skill.';
    }
    return 'I can help with job matching, skill gaps, learning plans, resumes, '
        'and interviews. Live Gemini is waiting for privacy approval.';
  }
}
