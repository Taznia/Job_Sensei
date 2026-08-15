import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/profile/data/repositories/in_memory_career_profile_repository.dart';
import 'package:jobsensei_frontend/features/profile/presentation/controllers/career_profile_controller.dart';
import 'package:jobsensei_frontend/features/profile/presentation/screens/career_profile_screen.dart';
import 'package:jobsensei_frontend/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:jobsensei_frontend/shared/models/career_profile_models.dart';

/// Pumps the screen against a fresh seeded repository and settles the entry
/// animations, which every widget test here needs first.
Future<void> _pumpProfile(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CareerProfileScreen(repository: InMemoryCareerProfileRepository()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the named section's "Edit" link into view and taps it, opening that
/// section's manage sheet.
Future<void> _openSectionEditor(
  WidgetTester tester,
  String sectionTitle,
) async {
  final card = find.ancestor(
    of: find.text(sectionTitle),
    matching: find.byType(ProfileCard),
  );
  final edit = find.descendant(of: card, matching: find.text('Edit'));

  await tester.ensureVisible(edit);
  await tester.pumpAndSettle();
  await tester.tap(edit);
  await tester.pumpAndSettle();
}

void main() {
  group('CareerProfile model', () {
    test('completeness reports missing sections weighted by matching value',
        () {
      const bare = CareerProfile(
        id: 'u1',
        fullName: 'Ada Lovelace',
        headline: 'Engineer',
        email: 'ada@example.com',
      );

      final result = bare.completeness;

      // Only "Basic details" is satisfied on a bare profile.
      expect(result.percent, 15);
      expect(result.isComplete, isFalse);
      // Highest-weight gaps must come first so the UI prompts for them first.
      expect(result.missing.first, anyOf('Skills', 'Job preferences'));
      expect(result.missing, contains('Education'));
    });

    test('initials fall back sensibly for one-word and empty names', () {
      const two = CareerProfile(
        id: 'u1',
        fullName: 'Taznia Rahman',
        headline: '',
        email: 'a@b.co',
      );
      const one = CareerProfile(
        id: 'u2',
        fullName: 'Prince',
        headline: '',
        email: 'a@b.co',
      );

      expect(two.initials, 'TR');
      expect(one.initials, 'P');
    });

    test('an ongoing role counts experience up to now', () {
      final role = WorkExperience(
        id: 'r1',
        company: 'ShiftLab',
        title: 'Dev',
        employmentType: EmploymentType.fullTime,
        startDate: DateTime(2024, 1),
        isCurrent: true,
      );

      expect(role.monthsOfExperience(DateTime(2024, 7)), 6);
    });
  });

  group('InMemoryCareerProfileRepository', () {
    test('assigns an id to new entries and replaces existing ones', () async {
      final repo = InMemoryCareerProfileRepository();
      final before = (await repo.loadProfile()).skills.length;

      final added = await repo.upsertSkill(
        const SkillEntry(id: '', name: 'Rust', level: SkillLevel.beginner),
      );
      expect(added.skills, hasLength(before + 1));

      final created = added.skills.firstWhere((s) => s.name == 'Rust');
      expect(created.id, isNotEmpty);

      // Re-saving the same id must update in place, not append a duplicate.
      final updated = await repo.upsertSkill(
        created.copyWith(level: SkillLevel.advanced),
      );
      expect(updated.skills, hasLength(before + 1));
      expect(
        updated.skills.firstWhere((s) => s.id == created.id).level,
        SkillLevel.advanced,
      );
    });

    test('saveBasics clears an optional field that was blanked out', () async {
      final repo = InMemoryCareerProfileRepository();
      final original = await repo.loadProfile();
      expect(original.phone, isNotNull);

      final saved = await repo.saveBasics(
        ProfileBasicsDraft(
          fullName: original.fullName,
          headline: original.headline,
          email: original.email,
          // phone deliberately omitted — the user cleared it.
        ),
      );

      expect(saved.phone, isNull);
      // Untouched sections must survive a basics-only save.
      expect(saved.skills, isNotEmpty);
      expect(saved.experience, isNotEmpty);
    });

    test('removing an entry drops it from the profile', () async {
      final repo = InMemoryCareerProfileRepository();
      final profile = await repo.loadProfile();
      final target = profile.education.first;

      final after = await repo.removeEducation(target.id);

      expect(after.education.any((e) => e.id == target.id), isFalse);
    });
  });

  group('CareerProfileController', () {
    test('exposes the loaded profile and reports save failures', () async {
      final controller = CareerProfileController(_FailingRepository());

      await controller.load();
      expect(controller.profile, isNotNull);

      final ok = await controller.saveSkill(
        const SkillEntry(id: '', name: 'Go', level: SkillLevel.beginner),
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.isSaving, isFalse);
      controller.dispose();
    });
  });

  group('CareerProfileScreen', () {
    testWidgets('renders the profile sections from the repository',
        (tester) async {
      await _pumpProfile(tester);

      expect(find.text('Taznia Rahman'), findsOneWidget);
      // Section titles, in the order the Figma frame lays them out.
      for (final title in const [
        'Education',
        'Work Experience',
        'Preferred Job Roles',
        'Location & Salary',
        'Skills',
        'Certifications',
        'Portfolio Links',
        'Career Goals',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'missing "$title"');
      }
      expect(find.text('Open to work'), findsOneWidget);
      expect(find.text('YOUR PROFILE POWERS'), findsOneWidget);
    });

    testWidgets('the skills card collapses overflow into a "+N more" chip',
        (tester) async {
      await _pumpProfile(tester);

      // Six seeded skills, five shown.
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('+1 more'), findsOneWidget);
      expect(find.text('Automated Testing'), findsNothing);
    });

    testWidgets('adding a skill flows through manage -> edit and updates the page',
        (tester) async {
      await _pumpProfile(tester);
      expect(find.text('+1 more'), findsOneWidget);

      await _openSectionEditor(tester, 'Skills');
      await tester.tap(find.widgetWithText(FilledButton, 'Add skill'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Kotlin');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // The edit sheet closed on a successful save, leaving the manage sheet.
      expect(find.text('Proficiency'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Add skill'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
      await tester.pumpAndSettle();

      // Seven skills now, so the overflow chip counts one more.
      expect(find.text('+2 more'), findsOneWidget);
    });

    testWidgets('a skill cannot be saved without a name', (tester) async {
      await _pumpProfile(tester);
      await _openSectionEditor(tester, 'Skills');

      await tester.tap(find.widgetWithText(FilledButton, 'Add skill'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Validation blocks the save, so the edit sheet stays open.
      expect(find.text('Skill name is required'), findsOneWidget);
      expect(find.text('Proficiency'), findsOneWidget);
    });
  });
}

/// Loads fine but fails every write, to exercise the controller's error path.
class _FailingRepository extends InMemoryCareerProfileRepository {
  @override
  Future<CareerProfile> upsertSkill(SkillEntry entry) async {
    throw Exception('network down');
  }
}
