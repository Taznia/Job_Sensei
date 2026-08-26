class LearningSkill {
  const LearningSkill({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final String category;

  factory LearningSkill.fromJson(Map<String, dynamic> json) => LearningSkill(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'General',
      );
}

class StructuredLearningPath {
  const StructuredLearningPath({
    required this.id,
    required this.skill,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedDuration,
    required this.lessons,
    this.declaredLessonCount,
  });

  final String id;
  final LearningSkill skill;
  final String title;
  final String description;
  final String difficulty;
  final String estimatedDuration;
  final List<LearningLesson> lessons;
  final int? declaredLessonCount;

  int get lessonCount =>
      lessons.isNotEmpty ? lessons.length : (declaredLessonCount ?? 0);

  factory StructuredLearningPath.fromJson(Map<String, dynamic> json) {
    return StructuredLearningPath(
      id: json['id'] as String,
      skill: LearningSkill.fromJson(json['skill'] as Map<String, dynamic>),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      estimatedDuration: json['estimatedDuration'] as String? ?? 'Self-paced',
      declaredLessonCount: json['lessonCount'] as int?,
      lessons: (json['lessons'] as List<dynamic>? ?? const [])
          .map((item) => LearningLesson.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.estimatedDuration,
    this.resources = const [],
  });

  final String id;
  final String title;
  final String description;
  final int orderIndex;
  final String estimatedDuration;
  final List<LessonResource> resources;

  factory LearningLesson.fromJson(Map<String, dynamic> json) => LearningLesson(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        orderIndex: json['orderIndex'] as int? ?? 1,
        estimatedDuration: json['estimatedDuration'] as String? ?? '30 min',
        resources: (json['resources'] as List<dynamic>? ?? const [])
            .map(
              (item) => LessonResource.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

class LessonResource {
  const LessonResource({
    required this.id,
    required this.title,
    required this.url,
    required this.platform,
    required this.resourceType,
  });

  final String id;
  final String title;
  final String url;
  final String platform;
  final String resourceType;

  factory LessonResource.fromJson(Map<String, dynamic> json) => LessonResource(
        id: json['id'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        platform: json['platform'] as String? ?? 'other',
        resourceType: json['resourceType'] as String? ?? 'video',
      );
}

const demoLearningPaths = <StructuredLearningPath>[
  StructuredLearningPath(
    id: 'flutter-state-management',
    skill: LearningSkill(
      id: 'state-management',
      name: 'State Management',
      category: 'Mobile Development',
    ),
    title: 'Flutter State Management',
    description:
        'Build predictable Flutter features with clear state ownership and repository-driven data flows.',
    difficulty: 'intermediate',
    estimatedDuration: '6 hours',
    lessons: [
      LearningLesson(
        id: 'state-1',
        title: 'State Ownership',
        description:
            'Decide where state should live and which widgets should observe it.',
        orderIndex: 1,
        estimatedDuration: '45 min',
        resources: [
          LessonResource(
            id: 'state-resource-1',
            title: 'Flutter state management concepts',
            url:
                'https://www.youtube.com/results?search_query=flutter+state+management+concepts',
            platform: 'youtube',
            resourceType: 'video',
          ),
        ],
      ),
      LearningLesson(
        id: 'state-2',
        title: 'Controller and Repository Flow',
        description:
            'Separate presentation state from data access and side effects.',
        orderIndex: 2,
        estimatedDuration: '75 min',
      ),
      LearningLesson(
        id: 'state-3',
        title: 'Loading, Error, and Empty States',
        description: 'Represent asynchronous UI states explicitly.',
        orderIndex: 3,
        estimatedDuration: '60 min',
      ),
    ],
  ),
  StructuredLearningPath(
    id: 'docker-basics',
    skill: LearningSkill(
      id: 'docker',
      name: 'Docker',
      category: 'DevOps',
    ),
    title: 'Docker Fundamentals',
    description:
        'Learn images, containers, Dockerfiles, networking, and deployment workflows.',
    difficulty: 'beginner',
    estimatedDuration: '5 hours',
    lessons: [
      LearningLesson(
        id: 'docker-1',
        title: 'Containers and Images',
        description: 'Understand images, containers, and the Docker workflow.',
        orderIndex: 1,
        estimatedDuration: '45 min',
        resources: [
          LessonResource(
            id: 'docker-resource-1',
            title: 'Docker containers and images tutorial',
            url:
                'https://www.youtube.com/results?search_query=docker+containers+images+tutorial',
            platform: 'youtube',
            resourceType: 'video',
          ),
        ],
      ),
      LearningLesson(
        id: 'docker-2',
        title: 'Writing Dockerfiles',
        description: 'Build repeatable application images.',
        orderIndex: 2,
        estimatedDuration: '60 min',
      ),
      LearningLesson(
        id: 'docker-3',
        title: 'Compose and Networking',
        description: 'Run connected application services locally.',
        orderIndex: 3,
        estimatedDuration: '75 min',
      ),
    ],
  ),
  StructuredLearningPath(
    id: 'django-beginner',
    skill: LearningSkill(
      id: 'django',
      name: 'Django',
      category: 'Web Development',
    ),
    title: 'Django Beginner Path',
    description: 'Build a secure Django application with models and REST APIs.',
    difficulty: 'beginner',
    estimatedDuration: '8 hours',
    lessons: [
      LearningLesson(
        id: 'django-1',
        title: 'Project Setup',
        description: 'Understand projects, apps, settings, and URLs.',
        orderIndex: 1,
        estimatedDuration: '60 min',
      ),
      LearningLesson(
        id: 'django-2',
        title: 'Models and Database',
        description: 'Define models, migrations, and relational data.',
        orderIndex: 2,
        estimatedDuration: '75 min',
      ),
      LearningLesson(
        id: 'django-3',
        title: 'Building REST APIs',
        description: 'Expose validated data through REST endpoints.',
        orderIndex: 3,
        estimatedDuration: '90 min',
      ),
    ],
  ),
];
