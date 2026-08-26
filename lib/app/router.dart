import 'package:flutter/material.dart';

import '../features/admin/admin_page.dart';
import '../features/ai/presentation/screens/ai_chat_screen.dart';
import '../features/applications/applications_page.dart';
import '../features/authentication/authentication_page.dart';
import '../features/authentication/role_account_page.dart';
import '../features/community/presentation/screens/community_screen.dart';
import '../features/jobs/jobs_page.dart';
import '../features/jobs/job_models.dart';
import '../features/home/seeker_home_page.dart';
import '../features/learning/presentation/screens/learning_hub_screen.dart';
import '../features/notifications/notifications_page.dart';
import '../features/profile/presentation/screens/career_profile_screen.dart';
import '../features/resumes/resumes_page.dart';
import '../core/constants/app_colors.dart';
import 'injector.dart';
import 'shell_tabs.dart';

abstract final class AppRouter {
  static const home = '/';
  static const authentication = '/authentication';
  static const login = '/login';
  static const register = '/register';
  static const account = '/account';
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
      home => (_) => const AuthGate(),
      authentication => (_) => const AuthenticationPage(),
      login => (_) => const AuthenticationPage(),
      register => (_) => const AuthenticationPage(register: true),
      profile => (_) => _RoleGuard(
            allowedRoles: const {'seeker'},
            child: CareerProfileScreen(
              repository: Injector.careerProfileRepository(),
            ),
          ),
      jobs => (_) => const JobsPage(),
      resumes => (_) => const _RoleGuard(
            allowedRoles: {'seeker'},
            child: ResumesPage(),
          ),
      applications => (_) => const ApplicationsPage(),
      ai => (_) => _RoleGuard(
            allowedRoles: const {'seeker'},
            child: AiChatScreen(
              service: Injector.chatService(),
              historyRepository: Injector.chatHistoryRepository(),
              attachmentPicker: Injector.aiAttachmentPickerService(),
            ),
          ),
      learning => (_) {
          final argument = settings.arguments;
          return _RoleGuard(
            allowedRoles: const {'seeker'},
            child: argument is JobPosting
                ? LearningHubScreen(initialJob: argument)
                : const LearningHubScreen(),
          );
        },
      skillGap => (_) => const _OpenLearnTab(),
      community => (_) => const CommunityScreen(),
      notifications => (_) => const NotificationsPage(),
      admin => (_) => const _RoleGuard(
            allowedRoles: {'admin'},
            child: AdminPage(),
          ),
      account => (_) => const RoleAccountPage(),
      _ => (_) => const AppShell(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }
}

class _OpenLearnTab extends StatefulWidget {
  const _OpenLearnTab();

  @override
  State<_OpenLearnTab> createState() => _OpenLearnTabState();
}

class _OpenLearnTabState extends State<_OpenLearnTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShellTabs.openLearn();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RoleGuard extends StatelessWidget {
  const _RoleGuard({
    required this.allowedRoles,
    required this.child,
  });

  final Set<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final role = Injector.authService().currentUser?.role;
    if (role != null && allowedRoles.contains(role)) return child;
    return Scaffold(
      appBar: AppBar(title: const Text('Access restricted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: AppColors.muted,
              ),
              const SizedBox(height: 14),
              const Text(
                'This feature is not available for your account type.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRouter.home, (route) => false),
                child: const Text('Back to my home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final auth = Injector.authService();
    if (auth.currentUser == null) {
      return AuthenticationPage(
        onAuthChanged: () => setState(() {}),
      );
    }
    return const AppShell();
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

  late final List<_NavItem> _items;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    ShellTabs.request.addListener(_onTabRequest);
    final role = Injector.authService().currentUser?.role ?? 'seeker';
    switch (role) {
      case 'recruiter':
        _items = const [
          _NavItem(
            'Job Posts',
            Icons.work_outline_rounded,
            Icons.work_rounded,
          ),
          _NavItem(
            'Applicants',
            Icons.people_outline_rounded,
            Icons.people_rounded,
          ),
          _NavItem(
            'Community',
            Icons.groups_2_outlined,
            Icons.groups_2_rounded,
          ),
          _NavItem(
            'Account',
            Icons.manage_accounts_outlined,
            Icons.manage_accounts_rounded,
          ),
        ];
        _screens = [
          const JobsPage(),
          const ApplicationsPage(),
          CommunityScreen(repository: Injector.communityRepository()),
          const RoleAccountPage(),
        ];
        break;
      case 'admin':
        _items = const [
          _NavItem(
            'Admin',
            Icons.admin_panel_settings_outlined,
            Icons.admin_panel_settings_rounded,
          ),
          _NavItem('Jobs', Icons.work_outline_rounded, Icons.work_rounded),
          _NavItem(
            'Community',
            Icons.groups_2_outlined,
            Icons.groups_2_rounded,
          ),
          _NavItem(
            'Account',
            Icons.manage_accounts_outlined,
            Icons.manage_accounts_rounded,
          ),
        ];
        _screens = [
          const AdminPage(),
          const JobsPage(),
          CommunityScreen(repository: Injector.communityRepository()),
          const RoleAccountPage(),
        ];
        break;
      default:
        _items = const [
          _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
          _NavItem('Jobs', Icons.work_outline_rounded, Icons.work_rounded),
          _NavItem('Learn', Icons.school_outlined, Icons.school_rounded),
          _NavItem(
            'Community',
            Icons.groups_2_outlined,
            Icons.groups_2_rounded,
          ),
          _NavItem(
            'Profile',
            Icons.person_outline_rounded,
            Icons.person_rounded,
          ),
        ];
        _screens = [
          const SeekerHomePage(),
          const JobsPage(),
          const LearningHubScreen(),
          CommunityScreen(repository: Injector.communityRepository()),
          CareerProfileScreen(
            repository: Injector.careerProfileRepository(),
          ),
        ];
        break;
    }
  }

  void _onTabRequest() {
    final request = ShellTabs.request.value;
    if (request != 'learn') return;
    final index = _screens.indexWhere((screen) => screen is LearningHubScreen);
    if (index < 0 || index == _index) return;
    setState(() => _index = index);
  }

  @override
  void dispose() {
    ShellTabs.request.removeListener(_onTabRequest);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final isSeeker = Injector.authService().currentUser?.role == null ||
            Injector.authService().currentUser?.role == 'seeker';
        final aiFab = isSeeker
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AiChatScreen(
                      service: Injector.chatService(),
                      historyRepository: Injector.chatHistoryRepository(),
                      attachmentPicker: Injector.aiAttachmentPickerService(),
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('AI Sensei'),
              )
            : null;
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
            floatingActionButton: aiFab,
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
                      selectedIconTheme: const IconThemeData(
                          color: AppColors.primary, size: 22),
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
          floatingActionButton: aiFab,
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
    final extended = MediaQuery.sizeOf(context).width >= 1100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Image.asset(
        'assets/logos/logo.png',
        height: extended ? 28 : 22,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
