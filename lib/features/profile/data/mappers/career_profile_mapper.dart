/// Translation between the Job Sensei API's JSON and the career profile domain
/// models. Kept out of the models so those stay free of transport concerns, and
/// out of the repository so the wire format is described in one place.
///
/// Enum values match the backend's string constants. Only [EmploymentType]
/// differs in spelling — Dart uses `fullTime`, the API uses `full-time` — so it
/// gets an explicit table rather than a name-based lookup.
library;

import '../../../../shared/models/career_profile_models.dart';

abstract final class CareerProfileMapper {
  /* ------------------------------------------------------------- enums --- */

  static const _employmentWire = <EmploymentType, String>{
    EmploymentType.fullTime: 'full-time',
    EmploymentType.partTime: 'part-time',
    EmploymentType.contract: 'contract',
    EmploymentType.internship: 'internship',
    EmploymentType.freelance: 'freelance',
  };

  static String employmentToWire(EmploymentType value) =>
      _employmentWire[value]!;

  static EmploymentType employmentFromWire(Object? value) {
    for (final entry in _employmentWire.entries) {
      if (entry.value == value) return entry.key;
    }
    return EmploymentType.fullTime;
  }

  /// For enums whose Dart name already equals the wire value.
  static T _enumFromName<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    if (raw is! String) return fallback;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  /* ------------------------------------------------------------ scalars --- */

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static List<Map<String, dynamic>> _objectList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  /// Mongo subdocuments carry `_id`; the domain models call it `id`.
  static String _id(Map<String, dynamic> json) =>
      (json['_id'] ?? json['id'] ?? '').toString();

  /// Dates go out as `yyyy-MM-dd` — the API parses with `z.coerce.date()`, and
  /// a date-only string avoids a timezone shifting an entry into the wrong
  /// month.
  static String _dateOut(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }

  /* ----------------------------------------------------------- inbound --- */

  static CareerProfile profileFromJson(Map<String, dynamic> json) {
    return CareerProfile(
      // The API keys the profile by the owning user, not by its own _id.
      id: (json['user'] ?? json['_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      headline: (json['headline'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: _string(json['phone']),
      location: _string(json['location']),
      avatarUrl: _string(json['avatarUrl']),
      about: _string(json['about']),
      careerGoals: _string(json['careerGoals']),
      education: _objectList(json['education']).map(educationFromJson).toList(),
      experience:
          _objectList(json['experience']).map(experienceFromJson).toList(),
      skills: _objectList(json['skills']).map(skillFromJson).toList(),
      certifications: _objectList(json['certifications'])
          .map(certificationFromJson)
          .toList(),
      portfolioLinks:
          _objectList(json['portfolioLinks']).map(linkFromJson).toList(),
      preferences: preferencesFromJson(
        json['preferences'] is Map
            ? Map<String, dynamic>.from(json['preferences'] as Map)
            : const {},
      ),
      updatedAt: _date(json['updatedAt']),
    );
  }

  static EducationEntry educationFromJson(Map<String, dynamic> json) {
    return EducationEntry(
      id: _id(json),
      institution: (json['institution'] ?? '').toString(),
      degree: (json['degree'] ?? '').toString(),
      fieldOfStudy: (json['fieldOfStudy'] ?? '').toString(),
      startDate: _date(json['startDate']) ?? DateTime.now(),
      endDate: _date(json['endDate']),
      isCurrent: json['isCurrent'] == true,
      grade: _string(json['grade']),
      description: _string(json['description']),
    );
  }

  static WorkExperience experienceFromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: _id(json),
      company: (json['company'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      employmentType: employmentFromWire(json['employmentType']),
      startDate: _date(json['startDate']) ?? DateTime.now(),
      location: _string(json['location']),
      endDate: _date(json['endDate']),
      isCurrent: json['isCurrent'] == true,
      description: _string(json['description']),
      skills: _stringList(json['skills']),
    );
  }

  static SkillEntry skillFromJson(Map<String, dynamic> json) {
    return SkillEntry(
      id: _id(json),
      name: (json['name'] ?? '').toString(),
      level: _enumFromName(
        SkillLevel.values,
        json['level'],
        SkillLevel.intermediate,
      ),
      yearsOfExperience: _double(json['yearsOfExperience']),
      isVerified: json['isVerified'] == true,
    );
  }

  static Certification certificationFromJson(Map<String, dynamic> json) {
    return Certification(
      id: _id(json),
      name: (json['name'] ?? '').toString(),
      issuer: (json['issuer'] ?? '').toString(),
      issueDate: _date(json['issueDate']) ?? DateTime.now(),
      expiryDate: _date(json['expiryDate']),
      credentialId: _string(json['credentialId']),
      credentialUrl: _string(json['credentialUrl']),
    );
  }

  static PortfolioLink linkFromJson(Map<String, dynamic> json) {
    return PortfolioLink(
      id: _id(json),
      label: (json['label'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      kind: _enumFromName(
        PortfolioLinkKind.values,
        json['kind'],
        PortfolioLinkKind.other,
      ),
    );
  }

  static JobPreferences preferencesFromJson(Map<String, dynamic> json) {
    final salary = json['salary'];
    return JobPreferences(
      preferredRoles: _stringList(json['preferredRoles']),
      preferredLocations: _stringList(json['preferredLocations']),
      workModes: _stringList(json['workModes'])
          .map((v) => _enumFromName(WorkMode.values, v, WorkMode.onsite))
          .toList(),
      employmentTypes:
          _stringList(json['employmentTypes']).map(employmentFromWire).toList(),
      salary: salary is Map
          ? SalaryExpectation(
              min: (salary['min'] as num?)?.round() ?? 0,
              max: (salary['max'] as num?)?.round() ?? 0,
              currency: (salary['currency'] ?? 'BDT').toString(),
              period: _enumFromName(
                SalaryPeriod.values,
                salary['period'],
                SalaryPeriod.monthly,
              ),
            )
          : null,
      openToRelocation: json['openToRelocation'] == true,
      availableFrom: _date(json['availableFrom']),
    );
  }

  /* ---------------------------------------------------------- outbound --- */

  static Map<String, dynamic> basicsToJson(ProfileBasicsDraft draft) {
    // Nulls are sent explicitly: the API reads null as "clear this field", so
    // omitting them would make a cleared phone number impossible to save.
    return {
      'fullName': draft.fullName,
      'headline': draft.headline,
      'email': draft.email,
      'phone': draft.phone,
      'location': draft.location,
      'about': draft.about,
      'careerGoals': draft.careerGoals,
      'avatarUrl': draft.avatarUrl,
    };
  }

  static Map<String, dynamic> preferencesToJson(JobPreferences prefs) {
    return {
      'preferredRoles': prefs.preferredRoles,
      'preferredLocations': prefs.preferredLocations,
      'workModes': prefs.workModes.map((m) => m.name).toList(),
      'employmentTypes': prefs.employmentTypes.map(employmentToWire).toList(),
      'salary': prefs.salary == null
          ? null
          : {
              'min': prefs.salary!.min,
              'max': prefs.salary!.max,
              'currency': prefs.salary!.currency,
              'period': prefs.salary!.period.name,
            },
      'openToRelocation': prefs.openToRelocation,
      'availableFrom': prefs.availableFrom == null
          ? null
          : _dateOut(prefs.availableFrom!),
    };
  }

  static Map<String, dynamic> educationToJson(EducationEntry entry) {
    return {
      'institution': entry.institution,
      'degree': entry.degree,
      'fieldOfStudy': entry.fieldOfStudy,
      'startDate': _dateOut(entry.startDate),
      'endDate': entry.endDate == null ? null : _dateOut(entry.endDate!),
      'isCurrent': entry.isCurrent,
      'grade': entry.grade,
      'description': entry.description,
    };
  }

  static Map<String, dynamic> experienceToJson(WorkExperience entry) {
    return {
      'company': entry.company,
      'title': entry.title,
      'employmentType': employmentToWire(entry.employmentType),
      'startDate': _dateOut(entry.startDate),
      'endDate': entry.endDate == null ? null : _dateOut(entry.endDate!),
      'isCurrent': entry.isCurrent,
      'location': entry.location,
      'description': entry.description,
      'skills': entry.skills,
    };
  }

  static Map<String, dynamic> skillToJson(SkillEntry entry) {
    return {
      'name': entry.name,
      'level': entry.level.name,
      'yearsOfExperience': entry.yearsOfExperience,
      'isVerified': entry.isVerified,
    };
  }

  static Map<String, dynamic> certificationToJson(Certification entry) {
    return {
      'name': entry.name,
      'issuer': entry.issuer,
      'issueDate': _dateOut(entry.issueDate),
      'expiryDate': entry.expiryDate == null
          ? null
          : _dateOut(entry.expiryDate!),
      'credentialId': entry.credentialId,
      'credentialUrl': entry.credentialUrl,
    };
  }

  static Map<String, dynamic> linkToJson(PortfolioLink entry) {
    return {
      'label': entry.label,
      'url': entry.url,
      'kind': entry.kind.name,
    };
  }
}
