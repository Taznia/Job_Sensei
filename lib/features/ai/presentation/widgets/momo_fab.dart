import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'ai_buddy.dart';

class MomoFab extends StatelessWidget {
  const MomoFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8F3FF),
      elevation: 5,
      shadowColor: AppColors.primary.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(6, 4, 16, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AiBuddy(size: 42),
              SizedBox(width: 2),
              Text(
                'AI Sensei',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
