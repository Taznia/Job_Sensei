import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/tracked_application_models.dart';
import '../../domain/repositories/tracked_application_repository.dart';

/// Talks to the Job Sensei API's `/applications` endpoints.
///
/// Reads use the shared list route, so the tracker shows job-board applications
/// alongside manually tracked ones. Writes use the `/tracked` routes, which is
/// what keeps this feature clear of the recruiter permission rules that govern
/// job-board applications.
class ApiTrackedApplicationRepository implements TrackedApplicationRepository {
  ApiTrackedApplicationRepository({DioClient? client})
      : _client = client ?? DioClient();

  final DioClient _client;

  static const _base = '/applications';

  @override
  Future<List<TrackedApplication>> listApplications() async {
    final data = await _client.get(_base);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) =>
            TrackedApplication.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<TrackedApplication> track({
    required String jobTitle,
    required String companyName,
    String? resumeId,
  }) async {
    final data = await _client.post('$_base/tracked', data: {
      'jobTitle': jobTitle,
      'companyName': companyName,
      if (resumeId != null && resumeId.isNotEmpty) 'resumeId': resumeId,
    });
    return TrackedApplication.fromJson(_asMap(data));
  }

  @override
  Future<TrackedApplication> updateStatus(
    String id,
    AppStatus status, {
    DateTime? interviewDate,
  }) async {
    final data = await _client.patch('$_base/$id/tracked-status', data: {
      'status': status.apiValue,
      if (interviewDate != null)
        'interviewDate': interviewDate.toUtc().toIso8601String(),
    });
    return TrackedApplication.fromJson(_asMap(data));
  }

  @override
  Future<void> deleteTracked(String id) async {
    await _client.delete('$_base/$id/tracked');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }
}
