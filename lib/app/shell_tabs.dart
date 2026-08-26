import 'package:flutter/foundation.dart';

/// Lets nested screens (Profile → Skill Gap) switch the seeker shell tab
/// instead of pushing a second Learn page on top of the bottom nav.
abstract final class ShellTabs {
  static final ValueNotifier<String?> request = ValueNotifier<String?>(null);

  static void openLearn() {
    request.value = null;
    request.value = 'learn';
  }
}
