import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/career_profile_models.dart';
import '../../domain/repositories/career_profile_repository.dart';
import '../mappers/career_profile_mapper.dart';

/// Talks to the Job Sensei API's career profile endpoints (Module 1).
///
/// Every route is `/career-profile/me` — the API derives the owner from the
/// bearer token, which `AppInterceptor` attaches, so the user must be signed in
/// before any of this works. A signed-out caller gets a 401 surfaced as an
/// [AppException].
///
/// The section endpoints return only the changed entry plus the recalculated
/// completeness, while this repository's contract returns the whole profile.
/// Rather than patching a local copy — which drifts the moment the server
/// normalises anything — each mutation re-reads the profile. One extra GET per
/// edit, against a screen the user edits a handful of times per session.
class ApiCareerProfileRepository implements CareerProfileRepository {
  ApiCareerProfileRepository({DioClient? client})
      : _client = client ?? DioClient();

  final DioClient _client;
  static const _base = '/career-profile/me';

  /// Path segments the API accepts for `:section`.
  static const _education = 'education';
  static const _experience = 'experience';
  static const _skills = 'skills';
  static const _certifications = 'certifications';
  static const _links = 'portfolio-links';

  @override
  Future<CareerProfile> loadProfile() => _fetchProfile();

  @override
  Future<CareerProfile> saveBasics(ProfileBasicsDraft draft) async {
    final data = await _client.put(
      _base,
      data: CareerProfileMapper.basicsToJson(draft),
    );
    return CareerProfileMapper.profileFromJson(_asMap(data));
  }

  @override
  Future<CareerProfile> savePreferences(JobPreferences preferences) async {
    final data = await _client.put(
      '$_base/preferences',
      data: CareerProfileMapper.preferencesToJson(preferences),
    );
    return CareerProfileMapper.profileFromJson(_asMap(data));
  }

  @override
  Future<CareerProfile> upsertEducation(EducationEntry entry) {
    return _upsert(
      _education,
      entry.id,
      CareerProfileMapper.educationToJson(entry),
    );
  }

  @override
  Future<CareerProfile> removeEducation(String id) => _remove(_education, id);

  @override
  Future<CareerProfile> upsertExperience(WorkExperience entry) {
    return _upsert(
      _experience,
      entry.id,
      CareerProfileMapper.experienceToJson(entry),
    );
  }

  @override
  Future<CareerProfile> removeExperience(String id) => _remove(_experience, id);

  @override
  Future<CareerProfile> upsertSkill(SkillEntry entry) {
    return _upsert(_skills, entry.id, CareerProfileMapper.skillToJson(entry));
  }

  @override
  Future<CareerProfile> removeSkill(String id) => _remove(_skills, id);

  @override
  Future<CareerProfile> upsertCertification(Certification entry) {
    return _upsert(
      _certifications,
      entry.id,
      CareerProfileMapper.certificationToJson(entry),
    );
  }

  @override
  Future<CareerProfile> removeCertification(String id) =>
      _remove(_certifications, id);

  @override
  Future<CareerProfile> upsertPortfolioLink(PortfolioLink link) {
    return _upsert(_links, link.id, CareerProfileMapper.linkToJson(link));
  }

  @override
  Future<CareerProfile> removePortfolioLink(String id) => _remove(_links, id);

  /* -------------------------------------------------------- internals --- */

  Future<CareerProfile> _fetchProfile() async {
    final data = await _client.get(_base);
    return CareerProfileMapper.profileFromJson(_asMap(data));
  }

  /// An empty id means the entry is new, matching the in-memory repository's
  /// convention, so callers do not have to know which backing store is live.
  Future<CareerProfile> _upsert(
    String section,
    String id,
    Map<String, dynamic> body,
  ) async {
    if (id.isEmpty) {
      await _client.post('$_base/sections/$section', data: body);
    } else {
      await _client.put('$_base/sections/$section/$id', data: body);
    }
    return _fetchProfile();
  }

  Future<CareerProfile> _remove(String section, String id) async {
    await _client.delete('$_base/sections/$section/$id');
    return _fetchProfile();
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('Expected a JSON object from the profile API, got $data');
  }
}
