import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/resume_models.dart';

/// Create/edit form for a resume.
///
/// Pops with the [ResumeDraft] the user built, or null if they backed out. The
/// caller owns persistence, which keeps this screen usable from anywhere that
/// needs a resume authored.
class ResumeEditorScreen extends StatefulWidget {
  const ResumeEditorScreen({super.key, this.resume, this.isSaving = false});

  /// Null when creating a new resume.
  final Resume? resume;
  final bool isSaving;

  @override
  State<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends State<ResumeEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _targetField;
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _linkedin;
  late final TextEditingController _portfolio;
  late final TextEditingController _summary;
  late final TextEditingController _skills;
  late final TextEditingController _experience;
  late final TextEditingController _education;
  late final TextEditingController _projects;
  late final TextEditingController _certifications;

  late String _template;

  bool get _isEditing => widget.resume != null;

  @override
  void initState() {
    super.initState();
    final resume = widget.resume;

    _title = TextEditingController(text: resume?.title ?? '');
    _targetField = TextEditingController(text: resume?.targetField ?? '');
    _fullName = TextEditingController(text: resume?.fullName ?? '');
    _email = TextEditingController(text: resume?.email ?? '');
    _phone = TextEditingController(text: resume?.phone ?? '');
    _location = TextEditingController(text: resume?.location ?? '');
    _linkedin = TextEditingController(text: resume?.linkedin ?? '');
    _portfolio = TextEditingController(text: resume?.portfolio ?? '');
    _summary = TextEditingController(text: resume?.summary ?? '');
    _skills = TextEditingController(text: _toText(resume?.skills));
    _experience = TextEditingController(text: _toText(resume?.experience));
    _education = TextEditingController(text: _toText(resume?.education));
    _projects = TextEditingController(text: _toText(resume?.projects));
    _certifications = TextEditingController(text: _toText(resume?.certifications));

    final saved = resume?.template;
    _template = (saved != null && ResumeDraft.templates.contains(saved))
        ? saved
        : ResumeDraft.templates.first;
  }

  @override
  void dispose() {
    for (final controller in [
      _title, _targetField, _fullName, _email, _phone, _location,
      _linkedin, _portfolio, _summary, _skills, _experience,
      _education, _projects, _certifications,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _toText(List<String>? items) => (items ?? const []).join('\n');

  /// One entry per line; blank lines are dropped so a stray newline does not
  /// become an empty bullet in the PDF.
  static List<String> _toList(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      ResumeDraft(
        title: _title.text.trim(),
        targetField: _targetField.text.trim(),
        template: _template,
        fullName: _fullName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        location: _location.text.trim(),
        linkedin: _linkedin.text.trim(),
        portfolio: _portfolio.text.trim(),
        summary: _summary.text.trim(),
        skills: _toList(_skills.text),
        experience: _toList(_experience.text),
        education: _toList(_education.text),
        projects: _toList(_projects.text),
        certifications: _toList(_certifications.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit resume' : 'Create resume')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _card('Resume details', Icons.style_outlined, [
                  _field(_title, 'Resume title',
                      hint: 'e.g. Backend Engineer Resume 2026', required: true),
                  _field(_targetField, 'Target role',
                      hint: 'e.g. Senior Backend Engineer', required: true),
                  const SizedBox(height: 8),
                  const Text('Template',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ResumeDraft.templates.map((template) {
                      final selected = _template == template;
                      return ChoiceChip(
                        label: Text(template),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (value) {
                          if (value) setState(() => _template = template);
                        },
                      );
                    }).toList(),
                  ),
                ]),
                _card('Contact', Icons.person_outline, [
                  _field(_fullName, 'Full name', required: true),
                  _field(_email, 'Email',
                      keyboardType: TextInputType.emailAddress),
                  _field(_phone, 'Phone', keyboardType: TextInputType.phone),
                  _field(_location, 'Location', hint: 'e.g. Dhaka / Remote'),
                  _field(_linkedin, 'LinkedIn',
                      hint: 'https://linkedin.com/in/username'),
                  _field(_portfolio, 'Portfolio',
                      hint: 'https://yourportfolio.com'),
                ]),
                _card('Summary', Icons.subject_outlined, [
                  _field(_summary, 'Professional summary',
                      hint: 'Two or three lines aimed at your target role',
                      maxLines: 4),
                ]),
                _card('Skills & experience', Icons.code, [
                  _field(_skills, 'Skills (one per line)',
                      hint: 'Node.js\nMongoDB\nFlutter', maxLines: 6),
                  _field(_experience, 'Experience (one bullet per line)',
                      hint: 'Backend Engineer at Acme\nBuilt REST APIs',
                      maxLines: 6),
                ]),
                _card('Education & more', Icons.school_outlined, [
                  _field(_education, 'Education', maxLines: 3),
                  _field(_projects, 'Projects', maxLines: 4),
                  _field(_certifications, 'Certifications', maxLines: 3),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: widget.isSaving ? null : _submit,
                    icon: widget.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isEditing ? 'Update resume' : 'Save resume'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) =>
                (value == null || value.trim().isEmpty) ? '$label is required.' : null
            : null,
      ),
    );
  }
}
