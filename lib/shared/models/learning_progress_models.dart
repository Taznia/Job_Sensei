class LearningProgress {
  const LearningProgress({
    required this.resourceId,
    required this.status,
  });

  final String resourceId;
  final String status;

  bool get completed => status == 'completed';
}
