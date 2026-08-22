/// Presentation pieces for the Career Profile screen, built to the Figma frame.
/// Geometry and colour come from [ProfileDesign]; nothing here reaches for
/// Theme.of(context), so the screen renders identically regardless of the app
/// theme still in force elsewhere.
library;

import 'package:flutter/material.dart';

import '../../../../shared/models/career_profile_models.dart';
import 'profile_design.dart';
import 'profile_formatting.dart';

/* -------------------------------------------------------------- top bar --- */

/// Back button, centred title, edit button — the design uses plain 42pt rounded
/// squares rather than a Material AppBar.
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key, required this.onEdit, this.onBack});

  final VoidCallback onEdit;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // Only offer "back" when there is somewhere to go; inside the tab shell
    // this screen is a root, so the slot stays empty to keep the title centred.
    final canPop = onBack != null && Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ProfileDesign.pagePadding,
        6,
        ProfileDesign.pagePadding,
        14,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: canPop
                ? _SquareButton(icon: Icons.chevron_left_rounded, onTap: onBack!)
                : null,
          ),
          const Expanded(
            child: Text(
              'Career Profile',
              textAlign: TextAlign.center,
              style: ProfileDesign.appBarTitle,
            ),
          ),
          SizedBox(
            width: 42,
            child: _SquareButton(icon: Icons.edit_outlined, onTap: onEdit),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileDesign.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ProfileDesign.border),
          ),
          child: Icon(icon, size: 20, color: ProfileDesign.ink),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------------- hero --- */

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final CareerProfile profile;
  final VoidCallback onEdit;

  /// The design's prompt names the single most valuable missing section.
  String get _prompt {
    final missing = profile.completeness.missing;
    if (missing.isEmpty) return 'Your profile is complete';
    return 'Add ${missing.first.toLowerCase()} to reach 100%';
  }

  @override
  Widget build(BuildContext context) {
    final completeness = profile.completeness;

    return Container(
      decoration: BoxDecoration(
        gradient: ProfileDesign.heroGradient,
        borderRadius: BorderRadius.circular(ProfileDesign.heroRadius),
        boxShadow: ProfileDesign.glow(ProfileDesign.primary, y: 16, blur: 30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ProfileDesign.heroRadius),
        child: Stack(
          children: [
            // Decorative disc bleeding off the top-right corner.
            Positioned(
              right: -42,
              top: -42,
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HeroAvatar(profile: profile),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ProfileDesign.heroName,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ProfileDesign.heroRole,
                            ),
                            const SizedBox(height: 8),
                            const _OpenToWorkPill(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile completeness',
                              style: ProfileDesign.heroLabel,
                            ),
                            const SizedBox(height: 3),
                            Text(_prompt, style: ProfileDesign.heroPrompt),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      CompletenessRing(percent: completeness.percent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.profile});

  final CareerProfile profile;

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: url == null ? ProfileDesign.avatarGradient : null,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        image: url == null
            ? null
            : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      child: url == null
          ? Text(profile.initials, style: ProfileDesign.avatarInitials)
          : null,
    );
  }
}

class _OpenToWorkPill extends StatelessWidget {
  const _OpenToWorkPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: ProfileDesign.online,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text('Open to work', style: ProfileDesign.heroPill),
        ],
      ),
    );
  }
}

/// White progress ring on the hero card.
class CompletenessRing extends StatelessWidget {
  const CompletenessRing({super.key, required this.percent, this.size = 58});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (percent / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 4.5,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Text('$percent%', style: ProfileDesign.ringValue),
        ],
      ),
    );
  }
}

/* ---------------------------------------------------------------- cards --- */

/// White section card: tinted icon square, title, and a blue "Edit" link.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.child,
  });

  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileDesign.surface,
        borderRadius: BorderRadius.circular(ProfileDesign.cardRadius),
        border: Border.all(color: ProfileDesign.border),
      ),
      padding: const EdgeInsets.fromLTRB(
        ProfileDesign.cardPadding,
        ProfileDesign.cardPadding,
        ProfileDesign.cardPadding,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ProfileDesign.iconBox,
                height: ProfileDesign.iconBox,
                decoration: BoxDecoration(
                  color: ProfileDesign.chipBg,
                  borderRadius:
                      BorderRadius.circular(ProfileDesign.iconBoxRadius),
                ),
                child: Icon(icon, size: 18, color: ProfileDesign.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: ProfileDesign.sectionTitle)),
              _EditLink(onTap: onEdit),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 14, color: ProfileDesign.primary),
            SizedBox(width: 4),
            Text('Edit', style: ProfileDesign.editLink),
          ],
        ),
      ),
    );
  }
}

/// A row inside a card: bold title, optional body, optional meta line. Rows
/// after the first carry a hairline top border, matching the design's dividers.
class ProfileEntryRow extends StatelessWidget {
  const ProfileEntryRow({
    super.key,
    required this.title,
    required this.isFirst,
    this.body,
    this.meta,
    this.trailing,
  });

  final String title;
  final bool isFirst;
  final String? body;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isFirst
          ? null
          : const BoxDecoration(
              border: Border(top: BorderSide(color: ProfileDesign.border)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ProfileDesign.entryTitle),
                if (body != null) ...[
                  const SizedBox(height: 4),
                  Text(body!, style: ProfileDesign.entryBody),
                ],
                if (meta != null) ...[
                  const SizedBox(height: 4),
                  Text(meta!, style: ProfileDesign.entryMeta),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Pill used for preferred roles and skills.
class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.label,
    this.isMuted = false,
    this.onTap,
  });

  final String label;
  final bool isMuted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isMuted ? ProfileDesign.chipMutedBg : ProfileDesign.chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: isMuted
            ? ProfileDesign.chipLabel
                .copyWith(color: ProfileDesign.chipMutedInk)
            : ProfileDesign.chipLabel,
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }
}

/// Half-width tile used by the Location & Salary section.
class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProfileDesign.tileBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ProfileDesign.tileLabel),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ProfileDesign.tileValue,
          ),
        ],
      ),
    );
  }
}

/// Portfolio link row: neutral icon square, label, URL, and a launch chevron.
class ProfileLinkRow extends StatelessWidget {
  const ProfileLinkRow({
    super.key,
    required this.link,
    required this.isFirst,
    required this.onOpen,
  });

  final PortfolioLink link;
  final bool isFirst;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: isFirst
            ? null
            : const BoxDecoration(
                border: Border(top: BorderSide(color: ProfileDesign.border)),
              ),
        child: Row(
          children: [
            Container(
              width: ProfileDesign.iconBox,
              height: ProfileDesign.iconBox,
              decoration: BoxDecoration(
                color: ProfileDesign.chipMutedBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                portfolioLinkIcon(link.kind),
                size: 17,
                color: ProfileDesign.ink,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.label, style: ProfileDesign.entryTitle),
                  const SizedBox(height: 3),
                  Text(
                    ProfileFormat.prettyUrl(link.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ProfileDesign.entryBody
                        .copyWith(color: ProfileDesign.primary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.north_east_rounded,
              size: 16,
              color: ProfileDesign.faint,
            ),
          ],
        ),
      ),
    );
  }
}

IconData portfolioLinkIcon(PortfolioLinkKind kind) => switch (kind) {
      PortfolioLinkKind.website => Icons.public_rounded,
      PortfolioLinkKind.github => Icons.code_rounded,
      PortfolioLinkKind.linkedin => Icons.business_center_rounded,
      PortfolioLinkKind.behance => Icons.palette_outlined,
      PortfolioLinkKind.dribbble => Icons.sports_basketball_outlined,
      PortfolioLinkKind.other => Icons.link_rounded,
    };

/* --------------------------------------------------------------- powers --- */

/// "YOUR PROFILE POWERS" — the three features this profile feeds. Tapping one
/// navigates to it, which is what makes the section worth its space.
class ProfilePowersStrip extends StatelessWidget {
  const ProfilePowersStrip({
    super.key,
    required this.onJobMatching,
    required this.onResumeSuggestions,
    required this.onSkillGap,
  });

  final VoidCallback onJobMatching;
  final VoidCallback onResumeSuggestions;
  final VoidCallback onSkillGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('YOUR PROFILE POWERS', style: ProfileDesign.eyebrow),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PowerCard(
                  icon: Icons.work_outline_rounded,
                  color: ProfileDesign.primary,
                  label: 'Job Matching',
                  onTap: onJobMatching,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PowerCard(
                  icon: Icons.description_outlined,
                  color: ProfileDesign.violet,
                  label: 'Resume\nSuggestions',
                  onTap: onResumeSuggestions,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PowerCard(
                  icon: Icons.donut_large_rounded,
                  color: ProfileDesign.sky,
                  label: 'Skill-Gap\nAnalysis',
                  onTap: onSkillGap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PowerCard extends StatelessWidget {
  const _PowerCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileDesign.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProfileDesign.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: ProfileDesign.powerLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ cta --- */

class ProfileCta extends StatelessWidget {
  const ProfileCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: ProfileDesign.glow(ProfileDesign.primary, y: 12, blur: 24),
      ),
      child: Material(
        color: ProfileDesign.primary,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: const SizedBox(
            height: 53,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text('Edit Profile', style: ProfileDesign.ctaLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------------------------------------------- empty --- */

/// Shown inside a card that has no entries yet. The design has no empty state,
/// so this keeps the card's rhythm and points at the same Edit action.
class ProfileEmptyRow extends StatelessWidget {
  const ProfileEmptyRow({
    super.key,
    required this.message,
    required this.onTap,
    required this.actionLabel,
  });

  final String message;
  final VoidCallback onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: ProfileDesign.tileBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: ProfileDesign.entryBody,
          ),
          const SizedBox(height: 10),
          ProfileChip(label: actionLabel, onTap: onTap),
        ],
      ),
    );
  }
}
