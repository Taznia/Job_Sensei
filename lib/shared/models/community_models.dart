import 'package:flutter/material.dart';

class CommunityGroup {
  CommunityGroup({
    required this.name,
    required this.description,
    required this.members,
    required this.icon,
    required this.color,
    this.isJoined = false,
  });

  final String name;
  final String description;
  final String members;
  final IconData icon;
  final Color color;
  bool isJoined;
}

class CommunityPost {
  CommunityPost({
    required this.author,
    required this.role,
    required this.body,
    required this.time,
    required this.tags,
    this.likes = 0,
    this.comments = 0,
  });

  final String author;
  final String role;
  final String body;
  final String time;
  final List<String> tags;
  int likes;
  int comments;
}
