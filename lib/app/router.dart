import 'package:flutter/material.dart';

import '../features/admin/admin_page.dart';
import '../features/ai/presentation/screens/ai_chat_screen.dart';
import '../features/applications/applications_page.dart';
import '../features/authentication/authentication_page.dart';
import '../features/community/presentation/screens/community_screen.dart';
import '../features/jobs/jobs_page.dart';
import '../features/learning/presentation/screens/learning_resources_screen.dart';
import '../features/learning/presentation/screens/skill_gap_screen.dart';
import '../features/notifications/notifications_page.dart';
import '../features/profile/profile_page.dart';
import '../features/resumes/resumes_page.dart';

abstract final class AppRouter {
  static const home = '/';
  static const authentication = '/authentication';
  static const profile = '/profile';
  static const jobs = '/jobs';
  static const resumes = '/resumes';
  static const applications = '/applications';
  static const ai = '/ai';
  static const learning = '/learning';
  static const skillGap = '/skill-gap';
  static const community = '/community';
  static const notifications = '/notifications';
  static const admin = '/admin';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      home => (_) => const AppShell(),
      authentication => (_) => const AuthenticationPage(),
      profile => (_) => const ProfilePage(),
      jobs => (_) => const JobsPage(),
      resumes => (_) => const ResumesPage(),
      applications => (_) => const ApplicationsPage(),
      ai => (_) => const AiChatScreen(),
      learning => (_) => const LearningResourcesScreen(),
      skillGap => (_) => const SkillGapScreen(),
      community => (_) => const CommunityScreen(),
      notifications => (_) => const NotificationsPage(),
      admin => (_) => const AdminPage(),
      _ => (_) => const AppShell(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.groups_2_outlined),
      selectedIcon: Icon(Icons.groups_2_rounded),
      label: 'Community',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome_rounded),
      label: 'AI Sensei',
    ),
    NavigationDestination(
      icon: Icon(Icons.donut_large_outlined),
      selectedIcon: Icon(Icons.donut_large_rounded),
      label: 'Skill Gap',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school_rounded),
      label: 'Learn',
    ),
  ];

  static const _screens = [
    CommunityScreen(),
    AiChatScreen(),
    SkillGapScreen(),
    LearningResourcesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final content = IndexedStack(index: _index, children: _screens);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    extended: constraints.maxWidth >= 1100,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: _BrandMark(),
                    ),
                    destinations: _destinations
                        .map((item) => NavigationRailDestination(
                              icon: item.icon,
                              selectedIcon: item.selectedIcon,
                              label: Text(item.label),
                            ))
                        .toList(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: _destinations,
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.psychology_alt_rounded,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        if (MediaQuery.sizeOf(context).width >= 1100)
          const Text(
            'Job Sensei',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
      ],
    );
  }
}
