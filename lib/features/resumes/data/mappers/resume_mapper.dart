import '../../../../shared/models/resume_models.dart';

/// Translates between the API's resume JSON and [Resume] / [ResumeDraft].
abstract final class ResumeMapper {
  static Resume fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      targetField: json['targetField']?.toString() ?? '',
      template: json['template']?.toString() ?? 'Professional',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      linkedin: json['linkedin']?.toString() ?? '',
      portfolio: json['portfolio']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      skills: _stringList(json['skills']),
      experience: _stringList(json['experience']),
      education: _stringList(json['education']),
      projects: _stringList(json['projects']),
      certifications: _stringList(json['certifications']),
      fileUrl: json['fileUrl']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal(),
    );
  }

  static Map<String, dynamic> draftToJson(ResumeDraft draft) {
    return {
      'title': draft.title,
      'targetField': draft.targetField,
      'template': draft.template,
      'fullName': draft.fullName,
      'email': draft.email,
      'phone': draft.phone,
      'location': draft.location,
      'linkedin': draft.linkedin,
      'portfolio': draft.portfolio,
      'summary': draft.summary,
      'skills': draft.skills,
      'experience': draft.experience,
      'education': draft.education,
      'projects': draft.projects,
      'certifications': draft.certifications,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
