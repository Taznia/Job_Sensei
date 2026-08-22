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
import '../features/profile/presentation/screens/career_profile_screen.dart';
import '../features/resumes/resumes_page.dart';
import '../core/constants/app_colors.dart';
import 'injector.dart';

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
      profile => (_) => CareerProfileScreen(
            repository: Injector.careerProfileRepository(),
          ),
      jobs => (_) => const JobsPage(),
      resumes => (_) => const ResumesPage(),
      applications => (_) => const ApplicationsPage(),
      ai => (_) => AiChatScreen(
            service: Injector.chatService(),
            historyRepository: Injector.chatHistoryRepository(),
            attachmentPicker: Injector.aiAttachmentPickerService(),
          ),
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

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Order matches _screens below; the shell renders both from the same index.
  static const _items = <_NavItem>[
    _NavItem('Community', Icons.groups_2_outlined, Icons.groups_2_rounded),
    _NavItem('AI Sensei', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
    _NavItem('Skill Gap', Icons.donut_large_outlined, Icons.donut_large_rounded),
    _NavItem('Learn', Icons.school_outlined, Icons.school_rounded),
    _NavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  late final List<Widget> _screens = [
    CommunityScreen(repository: Injector.communityRepository()),
    AiChatScreen(
      service: Injector.chatService(),
      historyRepository: Injector.chatHistoryRepository(),
      attachmentPicker: Injector.aiAttachmentPickerService(),
    ),
    const SkillGapScreen(),
    const LearningResourcesScreen(),
    CareerProfileScreen(repository: Injector.careerProfileRepository()),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final content = IndexedStack(
          index: _index,
          children: _screens.indexed.map((entry) {
            return TickerMode(
              enabled: entry.$1 == _index,
              child: entry.$2,
            );
          }).toList(),
        );

        if (wide) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                ColoredBox(
                  color: Colors.white,
                  child: SafeArea(
                    child: NavigationRail(
                      backgroundColor: Colors.white,
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      extended: constraints.maxWidth >= 1100,
                      indicatorColor: const Color(0xFFF3F6FB),
                      selectedIconTheme:
                          const IconThemeData(color: AppColors.primary, size: 22),
                      unselectedIconTheme:
                          const IconThemeData(color: AppColors.muted, size: 22),
                      selectedLabelTextStyle: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      unselectedLabelTextStyle: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: _BrandMark(),
                      ),
                      destinations: _items
                          .map(
                            (item) => NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.activeIcon),
                              label: Text(item.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: content,
          bottomNavigationBar: _MinimalBottomBar(
            items: _items,
            selectedIndex: _index,
            onSelect: (value) => setState(() => _index = value),
          ),
        );
      },
    );
  }
}

class _MinimalBottomBar extends StatelessWidget {
  const _MinimalBottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _MinimalNavButton(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalNavButton extends StatelessWidget {
  const _MinimalNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primary.withValues(alpha: 0.06),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1,
              letterSpacing: 0,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
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
        Icon(
          Icons.psychology_alt_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
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
