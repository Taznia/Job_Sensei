import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../core/constants/app_colors.dart';
import '../../features/authentication/authentication_page.dart';
import '../../shared/models/app_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = Injector.authService().currentUser;
    if (user == null) {
      return AuthenticationPage(onAuthChanged: () => setState(() {}));
    }
    return _SignedInProfile(
      user: user,
      onSignOut: () async {
        await Injector.authService().logout();
        if (mounted) setState(() {});
      },
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isEmpty ? '?' : user.name[0].toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          if (user.headline.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.headline,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: user.role),
                if (user.targetRole.isNotEmpty)
                  _MetaChip(label: user.targetRole),
                _MetaChip(label: '${user.xp} XP'),
              ],
            ),
            const SizedBox(height: 22),
            _ProfileLink(
              icon: Icons.work_outline_rounded,
              title: 'Jobs',
              onTap: () => Navigator.pushNamed(context, '/jobs'),
            ),
            _ProfileLink(
              icon: Icons.description_outlined,
              title: 'Resumes',
              onTap: () => Navigator.pushNamed(context, '/resumes'),
            ),
            _ProfileLink(
              icon: Icons.assignment_outlined,
              title: 'Applications',
              onTap: () => Navigator.pushNamed(context, '/applications'),
            ),
            _ProfileLink(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onSignOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.ink),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ),
      ),
    );
  }
}
