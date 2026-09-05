import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/resume_match_models.dart';
import '../../domain/repositories/resume_match_repository.dart';

/// Talks to the Job Sensei API's `/ai/resume-match` endpoints.
///
/// The Gemini call happens on the server, so no API key is compiled into this
/// app. An analysis can take a while, which is why the timeout is raised well
/// above `DioClient`'s 20-second default for this one request.
class ApiResumeMatchRepository implements ResumeMatchRepository {
  ApiResumeMatchRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  static const _base = '/ai/resume-match';

  /// Model responses regularly run past 20s on a long job description.
  static const _analysisTimeout = Duration(seconds: 90);

  @override
  Future<ResumeMatch> analyse({
    required String resumeId,
    required String jobDescription,
  }) async {
    final data = await _client.post(
      _base,
      data: {'resumeId': resumeId, 'jobDescription': jobDescription},
      options: Options(
        receiveTimeout: _analysisTimeout,
        sendTimeout: _analysisTimeout,
      ),
    );

    return ResumeMatch.fromJson(_asMap(data));
  }

  @override
  Future<List<ResumeMatch>> history({String? resumeId}) async {
    final data = await _client.get(
      '$_base/history',
      query: {
        if (resumeId != null && resumeId.isNotEmpty) 'resumeId': resumeId,
      },
    );
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => ResumeMatch.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete('$_base/$id');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }
}
