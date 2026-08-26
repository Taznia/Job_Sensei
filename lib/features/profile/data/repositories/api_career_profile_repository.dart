import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/career_profile_models.dart';
import '../../domain/repositories/career_profile_repository.dart';

class ApiCareerProfileRepository implements CareerProfileRepository {
  ApiCareerProfileRepository({DioClient? client})
      : _client = client ?? DioClient();

  final DioClient _client;
  CareerProfile? _profile;

  @override
  Future<CareerProfile> loadProfile() async {
    final json = await _client.get('/users/me') as Map<String, dynamic>;
    return _store(json);
  }

  @override
  Future<CareerProfile> saveBasics(ProfileBasicsDraft draft) => _patch({
        'name': draft.fullName,
        'headline': draft.headline,
        'bio': draft.about ?? '',
        'location': draft.location ?? '',
        'avatarUrl': draft.avatarUrl ?? '',
        'phone': draft.phone ?? '',
        'careerGoals': draft.careerGoals ?? '',
      });

  @override
  Future<CareerProfile> savePreferences(JobPreferences preferences) => _patch({
        'targetRole': preferences.preferredRoles.firstOrNull ?? '',
        'preferences': _preferencesToJson(preferences),
      });

  @override
  Future<CareerProfile> upsertEducation(EducationEntry entry) {
    final value = entry.id.isEmpty
        ? EducationEntry(
            id: _newId('education'),
            institution: entry.institution,
            degree: entry.degree,
            fieldOfStudy: entry.fieldOfStudy,
            startDate: entry.startDate,
            endDate: entry.endDate,
            isCurrent: entry.isCurrent,
            grade: entry.grade,
            description: entry.description,
          )
        : entry;
    final next = _upsert(_requireProfile().education, value, (item) => item.id);
    return _patch({'education': next.map(_educationToJson).toList()});
  }

  @override
  Future<CareerProfile> removeEducation(String id) => _patch({
        'education': _requireProfile()
            .education
            .where((item) => item.id != id)
            .map(_educationToJson)
            .toList(),
      });

  @override
  Future<CareerProfile> upsertExperience(WorkExperience entry) {
    final value = entry.id.isEmpty
        ? WorkExperience(
            id: _newId('experience'),
            company: entry.company,
            title: entry.title,
            employmentType: entry.employmentType,
            startDate: entry.startDate,
            location: entry.location,
            endDate: entry.endDate,
            isCurrent: entry.isCurrent,
            description: entry.description,
            skills: entry.skills,
          )
        : entry;
    final next = _upsert(_requireProfile().experience, value, (item) => item.id);
    return _patch({'experience': next.map(_experienceToJson).toList()});
  }

  @override
  Future<CareerProfile> removeExperience(String id) => _patch({
        'experience': _requireProfile()
            .experience
            .where((item) => item.id != id)
            .map(_experienceToJson)
            .toList(),
      });

  @override
  Future<CareerProfile> upsertSkill(SkillEntry entry) {
    final value = entry.id.isEmpty
        ? SkillEntry(
            id: _newId('skill'),
            name: entry.name,
            level: entry.level,
            yearsOfExperience: entry.yearsOfExperience,
            isVerified: entry.isVerified,
          )
        : entry;
    final next = _upsert(_requireProfile().skills, value, (item) => item.id);
    return _patch({'skills': next.map(_skillToJson).toList()});
  }

  @override
  Future<CareerProfile> removeSkill(String id) => _patch({
        'skills': _requireProfile()
            .skills
            .where((item) => item.id != id)
            .map(_skillToJson)
            .toList(),
      });

  @override
  Future<CareerProfile> upsertCertification(Certification entry) {
    final value = entry.id.isEmpty
        ? Certification(
            id: _newId('certification'),
            name: entry.name,
            issuer: entry.issuer,
            issueDate: entry.issueDate,
            expiryDate: entry.expiryDate,
            credentialId: entry.credentialId,
            credentialUrl: entry.credentialUrl,
          )
        : entry;
    final next =
        _upsert(_requireProfile().certifications, value, (item) => item.id);
    return _patch({'certifications': next.map(_certificationToJson).toList()});
  }

  @override
  Future<CareerProfile> removeCertification(String id) => _patch({
        'certifications': _requireProfile()
            .certifications
            .where((item) => item.id != id)
            .map(_certificationToJson)
            .toList(),
      });

  @override
  Future<CareerProfile> upsertPortfolioLink(PortfolioLink link) {
    final value = link.id.isEmpty
        ? PortfolioLink(
            id: _newId('portfolio'),
            label: link.label,
            url: link.url,
            kind: link.kind,
          )
        : link;
    final next =
        _upsert(_requireProfile().portfolioLinks, value, (item) => item.id);
    return _patch({'portfolioLinks': next.map(_portfolioToJson).toList()});
  }

  @override
  Future<CareerProfile> removePortfolioLink(String id) => _patch({
        'portfolioLinks': _requireProfile()
            .portfolioLinks
            .where((item) => item.id != id)
            .map(_portfolioToJson)
            .toList(),
      });

  Future<CareerProfile> _patch(Map<String, dynamic> body) async {
    final json =
        await _client.patch('/users/me', data: body) as Map<String, dynamic>;
    return _store(json);
  }

  CareerProfile _store(Map<String, dynamic> json) {
    _profile = CareerProfile(
      id: json['id'] as String,
      fullName: json['name'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: _nullable(json['phone']),
      location: _nullable(json['location']),
      avatarUrl: _nullable(json['avatarUrl']),
      about: _nullable(json['bio']),
      careerGoals: _nullable(json['careerGoals']),
      education: _maps(json['education']).map(_educationFromJson).toList(),
      experience: _maps(json['experience']).map(_experienceFromJson).toList(),
      skills: _maps(json['skills']).map(_skillFromJson).toList(),
      certifications:
          _maps(json['certifications']).map(_certificationFromJson).toList(),
      portfolioLinks:
          _maps(json['portfolioLinks']).map(_portfolioFromJson).toList(),
      preferences: _preferencesFromJson(
        json['preferences'],
        json['targetRole'] as String? ?? '',
      ),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
    return _profile!;
  }

  CareerProfile _requireProfile() {
    final profile = _profile;
    if (profile == null) {
      throw StateError('Load the profile before saving changes.');
    }
    return profile;
  }

  static List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String _id(Map<String, dynamic> json, String prefix) =>
      (json['id'] ?? json['_id'] ?? _newId(prefix)).toString();

  static String _newId(String prefix) =>
      prefix + '-' + DateTime.now().microsecondsSinceEpoch.toString();

  static SkillLevel _skillLevel(num value) {
    if (value >= 90) return SkillLevel.expert;
    if (value >= 70) return SkillLevel.advanced;
    if (value >= 40) return SkillLevel.intermediate;
    return SkillLevel.beginner;
  }

  static int _skillPercent(SkillLevel value) => switch (value) {
        SkillLevel.beginner => 25,
        SkillLevel.intermediate => 50,
        SkillLevel.advanced => 75,
        SkillLevel.expert => 95,
      };

  static SkillEntry _skillFromJson(Map<String, dynamic> json) => SkillEntry(
        id: _id(json, 'skill'),
        name: json['name'] as String? ?? '',
        level: _skillLevel(json['currentLevel'] as num? ?? 0),
        yearsOfExperience: (json['yearsOfExperience'] as num?)?.toDouble(),
        isVerified: json['isVerified'] as bool? ?? false,
      );

  static Map<String, dynamic> _skillToJson(SkillEntry item) => {
        'name': item.name,
        'currentLevel': _skillPercent(item.level),
        'category': 'Career Skill',
        if (item.yearsOfExperience != null)
          'yearsOfExperience': item.yearsOfExperience,
        'isVerified': item.isVerified,
      };

  static EducationEntry _educationFromJson(Map<String, dynamic> json) =>
      EducationEntry(
        id: _id(json, 'education'),
        institution: json['institution'] as String? ?? '',
        degree: json['degree'] as String? ?? '',
        fieldOfStudy: json['fieldOfStudy'] as String? ?? '',
        startDate: _date(json['startDate']),
        endDate: _optionalDate(json['endDate']),
        isCurrent: json['isCurrent'] as bool? ?? false,
        grade: _nullable(json['grade']),
        description: _nullable(json['description']),
      );

  static Map<String, dynamic> _educationToJson(EducationEntry item) => {
        'id': item.id,
        'institution': item.institution,
        'degree': item.degree,
        'fieldOfStudy': item.fieldOfStudy,
        'startDate': item.startDate.toIso8601String(),
        if (item.endDate != null) 'endDate': item.endDate!.toIso8601String(),
        'isCurrent': item.isCurrent,
        'grade': item.grade,
        'description': item.description,
      };

  static WorkExperience _experienceFromJson(Map<String, dynamic> json) =>
      WorkExperience(
        id: _id(json, 'experience'),
        company: json['company'] as String? ?? '',
        title: json['title'] as String? ?? '',
        employmentType: _employmentType(json['employmentType'] as String?),
        startDate: _date(json['startDate']),
        location: _nullable(json['location']),
        endDate: _optionalDate(json['endDate']),
        isCurrent: json['isCurrent'] as bool? ?? false,
        description: _nullable(json['description']),
        skills: (json['skills'] as List<dynamic>? ?? const []).cast<String>(),
      );

  static Map<String, dynamic> _experienceToJson(WorkExperience item) => {
        'id': item.id,
        'company': item.company,
        'title': item.title,
        'employmentType': item.employmentType.name,
        'startDate': item.startDate.toIso8601String(),
        'location': item.location,
        if (item.endDate != null) 'endDate': item.endDate!.toIso8601String(),
        'isCurrent': item.isCurrent,
        'description': item.description,
        'skills': item.skills,
      };

  static EmploymentType _employmentType(String? value) => switch (value) {
        'partTime' => EmploymentType.partTime,
        'contract' => EmploymentType.contract,
        'internship' => EmploymentType.internship,
        'freelance' => EmploymentType.freelance,
        _ => EmploymentType.fullTime,
      };

  static Certification _certificationFromJson(Map<String, dynamic> json) =>
      Certification(
        id: _id(json, 'certification'),
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        issueDate: _date(json['issueDate']),
        expiryDate: _optionalDate(json['expiryDate']),
        credentialId: _nullable(json['credentialId']),
        credentialUrl: _nullable(json['credentialUrl']),
      );

  static Map<String, dynamic> _certificationToJson(Certification item) => {
        'id': item.id,
        'name': item.name,
        'issuer': item.issuer,
        'issueDate': item.issueDate.toIso8601String(),
        if (item.expiryDate != null)
          'expiryDate': item.expiryDate!.toIso8601String(),
        'credentialId': item.credentialId,
        'credentialUrl': item.credentialUrl,
      };

  static PortfolioLink _portfolioFromJson(Map<String, dynamic> json) =>
      PortfolioLink(
        id: _id(json, 'portfolio'),
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
        kind: _portfolioKind(json['kind'] as String?),
      );

  static Map<String, dynamic> _portfolioToJson(PortfolioLink item) => {
        'id': item.id,
        'label': item.label,
        'url': item.url,
        'kind': item.kind.name,
      };

  static PortfolioLinkKind _portfolioKind(String? value) => switch (value) {
        'website' => PortfolioLinkKind.website,
        'github' => PortfolioLinkKind.github,
        'linkedin' => PortfolioLinkKind.linkedin,
        'behance' => PortfolioLinkKind.behance,
        'dribbble' => PortfolioLinkKind.dribbble,
        _ => PortfolioLinkKind.other,
      };

  static JobPreferences _preferencesFromJson(dynamic value, String targetRole) {
    final json = value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    final salaryJson = json['salary'] is Map
        ? Map<String, dynamic>.from(json['salary'] as Map)
        : null;
    final savedRoles =
        (json['preferredRoles'] as List<dynamic>? ?? const []).cast<String>();
    return JobPreferences(
      preferredRoles:
          savedRoles.isEmpty && targetRole.isNotEmpty ? [targetRole] : savedRoles,
      preferredLocations:
          (json['preferredLocations'] as List<dynamic>? ?? const [])
              .cast<String>(),
      workModes: (json['workModes'] as List<dynamic>? ?? const [])
          .map((item) => WorkMode.values.firstWhere(
                (value) => value.name == item,
                orElse: () => WorkMode.hybrid,
              ))
          .toList(),
      employmentTypes:
          (json['employmentTypes'] as List<dynamic>? ?? const [])
              .map((item) => _employmentType(item.toString()))
              .toList(),
      salary: salaryJson == null
          ? null
          : SalaryExpectation(
              min: (salaryJson['min'] as num?)?.toInt() ?? 0,
              max: (salaryJson['max'] as num?)?.toInt() ?? 0,
              currency: salaryJson['currency'] as String? ?? 'BDT',
              period: SalaryPeriod.values.firstWhere(
                (value) => value.name == salaryJson['period'],
                orElse: () => SalaryPeriod.monthly,
              ),
            ),
      openToRelocation: json['openToRelocation'] as bool? ?? false,
      availableFrom: _optionalDate(json['availableFrom']),
    );
  }

  static Map<String, dynamic> _preferencesToJson(JobPreferences item) => {
        'preferredRoles': item.preferredRoles,
        'preferredLocations': item.preferredLocations,
        'workModes': item.workModes.map((value) => value.name).toList(),
        'employmentTypes':
            item.employmentTypes.map((value) => value.name).toList(),
        if (item.salary != null)
          'salary': {
            'min': item.salary!.min,
            'max': item.salary!.max,
            'currency': item.salary!.currency,
            'period': item.salary!.period.name,
          },
        'openToRelocation': item.openToRelocation,
        if (item.availableFrom != null)
          'availableFrom': item.availableFrom!.toIso8601String(),
      };

  static DateTime _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime? _optionalDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');

  static List<T> _upsert<T>(
    List<T> source,
    T value,
    String Function(T) idOf,
  ) {
    final next = [...source];
    final index = next.indexWhere((item) => idOf(item) == idOf(value));
    if (index == -1) {
      next.add(value);
    } else {
      next[index] = value;
    }
    return next;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}