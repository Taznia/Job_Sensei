/// Models for the career profile — the base record the rest of Job Sensei reads
/// from. Job matching, resume suggestions, and skill-gap analysis all derive
/// their inputs from [CareerProfile], so treat it as the source of truth rather
/// than duplicating any of these fields into feature-local state.
library;

enum SkillLevel { beginner, intermediate, advanced, expert }

enum WorkMode { onsite, hybrid, remote }

enum EmploymentType { fullTime, partTime, contract, internship, freelance }

enum SalaryPeriod { hourly, monthly, yearly }

enum PortfolioLinkKind { website, github, linkedin, behance, dribbble, other }

/// One school, bootcamp, or degree program.
class EducationEntry {
  const EducationEntry({
    required this.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.grade,
    this.description,
  });

  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final DateTime startDate;

  /// Null while [isCurrent] is true.
  final DateTime? endDate;
  final bool isCurrent;
  final String? grade;
  final String? description;

  EducationEntry copyWith({
    String? institution,
    String? degree,
    String? fieldOfStudy,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? grade,
    String? description,
  }) {
    return EducationEntry(
      id: id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      grade: grade ?? this.grade,
      description: description ?? this.description,
    );
  }
}

/// One job or internship. [skills] lets skill-gap analysis attribute a skill to
/// the role where it was used, instead of treating the skill list as flat.
class WorkExperience {
  const WorkExperience({
    required this.id,
    required this.company,
    required this.title,
    required this.employmentType,
    required this.startDate,
    this.location,
    this.endDate,
    this.isCurrent = false,
    this.description,
    this.skills = const [],
  });

  final String id;
  final String company;
  final String title;
  final EmploymentType employmentType;
  final DateTime startDate;
  final String? location;

  /// Null while [isCurrent] is true.
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;
  final List<String> skills;

  /// Whole months worked, counting an ongoing role up to [now].
  int monthsOfExperience(DateTime now) {
    final end = isCurrent ? now : (endDate ?? now);
    final months =
        (end.year - startDate.year) * 12 + (end.month - startDate.month);
    return months < 0 ? 0 : months;
  }

  WorkExperience copyWith({
    String? company,
    String? title,
    EmploymentType? employmentType,
    DateTime? startDate,
    String? location,
    DateTime? endDate,
    bool? isCurrent,
    String? description,
    List<String>? skills,
  }) {
    return WorkExperience(
      id: id,
      company: company ?? this.company,
      title: title ?? this.title,
      employmentType: employmentType ?? this.employmentType,
      startDate: startDate ?? this.startDate,
      location: location ?? this.location,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      description: description ?? this.description,
      skills: skills ?? this.skills,
    );
  }
}

class SkillEntry {
  const SkillEntry({
    required this.id,
    required this.name,
    required this.level,
    this.yearsOfExperience,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final SkillLevel level;
  final double? yearsOfExperience;

  /// Set once a skill has been backed by an assessment or endorsement.
  final bool isVerified;

  SkillEntry copyWith({
    String? name,
    SkillLevel? level,
    double? yearsOfExperience,
    bool? isVerified,
  }) {
    return SkillEntry(
      id: id,
      name: name ?? this.name,
      level: level ?? this.level,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class Certification {
  const Certification({
    required this.id,
    required this.name,
    required this.issuer,
    required this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  final String id;
  final String name;
  final String issuer;
  final DateTime issueDate;

  /// Null when the credential does not expire.
  final DateTime? expiryDate;
  final String? credentialId;
  final String? credentialUrl;

  bool isExpired(DateTime now) =>
      expiryDate != null && expiryDate!.isBefore(now);

  Certification copyWith({
    String? name,
    String? issuer,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
  }) {
    return Certification(
      id: id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      credentialId: credentialId ?? this.credentialId,
      credentialUrl: credentialUrl ?? this.credentialUrl,
    );
  }
}

class PortfolioLink {
  const PortfolioLink({
    required this.id,
    required this.label,
    required this.url,
    this.kind = PortfolioLinkKind.other,
  });

  final String id;
  final String label;
  final String url;
  final PortfolioLinkKind kind;

  PortfolioLink copyWith({
    String? label,
    String? url,
    PortfolioLinkKind? kind,
  }) {
    return PortfolioLink(
      id: id,
      label: label ?? this.label,
      url: url ?? this.url,
      kind: kind ?? this.kind,
    );
  }
}

class SalaryExpectation {
  const SalaryExpectation({
    required this.min,
    required this.max,
    this.currency = 'BDT',
    this.period = SalaryPeriod.monthly,
  });

  final int min;
  final int max;
  final String currency;
  final SalaryPeriod period;

  SalaryExpectation copyWith({
    int? min,
    int? max,
    String? currency,
    SalaryPeriod? period,
  }) {
    return SalaryExpectation(
      min: min ?? this.min,
      max: max ?? this.max,
      currency: currency ?? this.currency,
      period: period ?? this.period,
    );
  }
}

/// What the seeker is looking for, as opposed to what they have already done.
/// This half of the profile drives matching; the history half drives resume
/// suggestions and skill-gap analysis.
class JobPreferences {
  const JobPreferences({
    this.preferredRoles = const [],
    this.preferredLocations = const [],
    this.workModes = const [],
    this.employmentTypes = const [],
    this.salary,
    this.openToRelocation = false,
    this.availableFrom,
  });

  final List<String> preferredRoles;
  final List<String> preferredLocations;
  final List<WorkMode> workModes;
  final List<EmploymentType> employmentTypes;
  final SalaryExpectation? salary;
  final bool openToRelocation;
  final DateTime? availableFrom;

  JobPreferences copyWith({
    List<String>? preferredRoles,
    List<String>? preferredLocations,
    List<WorkMode>? workModes,
    List<EmploymentType>? employmentTypes,
    SalaryExpectation? salary,
    bool? openToRelocation,
    DateTime? availableFrom,
  }) {
    return JobPreferences(
      preferredRoles: preferredRoles ?? this.preferredRoles,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      workModes: workModes ?? this.workModes,
      employmentTypes: employmentTypes ?? this.employmentTypes,
      salary: salary ?? this.salary,
      openToRelocation: openToRelocation ?? this.openToRelocation,
      availableFrom: availableFrom ?? this.availableFrom,
    );
  }
}

/// The editable identity fields, grouped so the "edit basics" form has a single
/// payload instead of a dozen loose arguments.
class ProfileBasicsDraft {
  const ProfileBasicsDraft({
    required this.fullName,
    required this.headline,
    required this.email,
    this.phone,
    this.location,
    this.about,
    this.careerGoals,
    this.avatarUrl,
  });

  final String fullName;
  final String headline;
  final String email;
  final String? phone;
  final String? location;
  final String? about;
  final String? careerGoals;
  final String? avatarUrl;
}

/// How much of the profile is filled in, plus which sections are still empty.
/// Matching quality degrades badly on sparse profiles, so the UI uses [missing]
/// to prompt for the specific sections that are worth the most.
class ProfileCompleteness {
  const ProfileCompleteness({required this.percent, required this.missing});

  /// 0..100, rounded.
  final int percent;

  /// Human-readable labels of the sections still to fill, highest value first.
  final List<String> missing;

  bool get isComplete => missing.isEmpty;
}

class CareerProfile {
  const CareerProfile({
    required this.id,
    required this.fullName,
    required this.headline,
    required this.email,
    this.phone,
    this.location,
    this.avatarUrl,
    this.about,
    this.careerGoals,
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.certifications = const [],
    this.portfolioLinks = const [],
    this.preferences = const JobPreferences(),
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String headline;
  final String email;
  final String? phone;
  final String? location;
  final String? avatarUrl;
  final String? about;
  final String? careerGoals;
  final List<EducationEntry> education;
  final List<WorkExperience> experience;
  final List<SkillEntry> skills;
  final List<Certification> certifications;
  final List<PortfolioLink> portfolioLinks;
  final JobPreferences preferences;
  final DateTime? updatedAt;

  /// Initials for the avatar fallback, e.g. "Taznia Rahman" -> "TR".
  String get initials {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Total months across all roles. Overlapping roles are counted twice, which
  /// is deliberate — concurrent work is still work — but means this reads high
  /// for people who freelance alongside a job.
  int totalMonthsOfExperience(DateTime now) =>
      experience.fold(0, (sum, role) => sum + role.monthsOfExperience(now));

  /// Weighted so the sections that actually improve matching count for most.
  /// Skills and preferences are the two the matcher reads directly, so they
  /// carry more than, say, portfolio links.
  ProfileCompleteness get completeness {
    const weights = <String, int>{
      'Basic details': 15,
      'Skills': 20,
      'Job preferences': 20,
      'Work experience': 15,
      'Education': 15,
      'Career goals': 5,
      'Certifications': 5,
      'Portfolio links': 5,
    };

    final filled = <String, bool>{
      'Basic details': fullName.isNotEmpty && headline.isNotEmpty,
      'Skills': skills.isNotEmpty,
      'Job preferences': preferences.preferredRoles.isNotEmpty &&
          preferences.salary != null,
      'Work experience': experience.isNotEmpty,
      'Education': education.isNotEmpty,
      'Career goals': (careerGoals ?? '').trim().isNotEmpty,
      'Certifications': certifications.isNotEmpty,
      'Portfolio links': portfolioLinks.isNotEmpty,
    };

    var score = 0;
    final missing = <String>[];
    for (final entry in weights.entries) {
      if (filled[entry.key] == true) {
        score += entry.value;
      } else {
        missing.add(entry.key);
      }
    }
    // Highest-weight gaps first so the UI prompts for what matters most.
    missing.sort((a, b) => weights[b]!.compareTo(weights[a]!));

    return ProfileCompleteness(percent: score, missing: missing);
  }

  CareerProfile copyWith({
    String? fullName,
    String? headline,
    String? email,
    String? phone,
    String? location,
    String? avatarUrl,
    String? about,
    String? careerGoals,
    List<EducationEntry>? education,
    List<WorkExperience>? experience,
    List<SkillEntry>? skills,
    List<Certification>? certifications,
    List<PortfolioLink>? portfolioLinks,
    JobPreferences? preferences,
    DateTime? updatedAt,
  }) {
    return CareerProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      headline: headline ?? this.headline,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      about: about ?? this.about,
      careerGoals: careerGoals ?? this.careerGoals,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      preferences: preferences ?? this.preferences,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
