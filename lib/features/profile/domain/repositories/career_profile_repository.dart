import '../../../../shared/models/career_profile_models.dart';

/// Every mutation returns the full updated [CareerProfile] rather than just the
/// changed entry, because derived values on the profile (completeness, totals)
/// change whenever any section does.
///
/// The list sections use upsert-by-id instead of separate add/update calls: the
/// caller always hands over a complete entry, which also sidesteps the usual
/// `copyWith` problem where you cannot clear a nullable field such as `endDate`
/// when a role becomes current.
abstract interface class CareerProfileRepository {
  Future<CareerProfile> loadProfile();

  Future<CareerProfile> saveBasics(ProfileBasicsDraft draft);

  Future<CareerProfile> savePreferences(JobPreferences preferences);

  Future<CareerProfile> upsertEducation(EducationEntry entry);

  Future<CareerProfile> removeEducation(String id);

  Future<CareerProfile> upsertExperience(WorkExperience entry);

  Future<CareerProfile> removeExperience(String id);

  Future<CareerProfile> upsertSkill(SkillEntry entry);

  Future<CareerProfile> removeSkill(String id);

  Future<CareerProfile> upsertCertification(Certification entry);

  Future<CareerProfile> removeCertification(String id);

  Future<CareerProfile> upsertPortfolioLink(PortfolioLink link);

  Future<CareerProfile> removePortfolioLink(String id);
}
