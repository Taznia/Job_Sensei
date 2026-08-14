import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

abstract final class CommunityVisuals {
  static const keys = [
    'code',
    'product',
    'data',
    'flutter',
    'design',
    'graduate'
  ];

  static IconData iconFor(String key) => switch (key) {
        'product' => Icons.view_kanban_rounded,
        'data' => Icons.query_stats_rounded,
        'flutter' => Icons.flutter_dash_rounded,
        'design' => Icons.palette_outlined,
        'graduate' => Icons.school_rounded,
        _ => Icons.code_rounded,
      };

  static Color colorFor(String key) => switch (key) {
        'product' => AppColors.violet,
        'data' => AppColors.success,
        'flutter' => AppColors.cyan,
        'design' => AppColors.danger,
        'graduate' => AppColors.warning,
        _ => AppColors.primary,
      };

  static String labelFor(String key) => switch (key) {
        'product' => 'Product',
        'data' => 'Data',
        'flutter' => 'Mobile',
        'design' => 'Design',
        'graduate' => 'Graduate',
        _ => 'Code',
      };

  static String memberCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}m';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  static String fileSize(int bytes) {
    if (bytes >= 1000000) return '${(bytes / 1000000).toStringAsFixed(1)} MB';
    if (bytes >= 1000) return '${(bytes / 1000).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  static String relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
