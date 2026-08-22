class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'seeker',
    this.headline = '',
    this.bio = '',
    this.location = '',
    this.targetRole = '',
    this.xp = 0,
    this.badges = const [],
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String headline;
  final String bio;
  final String location;
  final String targetRole;
  final int xp;
  final List<String> badges;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'seeker',
      headline: json['headline'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      location: json['location'] as String? ?? '',
      targetRole: json['targetRole'] as String? ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
