import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

/// Summary-only home tab. Detailed match and gap analysis remain inside Jobs.
class SeekerHomePage extends StatelessWidget {
  const SeekerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: const [
          ScreenIntro(
            eyebrow: 'Career command center',
            title: 'Welcome, Taznia',
            description:
                'Your next best actions are based on your profile, job matches, and learning progress.',
          ),
          SizedBox(height: 22),
          _SummaryCard(
            title: 'Recommended Jobs',
            value: '3 roles',
            detail: 'Open Jobs to compare each role with your skills.',
            icon: Icons.work_outline_rounded,
          ),
          SizedBox(height: 12),
          _SummaryCard(
            title: 'Learning Progress',
            value: '2 skills ready',
            detail: 'Use Start Learning from a job skill gap to begin a path.',
            icon: Icons.school_outlined,
          ),
          SizedBox(height: 12),
          _SummaryCard(
            title: 'Career Profile',
            value: 'Keep skills current',
            detail:
                'Your listed skills are used for job match and skill-gap analysis.',
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAF3FF),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(value,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(detail,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
