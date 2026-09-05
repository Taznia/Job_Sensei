import 'package:flutter/material.dart';

import '../../../../app/injector.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/resume_models.dart';
import '../../../../shared/models/tracked_application_models.dart';
import '../../../resumes/domain/repositories/resume_repository.dart';
import '../../domain/repositories/tracked_application_repository.dart';
import '../controllers/tracked_application_controller.dart';

/// Tracks every application the user has made — the ones sent through Job
/// Sensei's job board and the ones they made anywhere else.
class ApplicationTrackerScreen extends StatefulWidget {
  const ApplicationTrackerScreen({
    super.key,
    this.repository,
    this.resumeRepository,
  });

  final TrackedApplicationRepository? repository;
  final ResumeRepository? resumeRepository;

  @override
  State<ApplicationTrackerScreen> createState() =>
      _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen> {
  late final TrackedApplicationController _controller =
      TrackedApplicationController(
    widget.repository ?? Injector.trackedApplicationRepository(),
  )..addListener(_refresh);

  late final ResumeRepository _resumes =
      widget.resumeRepository ?? Injector.resumeRepository();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _addSheet() async {
    final result = await showModalBottomSheet<_TrackDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddApplicationSheet(resumeRepository: _resumes),
    );
    if (result == null) return;

    final saved = await _controller.track(
      jobTitle: result.jobTitle,
      companyName: result.companyName,
      resumeId: result.resumeId,
    );
    _showMessage(
      saved ? 'Application tracked.' : (_controller.errorMessage ?? 'Could not save.'),
      isError: !saved,
    );
  }

  Future<void> _advance(TrackedApplication application) async {
    final next = application.status.nextStatus;
    if (next == null) return;

    DateTime? interviewDate;
    if (next == AppStatus.interview) {
      interviewDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 3)),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'Interview date',
      );
    }

    final moved = await _controller.moveTo(application, next,
        interviewDate: interviewDate);
    _showMessage(
      moved
          ? 'Moved to ${next.label}.'
          : (_controller.errorMessage ?? 'Could not update.'),
      isError: !moved,
    );
  }

  Future<void> _setStatus(
      TrackedApplication application, AppStatus status) async {
    final moved = await _controller.moveTo(application, status);
    _showMessage(
      moved ? 'Marked as ${status.label}.' : (_controller.errorMessage ?? 'Could not update.'),
      isError: !moved,
    );
  }

  Future<void> _delete(TrackedApplication application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove application'),
        content: Text(
            'Stop tracking "${application.jobTitle}" at ${application.companyName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final done = await _controller.remove(application.id);
    _showMessage(
      done ? 'Removed.' : (_controller.errorMessage ?? 'Could not remove.'),
      isError: !done,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Applications')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isSaving ? null : _addSheet,
        icon: const Icon(Icons.add),
        label: const Text('Track application'),
      ),
      body: RefreshIndicator(onRefresh: _controller.load, child: _body()),
    );
  }

  Widget _body() {
    if (_controller.isLoading && !_controller.hasApplications) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && !_controller.hasApplications) {
      final needsSignIn = _controller.requiresSignIn;
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        children: [
          Icon(needsSignIn ? Icons.lock_outline : Icons.error_outline,
              size: 56, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(needsSignIn ? 'Sign in required' : 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(_controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              onPressed: needsSignIn
                  ? () => Navigator.of(context).pushNamed(AppRouter.authentication)
                  : _controller.load,
              child: Text(needsSignIn ? 'Sign in' : 'Try again'),
            ),
          ),
        ],
      );
    }

    if (!_controller.hasApplications) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        children: [
          const Icon(Icons.work_outline_rounded, size: 56, color: AppColors.muted),
          const SizedBox(height: 16),
          const Text('No applications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 8),
          const Text(
            'Track the jobs you apply to — here and anywhere else — and follow '
            'each one from applied through to an offer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
                onPressed: _addSheet,
                child: const Text('Track your first application')),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _controller.applications.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) return _summaryRow();
        return _applicationCard(_controller.applications[index - 1]);
      },
    );
  }

  Widget _summaryRow() {
    final counts = _controller.statusCounts;
    final entries = [
      (AppStatus.applied, AppColors.primary),
      (AppStatus.interview, AppColors.warning),
      (AppStatus.offer, AppColors.success),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: entries.map((entry) {
          final (status, color) = entry;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text('${counts[status] ?? 0}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(status.label,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _applicationCard(TrackedApplication application) {
    final next = application.status.nextStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.jobTitle,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(application.companyName,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.muted)),
                  ],
                ),
              ),
              _statusPill(application.status),
            ],
          ),
          if (application.resumeTitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(application.resumeTitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ),
              ],
            ),
          ],
          if (application.interviewDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 5),
                Text(
                  'Interview ${_formatDate(application.interviewDate!)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _stepper(application.status),
          if (application.isFromJobBoard) ...[
            const SizedBox(height: 10),
            const Text(
              'Applied through Job Sensei — the employer updates this status.',
              style: TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (next != null)
                  FilledButton.icon(
                    onPressed: _controller.isSaving
                        ? null
                        : () => _advance(application),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text('Move to ${next.label}'),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'rejected':
                        _setStatus(application, AppStatus.rejected);
                      case 'withdrawn':
                        _setStatus(application, AppStatus.withdrawn);
                      case 'delete':
                        _delete(application);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'rejected', child: Text('Mark rejected')),
                    PopupMenuItem(
                        value: 'withdrawn', child: Text('Mark withdrawn')),
                    PopupMenuItem(value: 'delete', child: Text('Remove')),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepper(AppStatus current) {
    // A rejected or withdrawn application left the pipeline; showing a
    // half-filled progress bar for it would misrepresent what happened.
    if (current == AppStatus.rejected || current == AppStatus.withdrawn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('${current.label} — no further steps',
            style: const TextStyle(fontSize: 11.5, color: AppColors.danger)),
      );
    }

    final pipeline = AppStatusX.pipeline;
    final currentIndex = pipeline.indexOf(current);

    return Row(
      children: List.generate(pipeline.length * 2 - 1, (index) {
        if (index.isOdd) {
          final done = (index ~/ 2) < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppColors.primary : AppColors.border,
            ),
          );
        }
        final step = index ~/ 2;
        final reached = step <= currentIndex;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? AppColors.primary : AppColors.surface,
            border: Border.all(
              color: reached ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _statusPill(AppStatus status) {
    final color = switch (status) {
      AppStatus.offer => AppColors.success,
      AppStatus.rejected || AppStatus.withdrawn => AppColors.danger,
      AppStatus.interview => AppColors.warning,
      _ => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

/// What the add sheet returns.
class _TrackDraft {
  const _TrackDraft(this.jobTitle, this.companyName, this.resumeId);
  final String jobTitle;
  final String companyName;
  final String? resumeId;
}

class _AddApplicationSheet extends StatefulWidget {
  const _AddApplicationSheet({required this.resumeRepository});

  final ResumeRepository resumeRepository;

  @override
  State<_AddApplicationSheet> createState() => _AddApplicationSheetState();
}

class _AddApplicationSheetState extends State<_AddApplicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitle = TextEditingController();
  final _company = TextEditingController();

  List<Resume> _resumes = const [];
  String? _resumeId;
  bool _loadingResumes = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    try {
      final resumes = await widget.resumeRepository.listResumes();
      if (!mounted) return;
      setState(() {
        _resumes = resumes;
        // Default to the resume the user marked as default, if there is one.
        _resumeId = resumes
            .where((resume) => resume.isDefault)
            .map((resume) => resume.id)
            .firstOrNull;
        _loadingResumes = false;
      });
    } catch (_) {
      // Attaching a resume is optional, so a failure here must not block
      // tracking an application.
      if (mounted) setState(() => _loadingResumes = false);
    }
  }

  @override
  void dispose() {
    _jobTitle.dispose();
    _company.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _TrackDraft(_jobTitle.text.trim(), _company.text.trim(), _resumeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Track an application',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text(
              'For a job you applied to anywhere — LinkedIn, email, a careers page.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _jobTitle,
              decoration: const InputDecoration(
                labelText: 'Job title',
                hintText: 'e.g. Backend Engineer',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Job title is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _company,
              decoration: const InputDecoration(
                labelText: 'Company',
                hintText: 'e.g. Acme',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Company is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            if (_loadingResumes)
              const LinearProgressIndicator()
            else if (_resumes.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _resumeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Resume used (optional)',
                  border: OutlineInputBorder(),
                ),
                items: _resumes
                    .map((resume) => DropdownMenuItem(
                          value: resume.id,
                          child: Text(resume.title,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _resumeId = value),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Start tracking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
