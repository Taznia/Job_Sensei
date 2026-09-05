import 'package:flutter/material.dart';

import '../../../../app/injector.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/resume_match_models.dart';
import '../../../../shared/models/resume_models.dart';
import '../../../resumes/domain/repositories/resume_repository.dart';
import '../../domain/repositories/resume_match_repository.dart';
import '../controllers/resume_match_controller.dart';

/// Scores one of the user's resumes against a pasted job description and shows
/// what to change.
///
/// Distinct from the AI chat coach: this returns structured, saved advice
/// rather than a conversation.
class ResumeMatchScreen extends StatefulWidget {
  const ResumeMatchScreen({super.key, this.repository, this.resumeRepository});

  final ResumeMatchRepository? repository;
  final ResumeRepository? resumeRepository;

  @override
  State<ResumeMatchScreen> createState() => _ResumeMatchScreenState();
}

class _ResumeMatchScreenState extends State<ResumeMatchScreen>
    with SingleTickerProviderStateMixin {
  late final ResumeMatchController _controller = ResumeMatchController(
    widget.repository ?? Injector.resumeMatchRepository(),
  )..addListener(_refresh);

  late final ResumeRepository _resumeRepository =
      widget.resumeRepository ?? Injector.resumeRepository();

  late final TabController _tabs = TabController(length: 2, vsync: this);
  final TextEditingController _jobDescription = TextEditingController();

  List<Resume> _resumes = const [];
  String? _resumeId;
  bool _loadingResumes = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
    _controller.loadHistory();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _tabs.dispose();
    _jobDescription.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadResumes() async {
    try {
      final resumes = await _resumeRepository.listResumes();
      if (!mounted) return;
      setState(() {
        _resumes = resumes;
        _resumeId = resumes
                .where((resume) => resume.isDefault)
                .map((resume) => resume.id)
                .firstOrNull ??
            (resumes.isNotEmpty ? resumes.first.id : null);
        _loadingResumes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingResumes = false);
    }
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

  Future<void> _analyse() async {
    final resumeId = _resumeId;
    if (resumeId == null) {
      _showMessage('Create a resume first.', isError: true);
      return;
    }
    final description = _jobDescription.text.trim();
    if (description.length < 20) {
      _showMessage('Paste a longer job description.', isError: true);
      return;
    }

    final ok = await _controller.analyse(
      resumeId: resumeId,
      jobDescription: description,
    );
    if (!ok) {
      _showMessage(_controller.errorMessage ?? 'The analysis failed.',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Resume Match'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Analyse'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_analyseTab(), _historyTab()],
      ),
    );
  }

  Widget _analyseTab() {
    if (_loadingResumes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_resumes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        children: [
          const Icon(Icons.description_outlined, size: 56, color: AppColors.muted),
          const SizedBox(height: 16),
          const Text('No resumes to analyse',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink)),
          const SizedBox(height: 8),
          const Text('Build a resume first, then match it against a job.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.resumes),
              child: const Text('Go to resumes'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _resumeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Resume',
                  border: OutlineInputBorder(),
                ),
                items: _resumes
                    .map((resume) => DropdownMenuItem(
                          value: resume.id,
                          child:
                              Text(resume.title, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _resumeId = value),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _jobDescription,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Job description',
                  hintText: 'Paste the full job posting here…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _controller.isAnalysing ? null : _analyse,
                  icon: _controller.isAnalysing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_controller.isAnalysing
                      ? 'Analysing…'
                      : 'Analyse match'),
                ),
              ),
            ],
          ),
        ),
        if (_controller.result != null) ...[
          const SizedBox(height: 18),
          _resultView(_controller.result!),
        ],
      ],
    );
  }

  Widget _historyTab() {
    if (_controller.isLoadingHistory && _controller.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Your past analyses will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _controller.history.length,
        itemBuilder: (_, index) {
          final match = _controller.history[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: _scoreBadge(match.matchScore),
              title: Text(match.resumeTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                match.jobDescription.length > 70
                    ? '${match.jobDescription.substring(0, 70)}…'
                    : match.jobDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  final done = await _controller.remove(match.id);
                  if (!done) {
                    _showMessage(_controller.errorMessage ?? 'Could not delete.',
                        isError: true);
                  }
                },
              ),
              onTap: () {
                _controller.showFromHistory(match);
                _tabs.animateTo(0);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _resultView(ResumeMatch match) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _scoreBadge(match.matchScore, large: true),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  match.overallFeedback,
                  style: const TextStyle(color: AppColors.ink, height: 1.4),
                ),
              ),
            ],
          ),
          _chipSection('Matched keywords', match.strongKeywords, AppColors.success),
          _chipSection('Add these keywords', match.recommendedKeywords, AppColors.warning),
          _chipSection('Suggested skill order', match.skillOrdering, AppColors.primary),
          _bulletSection('Strengths', match.strengths, AppColors.success),
          _bulletSection('Gaps', match.gaps, AppColors.danger),
          if (match.summaryImprovement.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Improved summary',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(match.summaryImprovement,
                  style: const TextStyle(height: 1.4)),
            ),
          ],
          for (final highlight in match.projectHighlights) ...[
            const SizedBox(height: 16),
            Text('Highlight: ${highlight.project}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.ink)),
            if (highlight.reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(highlight.reason,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.muted)),
            ],
            const SizedBox(height: 6),
            ...highlight.suggestedBullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(color: AppColors.primary)),
                    Expanded(child: Text(bullet, style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipSection(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(item,
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _bulletSection(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 7, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item, style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBadge(int score, {bool large = false}) {
    final color = score >= 75
        ? AppColors.success
        : score >= 45
            ? AppColors.warning
            : AppColors.danger;
    final size = large ? 64.0 : 42.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text('$score',
          style: TextStyle(
              fontSize: large ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}
