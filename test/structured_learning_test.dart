import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/learning/data/repositories/learning_path_repository.dart';
import 'package:jobsensei_frontend/features/learning/presentation/screens/structured_learning_screen.dart';
import 'package:jobsensei_frontend/shared/models/learning_path_models.dart';

void main() {
  testWidgets('skill gap opens a structured path with lessons and resources',
      (tester) async {
    final repository = _FakeLearningPathRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: StructuredLearningScreen(
          initialSkills: const ['Docker'],
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn Docker'), findsOneWidget);
    expect(find.text('Docker Fundamentals'), findsOneWidget);

    await tester.tap(find.text('Docker Fundamentals'));
    await tester.pumpAndSettle();
    expect(find.text('Ordered lessons'), findsOneWidget);
    expect(find.text('Containers and Images'), findsOneWidget);

    await tester.tap(find.text('Containers and Images'));
    await tester.pumpAndSettle();
    expect(find.text('Learning resources'), findsOneWidget);
    expect(find.text('Docker containers and images tutorial'), findsOneWidget);
  });
}

class _FakeLearningPathRepository implements LearningPathRepository {
  final _docker = demoLearningPaths.firstWhere(
    (path) => path.skill.name == 'Docker',
  );

  @override
  Future<StructuredLearningPath> pathDetails(String pathId) async => _docker;

  @override
  Future<List<StructuredLearningPath>> pathsForSkills(
    List<String> skills,
  ) async =>
      [_docker];
}
