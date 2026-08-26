import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/jobs/job_models.dart';
import 'package:jobsensei_frontend/shared/models/career_profile_models.dart';

void main() {
  test('selected job analysis returns only skills absent from the profile', () {
    const profile = CareerProfile(
      id: 'seeker-1',
      fullName: 'Taznia Rahman',
      headline: 'Developer',
      email: 'taznia@example.com',
      skills: [
        SkillEntry(id: 'python', name: 'Python', level: SkillLevel.advanced),
        SkillEntry(
          id: 'postgres',
          name: 'PostgreSQL',
          level: SkillLevel.intermediate,
        ),
      ],
    );
    final backendJob = JobPosting(
      id: 'backend',
      title: 'Backend Developer',
      company: 'ABC Technologies',
      location: 'Dhaka',
      type: 'Full time',
      workMode: 'On-site',
      description: 'Backend role',
      requiredSkills: demoJobs[1].requiredSkills,
    );

    final analysis = JobSkillGapAnalyzer.analyze(
      job: backendJob,
      profile: profile,
    );

    expect(analysis.matchPercent, 40);
    expect(analysis.strongSkills.map((skill) => skill.name),
        containsAll(['Python', 'PostgreSQL']));
    expect(analysis.missingSkills.map((skill) => skill.name),
        containsAll(['Django', 'Docker', 'REST APIs']));
    expect(analysis.missingSkills, hasLength(3));
    expect(analysis.missingSkills.first.learningPathAvailable, isTrue);
  });
}
