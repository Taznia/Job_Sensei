import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/app_user.dart';

class RoleAccountPage extends StatelessWidget {
  const RoleAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Injector.authService().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your account.')),
      );
    }

    final details = _detailsFor(user);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [details.color, AppColors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(details.icon, size: 18),
                  label: Text(details.label),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
          if (user.role == 'recruiter') ...[
            const SizedBox(height: 16),
            _EmployerStatusCard(user: user),
          ],
          const SizedBox(height: 18),
          Text(
            'Your access',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < details.privileges.length; i++)
                  ListTile(
                    leading: Icon(
                      details.privileges[i].$1,
                      color: details.color,
                    ),
                    title: Text(details.privileges[i].$2),
                    subtitle: Text(details.privileges[i].$3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in using your account type.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await Injector.authService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  _RoleDetails _detailsFor(AppUser user) {
    return switch (user.role) {
      'recruiter' => const _RoleDetails(
          label: 'Employer account',
          icon: Icons.apartment_rounded,
          color: AppColors.primary,
          privileges: [
            (
              Icons.add_business_rounded,
              'Manage job posts',
              'Create, update, close, and review your organization jobs.'
            ),
            (
              Icons.people_alt_outlined,
              'Review applicants',
              'View resumes, shortlist candidates, and update statuses.'
            ),
            (
              Icons.groups_2_outlined,
              'Join communities',
              'Participate in professional community discussions.'
            ),
          ],
        ),
      'admin' => const _RoleDetails(
          label: 'Administrator',
          icon: Icons.admin_panel_settings_rounded,
          color: AppColors.danger,
          privileges: [
            (
              Icons.verified_user_outlined,
              'Approve employers',
              'Verify or reject employer registration requests.'
            ),
            (
              Icons.policy_outlined,
              'Moderate content',
              'Monitor jobs, communities, users, and reported content.'
            ),
            (
              Icons.school_outlined,
              'Manage learning categories',
              'Maintain learning resources and skill categories.'
            ),
          ],
        ),
      _ => const _RoleDetails(
          label: 'Job seeker',
          icon: Icons.badge_outlined,
          color: AppColors.success,
          privileges: [
            (
              Icons.auto_awesome_rounded,
              'AI Sensei',
              'Receive conversational career guidance.'
            ),
            (
              Icons.donut_large_rounded,
              'Skill gap analysis',
              'Compare your skills with your target career.'
            ),
            (
              Icons.school_rounded,
              'Personalized learning',
              'Learn missing skills with recommended resources.'
            ),
          ],
        ),
    };
  }
}

class _EmployerStatusCard extends StatelessWidget {
  const _EmployerStatusCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final verified = user.employerStatus == 'verified';
    final color = verified ? AppColors.success : AppColors.warning;
    return Card(
      child: ListTile(
        leading: Icon(
          verified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
          color: color,
        ),
        title: Text(verified ? 'Verified employer' : 'Verification pending'),
        subtitle: Text(
          verified
              ? user.organizationName
              : 'Employer-only actions unlock after admin approval.',
        ),
      ),
    );
  }
}

class _RoleDetails {
  const _RoleDetails({
    required this.label,
    required this.icon,
    required this.color,
    required this.privileges,
  });

  final String label;
  final IconData icon;
  final Color color;
  final List<(IconData, String, String)> privileges;
}
