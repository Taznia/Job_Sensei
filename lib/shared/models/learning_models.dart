import 'package:flutter/material.dart';

enum SkillPriority { high, medium, low }

class SkillGap {
  const SkillGap({
    required this.name,
    required this.category,
    required this.currentLevel,
    required this.requiredLevel,
    required this.priority,
    required this.impact,
  });

  final String name;
  final String category;
  final int currentLevel;
  final int requiredLevel;
  final SkillPriority priority;
  final String impact;
}

class LearningResource {
  const LearningResource({
    required this.title,
    required this.creator,
    required this.skill,
    required this.duration,
    required this.difficulty,
    required this.color,
    required this.icon,
    required this.url,
  });

  final String title;
  final String creator;
  final String skill;
  final String duration;
  final String difficulty;
  final Color color;
  final IconData icon;
  final String url;
}
