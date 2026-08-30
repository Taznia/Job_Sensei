import '../../../shared/models/learning_models.dart';

const kDefaultCatalogRoles = [
  'Senior Frontend Engineer',
  'Full Stack Developer',
  'Tech Lead',
  'Solutions Architect',
  'Data Scientist',
  'Product Manager',
];

List<String> mergeCatalogRoles(Iterable<String> extra) {
  final seen = <String>{};
  final out = <String>[];
  for (final role in [...kDefaultCatalogRoles, ...extra]) {
    final trimmed = role.trim();
    if (trimmed.isEmpty) continue;
    if (!seen.add(trimmed.toLowerCase())) continue;
    out.add(trimmed);
  }
  return out;
}

bool sameRole(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

const kDemoSkillLevels = <String, int>{
  'typescript': 58,
  'graphql': 15,
  'docker': 35,
  'system design': 45,
  'technical leadership': 68,
  'react': 80,
  'node.js': 42,
  'figma': 50,
  'sql': 63,
  'python': 55,
  'machine learning': 28,
  'cloud certification': 20,
  'product analytics': 40,
  'roadmapping': 48,
  'stakeholder management': 62,
  'user research': 35,
  'prioritization': 50,
};

String canonicalRole(String role) {
  for (final name in kDefaultCatalogRoles) {
    if (sameRole(name, role)) return name;
  }
  final trimmed = role.trim();
  return trimmed.isEmpty ? kDefaultCatalogRoles.first : trimmed;
}

List<RoleSkillTemplate> templatesFor(String role) {
  final resolved = canonicalRole(role);
  for (final entry in kRoleSkillCatalog.entries) {
    if (sameRole(entry.key, resolved)) return entry.value;
  }
  return kRoleSkillCatalog[kDefaultCatalogRoles.first]!;
}

RoleGapSnapshot snapshotForRole({
  required String role,
  required Map<String, int> levels,
  List<String> roles = const [],
  String targetRole = '',
}) {
  final resolved = canonicalRole(role);
  final gaps = templatesFor(resolved)
      .map((item) => item.toGap(levels[item.name.toLowerCase()] ?? 0))
      .toList();
  return RoleGapSnapshot.fromGaps(
    role: resolved,
    targetRole: targetRole,
    roles: mergeCatalogRoles([...roles, resolved]),
    gaps: gaps,
  );
}

RoleGapSnapshot overlayRoleCatalog({
  required String requestedRole,
  required RoleGapSnapshot api,
  required List<String> roles,
}) {
  final levels = <String, int>{
    ...kDemoSkillLevels,
    for (final gap in api.gaps) gap.name.toLowerCase(): gap.currentLevel,
  };
  return snapshotForRole(
    role: requestedRole,
    levels: levels,
    roles: [...roles, ...api.roles],
    targetRole: api.targetRole,
  );
}

class RoleSkillTemplate {
  const RoleSkillTemplate({
    required this.name,
    required this.category,
    required this.requiredLevel,
    required this.priority,
    required this.impact,
  });

  final String name;
  final String category;
  final int requiredLevel;
  final SkillPriority priority;
  final String impact;

  SkillGap toGap(int currentLevel) => SkillGap(
        name: name,
        category: category,
        currentLevel: currentLevel,
        requiredLevel: requiredLevel,
        priority: priority,
        impact: impact,
      );
}

const kRoleSkillCatalog = <String, List<RoleSkillTemplate>>{
  'Senior Frontend Engineer': [
    RoleSkillTemplate(
      name: 'TypeScript',
      category: 'Technical skill',
      requiredLevel: 90,
      priority: SkillPriority.high,
      impact:
          'Strong TypeScript is expected for safe, scalable frontend architecture.',
    ),
    RoleSkillTemplate(
      name: 'GraphQL',
      category: 'Technical skill',
      requiredLevel: 70,
      priority: SkillPriority.high,
      impact:
          'GraphQL experience unlocks roles working on data-heavy products.',
    ),
    RoleSkillTemplate(
      name: 'Docker',
      category: 'Software tools',
      requiredLevel: 65,
      priority: SkillPriority.medium,
      impact:
          'Docker lets you reproduce production environments with backend teams.',
    ),
    RoleSkillTemplate(
      name: 'System Design',
      category: 'Technical skill',
      requiredLevel: 82,
      priority: SkillPriority.high,
      impact:
          'Senior interviews test tradeoffs, scalability, and architecture decisions.',
    ),
    RoleSkillTemplate(
      name: 'Technical Leadership',
      category: 'Soft skill',
      requiredLevel: 85,
      priority: SkillPriority.medium,
      impact:
          'Mentoring and cross-team communication separate senior contributors.',
    ),
    RoleSkillTemplate(
      name: 'React',
      category: 'Technical skill',
      requiredLevel: 88,
      priority: SkillPriority.high,
      impact: 'Required in most senior frontend roles and design-system work.',
    ),
    RoleSkillTemplate(
      name: 'Node.js',
      category: 'Technical skill',
      requiredLevel: 60,
      priority: SkillPriority.medium,
      impact:
          'Helps frontend engineers work across the API boundary with backend teams.',
    ),
    RoleSkillTemplate(
      name: 'Figma',
      category: 'Software tools',
      requiredLevel: 55,
      priority: SkillPriority.medium,
      impact:
          'Design-system collaboration is faster when you can read and comment in Figma.',
    ),
  ],
  'Full Stack Developer': [
    RoleSkillTemplate(
      name: 'TypeScript',
      category: 'Technical skill',
      requiredLevel: 80,
      priority: SkillPriority.high,
      impact: 'Typed JavaScript is expected across modern full-stack codebases.',
    ),
    RoleSkillTemplate(
      name: 'Node.js',
      category: 'Technical skill',
      requiredLevel: 78,
      priority: SkillPriority.high,
      impact: 'Most full-stack roles need a server runtime you can ship APIs on.',
    ),
    RoleSkillTemplate(
      name: 'GraphQL',
      category: 'Technical skill',
      requiredLevel: 65,
      priority: SkillPriority.medium,
      impact: 'GraphQL is common in product APIs that serve multiple clients.',
    ),
    RoleSkillTemplate(
      name: 'Docker',
      category: 'Software tools',
      requiredLevel: 70,
      priority: SkillPriority.high,
      impact: 'Containers are how full-stack services are built and deployed.',
    ),
    RoleSkillTemplate(
      name: 'SQL',
      category: 'Software tools',
      requiredLevel: 72,
      priority: SkillPriority.medium,
      impact: 'You will query and model relational data without a specialist.',
    ),
  ],
  'Tech Lead': [
    RoleSkillTemplate(
      name: 'System Design',
      category: 'Technical skill',
      requiredLevel: 88,
      priority: SkillPriority.high,
      impact: 'Leads own architecture tradeoffs for reliability and scale.',
    ),
    RoleSkillTemplate(
      name: 'Technical Leadership',
      category: 'Soft skill',
      requiredLevel: 90,
      priority: SkillPriority.high,
      impact: 'Mentoring and decision-making define the lead role.',
    ),
    RoleSkillTemplate(
      name: 'TypeScript',
      category: 'Technical skill',
      requiredLevel: 75,
      priority: SkillPriority.medium,
      impact: 'Leads still review production frontend and node services.',
    ),
    RoleSkillTemplate(
      name: 'Docker',
      category: 'Software tools',
      requiredLevel: 70,
      priority: SkillPriority.medium,
      impact: 'Delivery ownership includes local environments and deploy pipelines.',
    ),
  ],
  'Solutions Architect': [
    RoleSkillTemplate(
      name: 'System Design',
      category: 'Technical skill',
      requiredLevel: 92,
      priority: SkillPriority.high,
      impact: 'Architecture interviews and client proposals both test system design.',
    ),
    RoleSkillTemplate(
      name: 'Cloud Certification',
      category: 'Certifications',
      requiredLevel: 70,
      priority: SkillPriority.high,
      impact: 'A cloud credential signals you can map workloads onto a provider.',
    ),
    RoleSkillTemplate(
      name: 'Docker',
      category: 'Software tools',
      requiredLevel: 75,
      priority: SkillPriority.medium,
      impact: 'Container boundaries are part of most reference architectures.',
    ),
    RoleSkillTemplate(
      name: 'Technical Leadership',
      category: 'Soft skill',
      requiredLevel: 80,
      priority: SkillPriority.medium,
      impact: 'Architects align engineering, product, and stakeholders.',
    ),
  ],
  'Data Scientist': [
    RoleSkillTemplate(
      name: 'Python',
      category: 'Technical skill',
      requiredLevel: 88,
      priority: SkillPriority.medium,
      impact:
          'Production Python supports reproducible analysis and reliable ML pipelines.',
    ),
    RoleSkillTemplate(
      name: 'Machine Learning',
      category: 'Technical skill',
      requiredLevel: 85,
      priority: SkillPriority.high,
      impact:
          'Model selection, evaluation, and feature engineering are central hiring signals.',
    ),
    RoleSkillTemplate(
      name: 'SQL',
      category: 'Software tools',
      requiredLevel: 86,
      priority: SkillPriority.high,
      impact:
          'Most data roles require independent exploration of large relational datasets.',
    ),
    RoleSkillTemplate(
      name: 'Cloud Certification',
      category: 'Certifications',
      requiredLevel: 55,
      priority: SkillPriority.low,
      impact: 'A cloud credential validates familiarity with deployed data workloads.',
    ),
  ],
  'Product Manager': [
    RoleSkillTemplate(
      name: 'Product Analytics',
      category: 'Software tools',
      requiredLevel: 85,
      priority: SkillPriority.high,
      impact:
          'Analytics turns product choices into measurable hypotheses and outcomes.',
    ),
    RoleSkillTemplate(
      name: 'Roadmapping',
      category: 'Product Strategy',
      requiredLevel: 80,
      priority: SkillPriority.medium,
      impact: 'A clear roadmap communicates tradeoffs and keeps teams aligned.',
    ),
    RoleSkillTemplate(
      name: 'Stakeholder Management',
      category: 'Soft skill',
      requiredLevel: 85,
      priority: SkillPriority.high,
      impact:
          'Product managers align customers, business leaders, and engineers.',
    ),
    RoleSkillTemplate(
      name: 'User Research',
      category: 'Product Discovery',
      requiredLevel: 70,
      priority: SkillPriority.medium,
      impact:
          'User research reveals the real problems a product should solve.',
    ),
  ],
};
