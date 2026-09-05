/// Models for the resume builder.
///
/// These mirror the `Resume` document the Node API stores. The original
/// upload-a-file fields (`fileUrl`, `isDefault`) are kept alongside the
/// authored ones so a resume created either way round-trips through the same
/// model.
class Resume {
  const Resume({
    required this.id,
    required this.title,
    this.targetField = '',
    this.template = 'Professional',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.portfolio = '',
    this.summary = '',
    this.skills = const [],
    this.experience = const [],
    this.education = const [],
    this.projects = const [],
    this.certifications = const [],
    this.fileUrl = '',
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String targetField;
  final String template;

  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String portfolio;

  final String summary;

  final List<String> skills;
  final List<String> experience;
  final List<String> education;
  final List<String> projects;
  final List<String> certifications;

  /// Set when the resume was uploaded as a file rather than authored here.
  final String fileUrl;
  final bool isDefault;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True when there is nothing worth rendering into a PDF yet.
  bool get isEmpty =>
      summary.trim().isEmpty &&
      skills.isEmpty &&
      experience.isEmpty &&
      education.isEmpty &&
      projects.isEmpty &&
      certifications.isEmpty;

  Resume copyWith({
    String? id,
    String? title,
    String? targetField,
    String? template,
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? linkedin,
    String? portfolio,
    String? summary,
    List<String>? skills,
    List<String>? experience,
    List<String>? education,
    List<String>? projects,
    List<String>? certifications,
    String? fileUrl,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Resume(
      id: id ?? this.id,
      title: title ?? this.title,
      targetField: targetField ?? this.targetField,
      template: template ?? this.template,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedin: linkedin ?? this.linkedin,
      portfolio: portfolio ?? this.portfolio,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      projects: projects ?? this.projects,
      certifications: certifications ?? this.certifications,
      fileUrl: fileUrl ?? this.fileUrl,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// The editable payload the resume editor submits.
///
/// Separate from [Resume] because a draft has no id, no timestamps and no
/// server-owned flags — only the fields a user types.
class ResumeDraft {
  const ResumeDraft({
    required this.title,
    required this.targetField,
    required this.template,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.linkedin,
    required this.portfolio,
    required this.summary,
    required this.skills,
    required this.experience,
    required this.education,
    required this.projects,
    required this.certifications,
  });

  final String title;
  final String targetField;
  final String template;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String portfolio;
  final String summary;
  final List<String> skills;
  final List<String> experience;
  final List<String> education;
  final List<String> projects;
  final List<String> certifications;

  factory ResumeDraft.fromResume(Resume resume) {
    return ResumeDraft(
      title: resume.title,
      targetField: resume.targetField,
      template: resume.template,
      fullName: resume.fullName,
      email: resume.email,
      phone: resume.phone,
      location: resume.location,
      linkedin: resume.linkedin,
      portfolio: resume.portfolio,
      summary: resume.summary,
      skills: resume.skills,
      experience: resume.experience,
      education: resume.education,
      projects: resume.projects,
      certifications: resume.certifications,
    );
  }

  /// Templates offered by the editor.
  static const List<String> templates = [
    'Professional',
    'Modern',
    'Minimal',
    'Creative',
  ];
}
