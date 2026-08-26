import '../../shared/models/career_profile_models.dart';
import '../../shared/models/learning_models.dart';

/// A job requirement enriched with the information Module 3 needs to explain
/// a gap and hand the skill to Module 4's learning path.
class JobSkillRequirement {
  const JobSkillRequirement({
    required this.id,
    required this.name,
    required this.category,
    required this.priority,
    required this.reason,
    this.learningPathAvailable = false,
    this.learningPathId,
  });

  final String id;
  final String name;
  final String category;
  final SkillPriority priority;
  final String reason;
  final bool learningPathAvailable;
  final String? learningPathId;
}

class JobPosting {
  const JobPosting({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.workMode,
    required this.description,
    required this.requiredSkills,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String type;
  final String workMode;
  final String description;
  final List<JobSkillRequirement> requiredSkills;
}

class JobSkillGapAnalysis {
  const JobSkillGapAnalysis({
    required this.job,
    required this.strongSkills,
    required this.missingSkills,
  });

  final JobPosting job;
  final List<SkillEntry> strongSkills;
  final List<JobSkillRequirement> missingSkills;

  int get matchPercent {
    if (job.requiredSkills.isEmpty) return 0;
    return ((strongSkills.length / job.requiredSkills.length) * 100).round();
  }
}

/// Module 3: compare the selected job's requirements with career-profile
/// skills. It deliberately returns no lessons or resources; Module 4 owns that.
abstract final class JobSkillGapAnalyzer {
  static JobSkillGapAnalysis analyze({
    required JobPosting job,
    required CareerProfile profile,
  }) {
    final profileSkills = <String, SkillEntry>{
      for (final skill in profile.skills)
        skill.name.trim().toLowerCase(): skill,
      for (final role in profile.experience)
        for (final name in role.skills)
          name.trim().toLowerCase(): SkillEntry(
              id: 'experience-$name',
              name: name,
              level: SkillLevel.intermediate),
    };
    final strongSkills = <SkillEntry>[];
    final missingSkills = <JobSkillRequirement>[];
    for (final requirement in job.requiredSkills) {
      final skill = profileSkills[requirement.name.trim().toLowerCase()];
      if (skill == null) {
        missingSkills.add(requirement);
      } else {
        strongSkills.add(skill);
      }
    }
    return JobSkillGapAnalysis(
      job: job,
      strongSkills: strongSkills,
      missingSkills: missingSkills,
    );
  }
}

const demoJobs = <JobPosting>[
  JobPosting(
    id: 'flutter-developer',
    title: 'Flutter Developer',
    company: 'Orbit Labs',
    location: 'Dhaka',
    type: 'Full time',
    workMode: 'Hybrid',
    description:
        'Build polished mobile features for a career platform used by thousands of job seekers.',
    requiredSkills: [
      JobSkillRequirement(
          id: 'flutter',
          name: 'Flutter',
          category: 'TECHNICAL',
          priority: SkillPriority.high,
          reason:
              'Flutter is the primary framework used to build and ship this mobile application.',
          learningPathId: 'flutter-foundations'),
      JobSkillRequirement(
          id: 'dart',
          name: 'Dart',
          category: 'TECHNICAL',
          priority: SkillPriority.high,
          reason:
              'Dart is needed to build maintainable application logic and reusable components.',
          learningPathId: 'dart-foundations'),
      JobSkillRequirement(
          id: 'rest-api',
          name: 'REST APIs',
          category: 'TOOL',
          priority: SkillPriority.medium,
          reason:
              'This role connects mobile screens with backend services and reliable data flows.',
          learningPathId: 'rest-api-basics'),
      JobSkillRequirement(
          id: 'state-management',
          name: 'State Management',
          learningPathAvailable: true,
          category: 'TECHNICAL',
          priority: SkillPriority.high,
          reason:
              'Managing app state cleanly is essential for scalable production Flutter features.',
          learningPathId: 'flutter-state-management'),
      JobSkillRequirement(
          id: 'docker',
          name: 'Docker',
          learningPathAvailable: true,
          category: 'TOOL',
          priority: SkillPriority.medium,
          reason:
              'Docker helps developers run consistent local environments and collaborate with backend teams.',
          learningPathId: 'docker-basics'),
    ],
  ),
  JobPosting(
    id: 'backend-developer',
    title: 'Backend Developer',
    company: 'ABC Technologies',
    location: 'Dhaka',
    type: 'Full time',
    workMode: 'On-site',
    description:
        'Develop reliable web services and data APIs for a growing job marketplace.',
    requiredSkills: [
      JobSkillRequirement(
          id: 'python',
          name: 'Python',
          category: 'TECHNICAL',
          priority: SkillPriority.high,
          reason: 'Python is the core language used by this backend team.',
          learningPathId: 'python-foundations'),
      JobSkillRequirement(
          id: 'django',
          name: 'Django',
          learningPathAvailable: true,
          category: 'TECHNICAL',
          priority: SkillPriority.high,
          reason:
              'Django is the primary framework required for this backend role.',
          learningPathId: 'django-beginner'),
      JobSkillRequirement(
          id: 'docker',
          name: 'Docker',
          learningPathAvailable: true,
          category: 'TOOL',
          priority: SkillPriority.medium,
          reason:
              'Docker is used for application containerization and deployment.',
          learningPathId: 'docker-basics'),
      JobSkillRequirement(
          id: 'postgresql',
          name: 'PostgreSQL',
          category: 'TOOL',
          priority: SkillPriority.medium,
          reason:
              'PostgreSQL supports the relational data used by the platform.',
          learningPathId: 'postgresql-basics'),
      JobSkillRequirement(
          id: 'rest-api',
          name: 'REST APIs',
          category: 'TECHNICAL',
          priority: SkillPriority.high,
          reason:
              'REST APIs are required to design clear contracts for frontend and partner systems.',
          learningPathId: 'rest-api-basics'),
    ],
  ),
  JobPosting(
    id: 'product-manager',
    title: 'Associate Product Manager',
    company: 'Harbor Talent',
    location: 'Remote',
    type: 'Full time',
    workMode: 'Remote',
    description:
        'Guide discovery and delivery for tools that improve candidate career outcomes.',
    requiredSkills: [
      JobSkillRequirement(
          id: 'analytics',
          name: 'Product Analytics',
          category: 'TOOL',
          priority: SkillPriority.high,
          reason: 'Analytics turns product decisions into measurable outcomes.',
          learningPathId: 'product-analytics'),
      JobSkillRequirement(
          id: 'roadmapping',
          name: 'Roadmapping',
          category: 'TECHNICAL',
          priority: SkillPriority.medium,
          reason:
              'Roadmapping aligns customer needs, business goals, and engineering capacity.',
          learningPathId: 'product-roadmapping'),
      JobSkillRequirement(
          id: 'stakeholders',
          name: 'Stakeholder Management',
          category: 'SOFT_SKILL',
          priority: SkillPriority.high,
          reason:
              'Product work requires clear alignment across teams with different priorities.',
          learningPathId: 'stakeholder-management'),
    ],
  ),
];
