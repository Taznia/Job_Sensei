import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router.dart';
import '../../../../shared/models/career_profile_models.dart';
import '../../data/repositories/in_memory_career_profile_repository.dart';
import '../../domain/repositories/career_profile_repository.dart';
import '../controllers/career_profile_controller.dart';
import '../widgets/profile_design.dart';
import '../widgets/profile_edit_sheets.dart';
import '../widgets/profile_formatting.dart';
import '../widgets/profile_manage_sheet.dart';
import '../widgets/profile_widgets.dart';

/// The career profile: the seeker's full record of education, experience,
/// preferred roles, location and salary, skills, certifications, portfolio
/// links, and career goals.
///
/// Built to the Figma frame. The page itself is read-only; every section's
/// "Edit" link opens a sheet, and each write round-trips through
/// [CareerProfileController] so the page always re-renders from stored state
/// rather than from local form state.
class CareerProfileScreen extends StatefulWidget {
  const CareerProfileScreen({super.key, this.repository});

  final CareerProfileRepository? repository;

  @override
  State<CareerProfileScreen> createState() => _CareerProfileScreenState();
}

class _CareerProfileScreenState extends State<CareerProfileScreen> {
  /// How many skill chips fit before collapsing into "+N more", matching the
  /// design's five-chips-then-overflow row.
  static const _visibleSkills = 5;

  /// The frame is a phone design; on desktop it reads best as a centred column
  /// rather than stretched across the window.
  static const _columnWidth = 460.0;

  late final CareerProfileController _controller = CareerProfileController(
    widget.repository ?? InMemoryCareerProfileRepository(),
  )..addListener(_refresh);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? ProfileDesign.danger : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _commit(
    Future<bool> Function() write,
    String successMessage,
  ) async {
    final ok = await write();
    if (!mounted) return;
    _showMessage(
      ok ? successMessage : (_controller.errorMessage ?? 'Something went wrong.'),
      isError: !ok,
    );
  }

  Future<bool> _confirmDelete(String what) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove entry'),
        content: Text('Remove $what from your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ProfileDesign.danger,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /* --------------------------------------------------------- basics --- */

  Future<void> _editBasics() async {
    final profile = _controller.profile;
    if (profile == null) return;
    final draft = await EditBasicsSheet.show(context, profile);
    if (draft == null || !mounted) return;
    await _commit(() => _controller.saveBasics(draft), 'Profile details saved.');
  }

  Future<void> _editPreferences() async {
    final profile = _controller.profile;
    if (profile == null) return;
    final prefs = await EditPreferencesSheet.show(context, profile.preferences);
    if (prefs == null || !mounted) return;
    await _commit(
      () => _controller.savePreferences(prefs),
      'Job preferences saved.',
    );
  }

  /* ------------------------------------------------- section managers --- */

  Future<void> _manageEducation() {
    return ManageSectionSheet.show<EducationEntry>(
      context: context,
      sheet: ManageSectionSheet<EducationEntry>(
        controller: _controller,
        title: 'Education',
        addLabel: 'Add education',
        emptyMessage: 'No education added yet.',
        itemsOf: (p) => p.education,
        titleOf: (e) => '${e.degree} · ${e.fieldOfStudy}',
        subtitleOf: (e) => e.institution,
        onAdd: () => _upsertEducation(),
        onEdit: (e) => _upsertEducation(entry: e),
        onDelete: (e) async {
          if (!await _confirmDelete(e.institution) || !mounted) return;
          await _commit(
            () => _controller.removeEducation(e.id),
            'Education removed.',
          );
        },
      ),
    );
  }

  Future<void> _upsertEducation({EducationEntry? entry}) async {
    final result = await EditEducationSheet.show(context, entry: entry);
    if (result == null || !mounted) return;
    await _commit(() => _controller.saveEducation(result), 'Education saved.');
  }

  Future<void> _manageExperience() {
    return ManageSectionSheet.show<WorkExperience>(
      context: context,
      sheet: ManageSectionSheet<WorkExperience>(
        controller: _controller,
        title: 'Work Experience',
        addLabel: 'Add experience',
        emptyMessage: 'No roles added yet.',
        itemsOf: (p) => p.experience,
        titleOf: (e) => '${e.title} · ${e.company}',
        subtitleOf: (e) => ProfileFormat.dateRange(
          e.startDate,
          e.endDate,
          isCurrent: e.isCurrent,
        ),
        onAdd: () => _upsertExperience(),
        onEdit: (e) => _upsertExperience(entry: e),
        onDelete: (e) async {
          if (!await _confirmDelete('${e.title} at ${e.company}') || !mounted) {
            return;
          }
          await _commit(
            () => _controller.removeExperience(e.id),
            'Experience removed.',
          );
        },
      ),
    );
  }

  Future<void> _upsertExperience({WorkExperience? entry}) async {
    final result = await EditExperienceSheet.show(context, entry: entry);
    if (result == null || !mounted) return;
    await _commit(() => _controller.saveExperience(result), 'Experience saved.');
  }

  Future<void> _manageSkills() {
    return ManageSectionSheet.show<SkillEntry>(
      context: context,
      sheet: ManageSectionSheet<SkillEntry>(
        controller: _controller,
        title: 'Skills',
        addLabel: 'Add skill',
        emptyMessage: 'No skills added yet.',
        itemsOf: (p) => p.skills,
        titleOf: (s) => s.name,
        subtitleOf: (s) => ProfileFormat.skillLevel(s.level),
        onAdd: () => _upsertSkill(),
        onEdit: (s) => _upsertSkill(entry: s),
        onDelete: (s) async {
          if (!await _confirmDelete(s.name) || !mounted) return;
          await _commit(() => _controller.removeSkill(s.id), 'Skill removed.');
        },
      ),
    );
  }

  Future<void> _upsertSkill({SkillEntry? entry}) async {
    final result = await EditSkillSheet.show(context, entry: entry);
    if (result == null || !mounted) return;
    await _commit(() => _controller.saveSkill(result), 'Skill saved.');
  }

  Future<void> _manageCertifications() {
    return ManageSectionSheet.show<Certification>(
      context: context,
      sheet: ManageSectionSheet<Certification>(
        controller: _controller,
        title: 'Certifications',
        addLabel: 'Add certification',
        emptyMessage: 'No certifications added yet.',
        itemsOf: (p) => p.certifications,
        titleOf: (c) => c.name,
        subtitleOf: (c) =>
            'Issued ${ProfileFormat.monthYear(c.issueDate)} · ${c.issuer}',
        onAdd: () => _upsertCertification(),
        onEdit: (c) => _upsertCertification(entry: c),
        onDelete: (c) async {
          if (!await _confirmDelete(c.name) || !mounted) return;
          await _commit(
            () => _controller.removeCertification(c.id),
            'Certification removed.',
          );
        },
      ),
    );
  }

  Future<void> _upsertCertification({Certification? entry}) async {
    final result = await EditCertificationSheet.show(context, entry: entry);
    if (result == null || !mounted) return;
    await _commit(
      () => _controller.saveCertification(result),
      'Certification saved.',
    );
  }

  Future<void> _manageLinks() {
    return ManageSectionSheet.show<PortfolioLink>(
      context: context,
      sheet: ManageSectionSheet<PortfolioLink>(
        controller: _controller,
        title: 'Portfolio Links',
        addLabel: 'Add link',
        emptyMessage: 'No links added yet.',
        itemsOf: (p) => p.portfolioLinks,
        titleOf: (l) => l.label,
        subtitleOf: (l) => ProfileFormat.prettyUrl(l.url),
        onAdd: () => _upsertLink(),
        onEdit: (l) => _upsertLink(entry: l),
        onDelete: (l) async {
          if (!await _confirmDelete(l.label) || !mounted) return;
          await _commit(
            () => _controller.removePortfolioLink(l.id),
            'Link removed.',
          );
        },
      ),
    );
  }

  Future<void> _upsertLink({PortfolioLink? entry}) async {
    final result = await EditPortfolioLinkSheet.show(context, entry: entry);
    if (result == null || !mounted) return;
    await _commit(() => _controller.savePortfolioLink(result), 'Link saved.');
  }

  Future<void> _openLink(PortfolioLink link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Could not open ${link.url}', isError: true);
    }
  }

  void _goTo(String route) => Navigator.of(context).pushNamed(route);

  /// Sends the user to sign in, then reloads — the profile is per-account,
  /// so there is nothing to show until there is a session.
  Future<void> _goToSignIn() async {
    await Navigator.of(context).pushNamed(AppRouter.authentication);
    if (mounted) await _controller.load();
  }

  /* ----------------------------------------------------------- build --- */

  @override
  Widget build(BuildContext context) {
    final profile = _controller.profile;

    return Scaffold(
      backgroundColor: ProfileDesign.canvas,
      body: SafeArea(
        bottom: false,
        child: switch ((_controller.isLoading, profile, _controller.errorMessage)) {
          (_, final CareerProfile p, _) => _buildContent(p),
          (_, null, final String error) => _ErrorState(
              message: error,
              onRetry: _controller.load,
              onSignIn: _controller.requiresSignIn ? _goToSignIn : null,
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _buildContent(CareerProfile profile) {
    return Column(
      children: [
        if (_controller.isSaving)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        // Constrained to the same column as the cards, so on a wide window the
        // edit button sits above the content instead of at the screen edge.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _columnWidth),
            child: ProfileTopBar(
              onEdit: _editBasics,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                ProfileDesign.pagePadding,
                0,
                ProfileDesign.pagePadding,
                28,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _columnWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _sections(profile),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _sections(CareerProfile profile) {
    final widgets = <Widget>[
      ProfileHero(profile: profile, onEdit: _editBasics),
      _educationCard(profile),
      _experienceCard(profile),
      _rolesCard(profile),
      _locationSalaryCard(profile),
      _skillsCard(profile),
      _certificationsCard(profile),
      _linksCard(profile),
      _goalsCard(profile),
      ProfilePowersStrip(
        onJobMatching: () => _goTo(AppRouter.jobs),
        onResumeSuggestions: () => _goTo(AppRouter.resumes),
        onSkillGap: () => _goTo(AppRouter.skillGap),
      ),
      ProfileCta(onTap: _editBasics),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sync_rounded,
            size: 13,
            color: ProfileDesign.faint,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${ProfileFormat.relative(profile.updatedAt)} · '
              'Changes sync automatically',
              style: ProfileDesign.footnote,
            ),
          ),
        ],
      ),
    ];

    return [
      for (var i = 0; i < widgets.length; i++) ...[
        widgets[i],
        if (i != widgets.length - 1)
          const SizedBox(height: ProfileDesign.cardGap),
      ],
    ];
  }

  /* -------------------------------------------------------- sections --- */

  Widget _educationCard(CareerProfile profile) {
    return ProfileCard(
      icon: Icons.school_outlined,
      title: 'Education',
      onEdit: _manageEducation,
      child: profile.education.isEmpty
          ? ProfileEmptyRow(
              message: 'Add your degrees, diplomas, and bootcamps.',
              actionLabel: 'Add education',
              onTap: () => _upsertEducation(),
            )
          : Column(
              children: [
                for (var i = 0; i < profile.education.length; i++)
                  ProfileEntryRow(
                    isFirst: i == 0,
                    title: '${profile.education[i].degree} · '
                        '${profile.education[i].fieldOfStudy}',
                    body: profile.education[i].institution,
                    meta: _educationMeta(profile.education[i]),
                  ),
              ],
            ),
    );
  }

  /// "2019 – 2023 · First Class Honours" — years only, grade appended if set.
  String _educationMeta(EducationEntry entry) {
    final end = entry.isCurrent || entry.endDate == null
        ? 'Present'
        : '${entry.endDate!.year}';
    final range = '${entry.startDate.year} – $end';
    return entry.grade == null ? range : '$range · ${entry.grade}';
  }

  Widget _experienceCard(CareerProfile profile) {
    return ProfileCard(
      icon: Icons.work_outline_rounded,
      title: 'Work Experience',
      onEdit: _manageExperience,
      child: profile.experience.isEmpty
          ? ProfileEmptyRow(
              message: 'Add the roles you have held, including internships.',
              actionLabel: 'Add experience',
              onTap: () => _upsertExperience(),
            )
          : Column(
              children: [
                for (var i = 0; i < profile.experience.length; i++)
                  ProfileEntryRow(
                    isFirst: i == 0,
                    title: '${profile.experience[i].title} · '
                        '${profile.experience[i].company}',
                    body: profile.experience[i].description,
                    meta: ProfileFormat.dateRange(
                      profile.experience[i].startDate,
                      profile.experience[i].endDate,
                      isCurrent: profile.experience[i].isCurrent,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _rolesCard(CareerProfile profile) {
    final roles = profile.preferences.preferredRoles;
    return ProfileCard(
      icon: Icons.near_me_outlined,
      title: 'Preferred Job Roles',
      onEdit: _editPreferences,
      child: roles.isEmpty
          ? ProfileEmptyRow(
              message: 'Tell matching which roles you are aiming for.',
              actionLabel: 'Set preferences',
              onTap: _editPreferences,
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in roles) ProfileChip(label: role),
              ],
            ),
    );
  }

  Widget _locationSalaryCard(CareerProfile profile) {
    final prefs = profile.preferences;
    final locations = prefs.preferredLocations.isEmpty
        ? 'Not set'
        : prefs.preferredLocations.join(' · ');
    // Compact form: the tile is half-card width, so the full figure clips.
    final salary = prefs.salary == null
        ? 'Not set'
        : ProfileFormat.salaryCompact(prefs.salary!);

    return ProfileCard(
      icon: Icons.place_outlined,
      title: 'Location & Salary',
      onEdit: _editPreferences,
      child: Row(
        children: [
          Expanded(
            child: ProfileStatTile(
              label: 'Preferred location',
              value: locations,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ProfileStatTile(
              label: 'Expected salary',
              value: salary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsCard(CareerProfile profile) {
    final skills = profile.skills;
    final shown = skills.take(_visibleSkills).toList();
    final overflow = skills.length - shown.length;

    return ProfileCard(
      icon: Icons.bolt_rounded,
      title: 'Skills',
      onEdit: _manageSkills,
      child: skills.isEmpty
          ? ProfileEmptyRow(
              message: 'Add the skills you already have.',
              actionLabel: 'Add a skill',
              onTap: () => _upsertSkill(),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in shown)
                  ProfileChip(
                    label: skill.name,
                    onTap: () => _upsertSkill(entry: skill),
                  ),
                if (overflow > 0)
                  ProfileChip(
                    label: '+$overflow more',
                    isMuted: true,
                    onTap: _manageSkills,
                  ),
              ],
            ),
    );
  }

  Widget _certificationsCard(CareerProfile profile) {
    final certs = profile.certifications;
    return ProfileCard(
      icon: Icons.workspace_premium_outlined,
      title: 'Certifications',
      onEdit: _manageCertifications,
      child: certs.isEmpty
          ? ProfileEmptyRow(
              message: 'Add credentials that back up your skills.',
              actionLabel: 'Add certification',
              onTap: () => _upsertCertification(),
            )
          : Column(
              children: [
                for (var i = 0; i < certs.length; i++)
                  ProfileEntryRow(
                    isFirst: i == 0,
                    title: certs[i].name,
                    meta: 'Issued ${certs[i].issueDate.year} · '
                        '${certs[i].issuer}',
                  ),
              ],
            ),
    );
  }

  Widget _linksCard(CareerProfile profile) {
    final links = profile.portfolioLinks;
    return ProfileCard(
      icon: Icons.link_rounded,
      title: 'Portfolio Links',
      onEdit: _manageLinks,
      child: links.isEmpty
          ? ProfileEmptyRow(
              message: 'Link your GitHub, portfolio site, or LinkedIn.',
              actionLabel: 'Add a link',
              onTap: () => _upsertLink(),
            )
          : Column(
              children: [
                for (var i = 0; i < links.length; i++)
                  ProfileLinkRow(
                    link: links[i],
                    isFirst: i == 0,
                    onOpen: () => _openLink(links[i]),
                  ),
              ],
            ),
    );
  }

  Widget _goalsCard(CareerProfile profile) {
    final goals = profile.careerGoals;
    return ProfileCard(
      icon: Icons.flag_outlined,
      title: 'Career Goals',
      onEdit: _editBasics,
      child: goals == null || goals.trim().isEmpty
          ? ProfileEmptyRow(
              message: 'Say where you want your career to go next.',
              actionLabel: 'Add career goals',
              onTap: _editBasics,
            )
          : Text(goals, style: ProfileDesign.goalsBody),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.onSignIn,
  });

  final String message;
  final VoidCallback onRetry;

  /// Set only when the failure was a missing or expired session.
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: ProfileDesign.faint,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ProfileDesign.entryBody,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onSignIn ?? onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: ProfileDesign.primary,
              ),
              child: Text(onSignIn == null ? 'Try again' : 'Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
