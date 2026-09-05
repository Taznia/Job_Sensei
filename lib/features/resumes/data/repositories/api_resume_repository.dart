import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/resume_models.dart';
import '../../domain/repositories/resume_repository.dart';
import '../mappers/resume_mapper.dart';

/// Talks to the Job Sensei API's `/resumes` endpoints.
///
/// The owner comes from the bearer token that `AppInterceptor` attaches, so no
/// userId appears in any path. `DioClient` has already unwrapped the
/// `{success, data}` envelope by the time these methods see a response.
class ApiResumeRepository implements ResumeRepository {
  ApiResumeRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  static const _base = '/resumes';

  @override
  Future<List<Resume>> listResumes() async {
    final data = await _client.get(_base);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => ResumeMapper.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<Resume> getResume(String id) async {
    final data = await _client.get('$_base/$id');
    return ResumeMapper.fromJson(_asMap(data));
  }

  @override
  Future<Resume> createResume(ResumeDraft draft) async {
    final data = await _client.post(_base, data: ResumeMapper.draftToJson(draft));
    return ResumeMapper.fromJson(_asMap(data));
  }

  @override
  Future<Resume> updateResume(String id, ResumeDraft draft) async {
    // The API exposes PATCH for resumes, and only overwrites the keys sent.
    final data = await _client.patch(
      '$_base/$id',
      data: ResumeMapper.draftToJson(draft),
    );
    return ResumeMapper.fromJson(_asMap(data));
  }

  @override
  Future<void> deleteResume(String id) async {
    await _client.delete('$_base/$id');
  }

  @override
  Future<Resume> duplicateResume(Resume resume) async {
    final draft = ResumeDraft.fromResume(resume);
    final copy = ResumeDraft(
      title: '${draft.title} Copy',
      targetField: draft.targetField,
      template: draft.template,
      fullName: draft.fullName,
      email: draft.email,
      phone: draft.phone,
      location: draft.location,
      linkedin: draft.linkedin,
      portfolio: draft.portfolio,
      summary: draft.summary,
      skills: draft.skills,
      experience: draft.experience,
      education: draft.education,
      projects: draft.projects,
      certifications: draft.certifications,
    );
    return createResume(copy);
  }

  @override
  Future<Resume> setDefault(String id) async {
    final data = await _client.post('$_base/$id/default');
    return ResumeMapper.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }
}
