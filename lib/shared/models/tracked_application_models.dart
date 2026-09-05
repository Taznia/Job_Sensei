/// Models for the Application Tracker.
///
/// A tracked application is one the user made outside Job Sensei — on LinkedIn,
/// by email, on a company site. It shares the `applications` collection with
/// job-board applications; the difference is that a tracked one has no
/// [jobId], so the applicant owns the whole status timeline.
library;

enum AppStatus { applied, reviewing, shortlisted, interview, offer, rejected, withdrawn }

extension AppStatusX on AppStatus {
  /// Wire value — matches the enum on the Node model exactly.
  String get apiValue {
    switch (this) {
      case AppStatus.applied:
        return 'applied';
      case AppStatus.reviewing:
        return 'reviewing';
      case AppStatus.shortlisted:
        return 'shortlisted';
      case AppStatus.interview:
        return 'interview';
      case AppStatus.offer:
        return 'offer';
      case AppStatus.rejected:
        return 'rejected';
      case AppStatus.withdrawn:
        return 'withdrawn';
    }
  }

  String get label {
    switch (this) {
      case AppStatus.applied:
        return 'Applied';
      case AppStatus.reviewing:
        return 'Under Review';
      case AppStatus.shortlisted:
        return 'Shortlisted';
      case AppStatus.interview:
        return 'Interview';
      case AppStatus.offer:
        return 'Offer';
      case AppStatus.rejected:
        return 'Rejected';
      case AppStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  static AppStatus fromApi(String? value) {
    switch (value) {
      case 'reviewing':
        return AppStatus.reviewing;
      case 'shortlisted':
        return AppStatus.shortlisted;
      case 'interview':
        return AppStatus.interview;
      case 'offer':
        return AppStatus.offer;
      case 'rejected':
        return AppStatus.rejected;
      case 'withdrawn':
        return AppStatus.withdrawn;
      default:
        return AppStatus.applied;
    }
  }

  /// The happy-path progression the tracker's stepper walks.
  static const List<AppStatus> pipeline = [
    AppStatus.applied,
    AppStatus.reviewing,
    AppStatus.shortlisted,
    AppStatus.interview,
    AppStatus.offer,
  ];

  /// Next step forward, or null once the application has come to rest.
  AppStatus? get nextStatus {
    final index = AppStatusX.pipeline.indexOf(this);
    if (index == -1 || index == AppStatusX.pipeline.length - 1) return null;
    return AppStatusX.pipeline[index + 1];
  }

  bool get isTerminal =>
      this == AppStatus.offer ||
      this == AppStatus.rejected ||
      this == AppStatus.withdrawn;
}

class StatusHistoryEntry {
  const StatusHistoryEntry({required this.status, required this.changedAt});

  final AppStatus status;
  final DateTime changedAt;

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: AppStatusX.fromApi(json['status']?.toString()),
      changedAt:
          DateTime.tryParse(json['changedAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

class TrackedApplication {
  const TrackedApplication({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    this.resumeId,
    this.resumeTitle = '',
    this.targetField = '',
    this.interviewDate,
    this.statusHistory = const [],
    this.createdAt,
    this.isFromJobBoard = false,
  });

  final String id;
  final String jobTitle;
  final String companyName;
  final AppStatus status;
  final String? resumeId;
  final String resumeTitle;
  final String targetField;
  final DateTime? interviewDate;
  final List<StatusHistoryEntry> statusHistory;
  final DateTime? createdAt;

  /// True when this row came from applying to a Job posting inside Job Sensei.
  /// Those are owned by the recruiter flow, so the tracker shows them read-only
  /// rather than offering its own status controls.
  final bool isFromJobBoard;

  factory TrackedApplication.fromJson(Map<String, dynamic> json) {
    final job = json['jobId'];
    final fromJobBoard = job != null;

    // A job-board application carries its title/company on the populated job.
    final jobMap = job is Map ? Map<String, dynamic>.from(job) : null;

    final rawHistory = json['statusHistory'];
    final history = <StatusHistoryEntry>[];
    if (rawHistory is List) {
      for (final entry in rawHistory) {
        if (entry is Map) {
          history.add(
            StatusHistoryEntry.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    final resume = json['resumeId'];
    final resumeMap = resume is Map ? Map<String, dynamic>.from(resume) : null;

    return TrackedApplication(
      id: json['id']?.toString() ?? '',
      jobTitle: (json['jobTitle']?.toString().isNotEmpty ?? false)
          ? json['jobTitle'].toString()
          : (jobMap?['title']?.toString() ?? 'Untitled role'),
      companyName: (json['companyName']?.toString().isNotEmpty ?? false)
          ? json['companyName'].toString()
          : (jobMap?['company']?.toString() ?? ''),
      status: AppStatusX.fromApi(json['status']?.toString()),
      resumeId: resumeMap?['id']?.toString() ?? resume?.toString(),
      resumeTitle: (json['resumeTitle']?.toString().isNotEmpty ?? false)
          ? json['resumeTitle'].toString()
          : (resumeMap?['title']?.toString() ?? ''),
      targetField: json['targetField']?.toString() ?? '',
      interviewDate:
          DateTime.tryParse(json['interviewDate']?.toString() ?? '')?.toLocal(),
      statusHistory: history,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      isFromJobBoard: fromJobBoard,
    );
  }
}
