import 'dart:async';

import '../../../../shared/models/career_profile_models.dart';
import '../../domain/repositories/career_profile_repository.dart';

/// In-memory stand-in for the real backend, seeded with a realistic profile so
/// the UI has something to render. Swap this for a REST implementation behind
/// [CareerProfileRepository] without touching the presentation layer.
class InMemoryCareerProfileRepository implements CareerProfileRepository {
  InMemoryCareerProfileRepository() : _profile = _seedProfile;

  CareerProfile _profile;

  /// Counter for ids assigned to newly created entries. Entries arriving with
  /// an empty id are treated as new; anything else replaces the matching row.
  int _sequence = 0;

  String _nextId(String prefix) => '$prefix-local-${++_sequence}';

  @override
  Future<CareerProfile> loadProfile() async => _profile;

  @override
  Future<CareerProfile> saveBasics(ProfileBasicsDraft draft) async {
    // Built directly rather than with copyWith: the draft's optional fields are
    // nullable, and copyWith's `value ?? this.value` would silently keep the old
    // phone/location when the user deliberately cleared it.
    return _commit(
      CareerProfile(
        id: _profile.id,
        fullName: draft.fullName,
        headline: draft.headline,
        email: draft.email,
        phone: draft.phone,
        location: draft.location,
        avatarUrl: draft.avatarUrl,
        about: draft.about,
        careerGoals: draft.careerGoals,
        education: _profile.education,
        experience: _profile.experience,
        skills: _profile.skills,
        certifications: _profile.certifications,
        portfolioLinks: _profile.portfolioLinks,
        preferences: _profile.preferences,
        updatedAt: _profile.updatedAt,
      ),
    );
  }

  @override
  Future<CareerProfile> savePreferences(JobPreferences preferences) async {
    return _commit(_profile.copyWith(preferences: preferences));
  }

  @override
  Future<CareerProfile> upsertEducation(EducationEntry entry) async {
    final saved = entry.id.isEmpty
        ? EducationEntry(
            id: _nextId('edu'),
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

    final next = _upsertById(_profile.education, saved, (e) => e.id)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return _commit(_profile.copyWith(education: next));
  }

  @override
  Future<CareerProfile> removeEducation(String id) async {
    final next = _profile.education.where((e) => e.id != id).toList();
    return _commit(_profile.copyWith(education: next));
  }

  @override
  Future<CareerProfile> upsertExperience(WorkExperience entry) async {
    final saved = entry.id.isEmpty
        ? WorkExperience(
            id: _nextId('exp'),
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

    final next = _upsertById(_profile.experience, saved, (e) => e.id)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return _commit(_profile.copyWith(experience: next));
  }

  @override
  Future<CareerProfile> removeExperience(String id) async {
    final next = _profile.experience.where((e) => e.id != id).toList();
    return _commit(_profile.copyWith(experience: next));
  }

  @override
  Future<CareerProfile> upsertSkill(SkillEntry entry) async {
    final saved = entry.id.isEmpty
        ? SkillEntry(
            id: _nextId('skill'),
            name: entry.name,
            level: entry.level,
            yearsOfExperience: entry.yearsOfExperience,
            isVerified: entry.isVerified,
          )
        : entry;

    final next = _upsertById(_profile.skills, saved, (e) => e.id);
    return _commit(_profile.copyWith(skills: next));
  }

  @override
  Future<CareerProfile> removeSkill(String id) async {
    final next = _profile.skills.where((e) => e.id != id).toList();
    return _commit(_profile.copyWith(skills: next));
  }

  @override
  Future<CareerProfile> upsertCertification(Certification entry) async {
    final saved = entry.id.isEmpty
        ? Certification(
            id: _nextId('cert'),
            name: entry.name,
            issuer: entry.issuer,
            issueDate: entry.issueDate,
            expiryDate: entry.expiryDate,
            credentialId: entry.credentialId,
            credentialUrl: entry.credentialUrl,
          )
        : entry;

    final next = _upsertById(_profile.certifications, saved, (e) => e.id)
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return _commit(_profile.copyWith(certifications: next));
  }

  @override
  Future<CareerProfile> removeCertification(String id) async {
    final next = _profile.certifications.where((e) => e.id != id).toList();
    return _commit(_profile.copyWith(certifications: next));
  }

  @override
  Future<CareerProfile> upsertPortfolioLink(PortfolioLink link) async {
    final saved = link.id.isEmpty
        ? PortfolioLink(
            id: _nextId('link'),
            label: link.label,
            url: link.url,
            kind: link.kind,
          )
        : link;

    final next = _upsertById(_profile.portfolioLinks, saved, (e) => e.id);
    return _commit(_profile.copyWith(portfolioLinks: next));
  }

  @override
  Future<CareerProfile> removePortfolioLink(String id) async {
    final next = _profile.portfolioLinks.where((e) => e.id != id).toList();
    return _commit(_profile.copyWith(portfolioLinks: next));
  }

  /// Replace the entry with a matching id, or append when it is new.
  List<T> _upsertById<T>(List<T> source, T value, String Function(T) idOf) {
    final id = idOf(value);
    final index = source.indexWhere((item) => idOf(item) == id);
    final next = [...source];
    if (index == -1) {
      next.add(value);
    } else {
      next[index] = value;
    }
    return next;
  }

  CareerProfile _commit(CareerProfile updated) {
    // The real backend stamps this; do it here so the UI shows a live value.
    _profile = updated.copyWith(updatedAt: DateTime.now());
    return _profile;
  }

  static final _seedProfile = CareerProfile(
    id: 'user-taznia',
    fullName: 'Taznia Rahman',
    headline: 'Flutter Developer • Building for mobile-first teams',
    email: 'taznia.rahman@example.com',
    phone: '+880 1712 345678',
    location: 'Dhaka, Bangladesh',
    about:
        'Mobile engineer with a product mindset. I care about smooth frame '
        'times, accessible UI, and shipping features people actually finish.',
    careerGoals:
        'Move into a senior mobile role within two years, leading a small '
        'team and owning the architecture of a production Flutter app.',
    updatedAt: DateTime(2026, 7, 28),
    education: [
      EducationEntry(
        id: 'edu-buet',
        institution: 'Bangladesh University of Engineering and Technology',
        degree: 'BSc',
        fieldOfStudy: 'Computer Science and Engineering',
        startDate: DateTime(2019, 1),
        endDate: DateTime(2023, 6),
        grade: 'CGPA 3.72 / 4.00',
      ),
    ],
    experience: [
      WorkExperience(
        id: 'exp-shiftlab',
        company: 'ShiftLab',
        title: 'Flutter Developer',
        employmentType: EmploymentType.fullTime,
        startDate: DateTime(2024, 3),
        location: 'Dhaka, Bangladesh',
        isCurrent: true,
        description:
            'Own the candidate-facing mobile app: offline caching, push '
            'notifications, and a design system used across four features.',
        skills: ['Flutter', 'Dart', 'REST APIs', 'CI/CD'],
      ),
      WorkExperience(
        id: 'exp-brightpath',
        company: 'BrightPath Solutions',
        title: 'Junior Mobile Developer',
        employmentType: EmploymentType.fullTime,
        startDate: DateTime(2023, 7),
        endDate: DateTime(2024, 2),
        location: 'Remote',
        description:
            'Shipped two client apps in Flutter and maintained the shared '
            'widget library.',
        skills: ['Flutter', 'Firebase', 'Figma'],
      ),
    ],
    skills: [
      SkillEntry(
        id: 'skill-flutter',
        name: 'Flutter',
        level: SkillLevel.advanced,
        yearsOfExperience: 3.0,
        isVerified: true,
      ),
      SkillEntry(
        id: 'skill-dart',
        name: 'Dart',
        level: SkillLevel.advanced,
        yearsOfExperience: 3.0,
        isVerified: true,
      ),
      SkillEntry(
        id: 'skill-firebase',
        name: 'Firebase',
        level: SkillLevel.intermediate,
        yearsOfExperience: 2.0,
      ),
      SkillEntry(
        id: 'skill-rest',
        name: 'REST APIs',
        level: SkillLevel.advanced,
        yearsOfExperience: 3.0,
      ),
      SkillEntry(
        id: 'skill-figma',
        name: 'Figma',
        level: SkillLevel.intermediate,
        yearsOfExperience: 2.0,
      ),
      SkillEntry(
        id: 'skill-testing',
        name: 'Automated Testing',
        level: SkillLevel.beginner,
        yearsOfExperience: 1.0,
      ),
    ],
    certifications: [
      Certification(
        id: 'cert-gcp',
        name: 'Associate Cloud Engineer',
        issuer: 'Google Cloud',
        issueDate: DateTime(2025, 4),
        expiryDate: DateTime(2028, 4),
        credentialId: 'GCP-ACE-2025-88213',
        credentialUrl: 'https://www.credential.net/example',
      ),
    ],
    portfolioLinks: [
      PortfolioLink(
        id: 'link-github',
        label: 'GitHub',
        url: 'https://github.com/example',
        kind: PortfolioLinkKind.github,
      ),
      PortfolioLink(
        id: 'link-linkedin',
        label: 'LinkedIn',
        url: 'https://linkedin.com/in/example',
        kind: PortfolioLinkKind.linkedin,
      ),
    ],
    preferences: JobPreferences(
      preferredRoles: ['Flutter Developer', 'Mobile Engineer'],
      preferredLocations: ['Dhaka', 'Remote'],
      workModes: [WorkMode.hybrid, WorkMode.remote],
      employmentTypes: [EmploymentType.fullTime, EmploymentType.contract],
      salary: SalaryExpectation(
        min: 70000,
        max: 110000,
        currency: 'BDT',
        period: SalaryPeriod.monthly,
      ),
      openToRelocation: true,
      availableFrom: DateTime(2026, 9, 1),
    ),
  );
}
