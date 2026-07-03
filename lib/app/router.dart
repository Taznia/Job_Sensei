import 'package:flutter/material.dart';

import '../features/admin/admin_page.dart';
import '../features/ai/ai_page.dart';
import '../features/applications/applications_page.dart';
import '../features/authentication/authentication_page.dart';
import '../features/community/community_page.dart';
import '../features/jobs/jobs_page.dart';
import '../features/learning/learning_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/profile/profile_page.dart';
import '../features/resumes/resumes_page.dart';

class AppRouter {
  static const String authentication = '/authentication';
  static const String profile = '/profile';
  static const String jobs = '/jobs';
  static const String resumes = '/resumes';
  static const String applications = '/applications';
  static const String ai = '/ai';
  static const String learning = '/learning';
  static const String community = '/community';
  static const String notifications = '/notifications';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> routes = {
    authentication: (_) => const AuthenticationPage(),
    profile: (_) => const ProfilePage(),
    jobs: (_) => const JobsPage(),
    resumes: (_) => const ResumesPage(),
    applications: (_) => const ApplicationsPage(),
    ai: (_) => const AiPage(),
    learning: (_) => const LearningPage(),
    community: (_) => const CommunityPage(),
    notifications: (_) => const NotificationsPage(),
    admin: (_) => const AdminPage(),
  };
}
