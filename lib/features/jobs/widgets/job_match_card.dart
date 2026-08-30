import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../data/job_api_repository.dart';
import '../job_models.dart';
import '../job_search_models.dart';

/// Job match score — Module 4 (Adreed Saadad Hasan, 22301190).
///
/// Compares the signed-in seeker's career profile, and their selected resume
/// when they have one, against this job's requirements, and shows the overall
/// suitability with the qualifications that earned it.
///
/// Says nothing about closing a gap on purpose: learning recommendations are
/// the skill-gap feature's job, reached from the button below this card. Two
/// answers to "what should I do next" would be worse than one.
class JobMatchCard extends StatefulWidget {
  const JobMatchCard({
    super.key,
    required this.job,
    required this.repository,
    this.resumeId,
  });

  final JobPosting job;
  final JobRepository repository;

  /// Optional; the API falls back to the user's default resume, then to the
  /// career profile alone.
  final String? resumeId;

  @override
  State<JobMatchCard> createState() => _JobMatchCardState();
}

class _JobMatchCardState extends State<JobMatchCard> {
  JobMatchScore? _score;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final score = await widget.repository.matchScore(
        widget.job.id,
        resumeId: widget.resumeId,
      );
      if (!mounted) return;
      setState(() {
        _score = score;
        _loading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 401 means signed out; 409 means the profile is empty. Both are the
        // user's to fix, so the API's own wording is more useful than ours.
        _error = error.statusCode == 401
            ? 'Sign in to see how you match this role.'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not calculate your match for this role.';
      });
    }
  }

  static Color _colorFor(String verdict) => switch (verdict) {
        'strong' => AppColors.success,
        'good' => AppColors.primary,
        'fair' => AppColors.warning,
        _ => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 34),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.insights_outlined, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final score = _score!;
    final accent = _colorFor(score.verdict);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, accent.withValues(alpha: 0.72)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ScoreRing(percent: score.overallScore),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          score.verdictLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score.resumeTitle == null
                              ? 'Based on your career profile'
                              : 'Profile + "${score.resumeTitle}"',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (score.matchedSkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'SKILLS YOU ALREADY HAVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: score.matchedSkills
                      .take(8)
                      .map(
                        (skill) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        // The breakdown is what makes the number accountable — without it a
        // score is just an assertion.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How this score is made up',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final area in score.breakdown)
                _AreaRow(area: area, accent: accent),
              if (score.skillsNotEvidenced > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    '${score.skillsNotEvidenced} listed '
                    '${score.skillsNotEvidenced == 1 ? 'skill is' : 'skills are'} '
                    'not yet evidenced on your profile. Open Learn for a full '
                    'skill-gap breakdown.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (percent / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.area, required this.accent});

  final JobMatchArea area;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  area.area,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${area.score}/${area.max}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: area.fraction,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            area.detail,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
