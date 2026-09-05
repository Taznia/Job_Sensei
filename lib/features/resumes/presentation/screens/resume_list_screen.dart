import 'package:flutter/material.dart';

import '../../../../app/injector.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/resume_models.dart';
import '../../domain/repositories/resume_repository.dart';
import '../controllers/resume_controller.dart';
import 'resume_editor_screen.dart';
import 'resume_preview_screen.dart';

/// The resumes tab: list, create, edit, duplicate, preview/export, delete.
class ResumeListScreen extends StatefulWidget {
  const ResumeListScreen({super.key, this.repository});

  /// Injected in tests; defaults to the API-backed repository.
  final ResumeRepository? repository;

  @override
  State<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends State<ResumeListScreen> {
  late final ResumeController _controller = ResumeController(
    widget.repository ?? Injector.resumeRepository(),
  )..addListener(_refresh);

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

  Future<void> _create() async {
    final draft = await Navigator.of(context).push<ResumeDraft>(
      MaterialPageRoute(builder: (_) => const ResumeEditorScreen()),
    );
    if (draft == null) return;

    final saved = await _controller.create(draft);
    _showMessage(
      saved ? 'Resume created.' : (_controller.errorMessage ?? 'Could not save.'),
      isError: !saved,
    );
  }

  Future<void> _edit(Resume resume) async {
    final draft = await Navigator.of(context).push<ResumeDraft>(
      MaterialPageRoute(builder: (_) => ResumeEditorScreen(resume: resume)),
    );
    if (draft == null) return;

    final saved = await _controller.update(resume.id, draft);
    _showMessage(
      saved ? 'Resume updated.' : (_controller.errorMessage ?? 'Could not save.'),
      isError: !saved,
    );
  }

  Future<void> _delete(Resume resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resume'),
        content: Text('Delete "${resume.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final done = await _controller.remove(resume.id);
    _showMessage(
      done ? 'Resume deleted.' : (_controller.errorMessage ?? 'Could not delete.'),
      isError: !done,
    );
  }

  Future<void> _duplicate(Resume resume) async {
    final done = await _controller.duplicate(resume);
    _showMessage(
      done ? 'Resume duplicated.' : (_controller.errorMessage ?? 'Could not duplicate.'),
      isError: !done,
    );
  }

  Future<void> _setDefault(Resume resume) async {
    final done = await _controller.setDefault(resume.id);
    _showMessage(
      done ? '"${resume.title}" is now your default.' : (_controller.errorMessage ?? 'Could not update.'),
      isError: !done,
    );
  }

  void _preview(Resume resume) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResumePreviewScreen(resume: resume)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My resumes'),
        actions: [
          IconButton(
            tooltip: 'AI Resume Match',
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.resumeMatch),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isSaving ? null : _create,
        icon: const Icon(Icons.add),
        label: const Text('New resume'),
      ),
      body: RefreshIndicator(
        onRefresh: _controller.load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_controller.isLoading && !_controller.hasResumes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && !_controller.hasResumes) {
      return _message(
        icon: _controller.requiresSignIn ? Icons.lock_outline : Icons.error_outline,
        title: _controller.requiresSignIn ? 'Sign in required' : 'Something went wrong',
        body: _controller.errorMessage!,
        actionLabel: _controller.requiresSignIn ? 'Sign in' : 'Try again',
        onAction: _controller.requiresSignIn
            ? () => Navigator.of(context).pushNamed(AppRouter.authentication)
            : _controller.load,
      );
    }

    if (!_controller.hasResumes) {
      return _message(
        icon: Icons.description_outlined,
        title: 'No resumes yet',
        body: 'Build a resume once, then tailor it for every job you apply to.',
        actionLabel: 'Create your first resume',
        onAction: _create,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _controller.resumes.length,
      itemBuilder: (_, index) => _resumeCard(_controller.resumes[index]),
    );
  }

  Widget _resumeCard(Resume resume) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _preview(resume),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                resume.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink),
                              ),
                            ),
                            if (resume.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Default',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success)),
                              ),
                            ],
                          ],
                        ),
                        if (resume.targetField.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(resume.targetField,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.primary)),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _edit(resume);
                        case 'duplicate':
                          _duplicate(resume);
                        case 'default':
                          _setDefault(resume);
                        case 'delete':
                          _delete(resume);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'duplicate', child: Text('Duplicate')),
                      if (!resume.isDefault)
                        const PopupMenuItem(
                            value: 'default', child: Text('Set as default')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              if (resume.skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resume.skills.take(5).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(skill,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.muted)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _preview(resume),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Preview / PDF'),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _edit(resume),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    // Wrapped in a scroll view so RefreshIndicator still works when empty.
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(icon, size: 56, color: AppColors.muted),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 20),
        Center(
          child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    );
  }
}
