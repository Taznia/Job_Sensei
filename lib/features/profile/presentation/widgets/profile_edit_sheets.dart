/// Modal editors for each profile section.
///
/// Every sheet is self-contained: it takes the existing entry (or null to
/// create), edits a local copy, and pops the finished value. The caller decides
/// what to do with the result, so none of these know about the repository or
/// the controller.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/career_profile_models.dart';
import 'profile_formatting.dart';

/// Shared chrome — grab handle, title, scrollable body, cancel/save footer.
/// [onSave] returns false to keep the sheet open, which is what validation
/// failure does.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.child,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      // Lifts the sheet above the keyboard instead of letting it cover fields.
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.muted,
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                  child: child,
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: onSave,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> _showSheet<T>(BuildContext context, Widget sheet) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}

/// Labelled text field with the spacing every sheet uses.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

const _labelStyle = TextStyle(
  color: AppColors.ink,
  fontSize: 12.5,
  fontWeight: FontWeight.w700,
);

/// Month/year picker rendered as a tappable field. Figma-style date pickers are
/// month-granular, so the day component is discarded.
class _MonthField extends StatelessWidget {
  const _MonthField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.placeholder = 'Select',
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: !enabled
              ? null
              : () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? now,
                    firstDate: DateTime(1970),
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked != null) {
                    onChanged(DateTime(picked.year, picked.month));
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              enabled: enabled,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 17),
            ),
            child: Text(
              value == null ? placeholder : ProfileFormat.monthYear(value!),
              style: TextStyle(
                color: !enabled
                    ? AppColors.muted
                    : (value == null ? AppColors.muted : AppColors.ink),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Free-text list editor: type, press enter or the add button, get a chip.
/// Used for preferred roles, preferred locations, and per-role skills.
class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.label,
    required this.values,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String? hint;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // Case-insensitive dedupe — "Flutter" and "flutter" are the same tag.
    final exists = widget.values
        .any((v) => v.toLowerCase() == text.toLowerCase());
    if (!exists) widget.onChanged([...widget.values, text]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: _labelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(hintText: widget.hint),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add',
              ),
            ],
          ),
          if (widget.values.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.values
                  .map(
                    (value) => Chip(
                      label: Text(value),
                      onDeleted: () => widget.onChanged(
                        widget.values.where((v) => v != value).toList(),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 15),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Multi-select chip row for the enum-backed preference fields.
class _EnumChips<T> extends StatelessWidget {
  const _EnumChips({
    required this.label,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> options;
  final List<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<List<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isOn = selected.contains(option);
              return FilterChip(
                label: Text(labelOf(option)),
                selected: isOn,
                showCheckmark: false,
                onSelected: (_) => onChanged(
                  isOn
                      ? selected.where((s) => s != option).toList()
                      : [...selected, option],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

String? _required(String? value, String field) {
  return (value ?? '').trim().isEmpty ? '$field is required' : null;
}

/* ------------------------------------------------------------ basics --- */

class EditBasicsSheet extends StatefulWidget {
  const EditBasicsSheet({super.key, required this.profile});

  final CareerProfile profile;

  static Future<ProfileBasicsDraft?> show(
    BuildContext context,
    CareerProfile profile,
  ) {
    return _showSheet<ProfileBasicsDraft>(
      context,
      EditBasicsSheet(profile: profile),
    );
  }

  @override
  State<EditBasicsSheet> createState() => _EditBasicsSheetState();
}

class _EditBasicsSheetState extends State<EditBasicsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _headline = TextEditingController(text: widget.profile.headline);
  late final _email = TextEditingController(text: widget.profile.email);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _location =
      TextEditingController(text: widget.profile.location ?? '');
  late final _about = TextEditingController(text: widget.profile.about ?? '');
  late final _goals =
      TextEditingController(text: widget.profile.careerGoals ?? '');

  @override
  void dispose() {
    for (final c in [_name, _headline, _email, _phone, _location, _about, _goals]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Empty optional fields are sent as null, not "", so clearing a field really
  /// clears it rather than storing a blank string.
  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ProfileBasicsDraft(
        fullName: _name.text.trim(),
        headline: _headline.text.trim(),
        email: _email.text.trim(),
        phone: _optional(_phone),
        location: _optional(_location),
        about: _optional(_about),
        careerGoals: _optional(_goals),
        avatarUrl: widget.profile.avatarUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Edit profile details',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Full name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Name'),
            ),
            _Field(
              label: 'Headline',
              controller: _headline,
              hint: 'e.g. Flutter Developer',
              validator: (v) => _required(v, 'Headline'),
            ),
            _Field(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'Email is required';
                // Deliberately loose: catches typos, rejects nothing valid.
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            _Field(
              label: 'Phone',
              controller: _phone,
              keyboardType: TextInputType.phone,
              textCapitalization: TextCapitalization.none,
            ),
            _Field(
              label: 'Location',
              controller: _location,
              hint: 'e.g. Dhaka, Bangladesh',
              textCapitalization: TextCapitalization.words,
            ),
            _Field(
              label: 'About',
              controller: _about,
              maxLines: 4,
              hint: 'A short summary of who you are professionally',
            ),
            _Field(
              label: 'Career goals',
              controller: _goals,
              maxLines: 4,
              hint: 'Where you want your career to go next',
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------- education --- */

class EditEducationSheet extends StatefulWidget {
  const EditEducationSheet({super.key, this.entry});

  final EducationEntry? entry;

  static Future<EducationEntry?> show(
    BuildContext context, {
    EducationEntry? entry,
  }) {
    return _showSheet<EducationEntry>(context, EditEducationSheet(entry: entry));
  }

  @override
  State<EditEducationSheet> createState() => _EditEducationSheetState();
}

class _EditEducationSheetState extends State<EditEducationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _institution =
      TextEditingController(text: widget.entry?.institution ?? '');
  late final _degree = TextEditingController(text: widget.entry?.degree ?? '');
  late final _field =
      TextEditingController(text: widget.entry?.fieldOfStudy ?? '');
  late final _grade = TextEditingController(text: widget.entry?.grade ?? '');
  late final _description =
      TextEditingController(text: widget.entry?.description ?? '');

  late DateTime _start = widget.entry?.startDate ?? DateTime.now();
  late DateTime? _end = widget.entry?.endDate;
  late bool _isCurrent = widget.entry?.isCurrent ?? false;
  String? _dateError;

  @override
  void dispose() {
    for (final c in [_institution, _degree, _field, _grade, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final validForm = _formKey.currentState!.validate();
    // End before start is a data error the form validators cannot see, since
    // the dates live outside the Form.
    final end = _isCurrent ? null : _end;
    setState(() {
      _dateError = !_isCurrent && end != null && end.isBefore(_start)
          ? 'End date cannot be before the start date'
          : null;
    });
    if (!validForm || _dateError != null) return;

    Navigator.of(context).pop(
      EducationEntry(
        id: widget.entry?.id ?? '',
        institution: _institution.text.trim(),
        degree: _degree.text.trim(),
        fieldOfStudy: _field.text.trim(),
        startDate: _start,
        endDate: end,
        isCurrent: _isCurrent,
        grade: _grade.text.trim().isEmpty ? null : _grade.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.entry == null ? 'Add education' : 'Edit education',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Institution',
              controller: _institution,
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Institution'),
            ),
            _Field(
              label: 'Degree',
              controller: _degree,
              hint: 'e.g. BSc, Diploma',
              validator: (v) => _required(v, 'Degree'),
            ),
            _Field(
              label: 'Field of study',
              controller: _field,
              hint: 'e.g. Computer Science',
              validator: (v) => _required(v, 'Field of study'),
            ),
            _DateRangeFields(
              start: _start,
              end: _end,
              isCurrent: _isCurrent,
              currentLabel: 'I am currently studying here',
              error: _dateError,
              onStart: (v) => setState(() => _start = v),
              onEnd: (v) => setState(() => _end = v),
              onCurrent: (v) => setState(() => _isCurrent = v),
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Grade',
              controller: _grade,
              hint: 'e.g. CGPA 3.72 / 4.00',
            ),
            _Field(
              label: 'Description',
              controller: _description,
              maxLines: 3,
              hint: 'Coursework, thesis, achievements',
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------- experience --- */

class EditExperienceSheet extends StatefulWidget {
  const EditExperienceSheet({super.key, this.entry});

  final WorkExperience? entry;

  static Future<WorkExperience?> show(
    BuildContext context, {
    WorkExperience? entry,
  }) {
    return _showSheet<WorkExperience>(
      context,
      EditExperienceSheet(entry: entry),
    );
  }

  @override
  State<EditExperienceSheet> createState() => _EditExperienceSheetState();
}

class _EditExperienceSheetState extends State<EditExperienceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _company = TextEditingController(text: widget.entry?.company ?? '');
  late final _title = TextEditingController(text: widget.entry?.title ?? '');
  late final _location =
      TextEditingController(text: widget.entry?.location ?? '');
  late final _description =
      TextEditingController(text: widget.entry?.description ?? '');

  late EmploymentType _type =
      widget.entry?.employmentType ?? EmploymentType.fullTime;
  late DateTime _start = widget.entry?.startDate ?? DateTime.now();
  late DateTime? _end = widget.entry?.endDate;
  late bool _isCurrent = widget.entry?.isCurrent ?? false;
  late List<String> _skills = [...?widget.entry?.skills];
  String? _dateError;

  @override
  void dispose() {
    for (final c in [_company, _title, _location, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final validForm = _formKey.currentState!.validate();
    final end = _isCurrent ? null : _end;
    setState(() {
      _dateError = !_isCurrent && end != null && end.isBefore(_start)
          ? 'End date cannot be before the start date'
          : null;
    });
    if (!validForm || _dateError != null) return;

    Navigator.of(context).pop(
      WorkExperience(
        id: widget.entry?.id ?? '',
        company: _company.text.trim(),
        title: _title.text.trim(),
        employmentType: _type,
        startDate: _start,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        endDate: end,
        isCurrent: _isCurrent,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        skills: _skills,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.entry == null ? 'Add experience' : 'Edit experience',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Job title',
              controller: _title,
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Job title'),
            ),
            _Field(
              label: 'Company',
              controller: _company,
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Company'),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Employment type', style: _labelStyle),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<EmploymentType>(
                    initialValue: _type,
                    items: EmploymentType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(ProfileFormat.employmentType(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                ],
              ),
            ),
            _Field(
              label: 'Location',
              controller: _location,
              hint: 'e.g. Dhaka, or Remote',
              textCapitalization: TextCapitalization.words,
            ),
            _DateRangeFields(
              start: _start,
              end: _end,
              isCurrent: _isCurrent,
              currentLabel: 'I currently work here',
              error: _dateError,
              onStart: (v) => setState(() => _start = v),
              onEnd: (v) => setState(() => _end = v),
              onCurrent: (v) => setState(() => _isCurrent = v),
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Description',
              controller: _description,
              maxLines: 4,
              hint: 'What you owned and what you shipped',
            ),
            _TagEditor(
              label: 'Skills used in this role',
              values: _skills,
              hint: 'e.g. Flutter',
              onChanged: (v) => setState(() => _skills = v),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------- skill --- */

class EditSkillSheet extends StatefulWidget {
  const EditSkillSheet({super.key, this.entry});

  final SkillEntry? entry;

  static Future<SkillEntry?> show(BuildContext context, {SkillEntry? entry}) {
    return _showSheet<SkillEntry>(context, EditSkillSheet(entry: entry));
  }

  @override
  State<EditSkillSheet> createState() => _EditSkillSheetState();
}

class _EditSkillSheetState extends State<EditSkillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.entry?.name ?? '');
  late final _years = TextEditingController(
    text: widget.entry?.yearsOfExperience?.toString() ?? '',
  );
  late SkillLevel _level = widget.entry?.level ?? SkillLevel.intermediate;

  @override
  void dispose() {
    _name.dispose();
    _years.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      SkillEntry(
        id: widget.entry?.id ?? '',
        name: _name.text.trim(),
        level: _level,
        yearsOfExperience: double.tryParse(_years.text.trim()),
        isVerified: widget.entry?.isVerified ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.entry == null ? 'Add skill' : 'Edit skill',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Skill',
              controller: _name,
              hint: 'e.g. Flutter',
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Skill name'),
            ),
            const Text('Proficiency', style: _labelStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SkillLevel.values.map((level) {
                return ChoiceChip(
                  label: Text(ProfileFormat.skillLevel(level)),
                  selected: _level == level,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _level = level),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Years of experience',
              controller: _years,
              hint: 'e.g. 2.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return null;
                final parsed = double.tryParse(text);
                if (parsed == null) return 'Enter a number';
                if (parsed < 0 || parsed > 70) return 'Enter a realistic value';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------------------------------- certification --- */

class EditCertificationSheet extends StatefulWidget {
  const EditCertificationSheet({super.key, this.entry});

  final Certification? entry;

  static Future<Certification?> show(
    BuildContext context, {
    Certification? entry,
  }) {
    return _showSheet<Certification>(
      context,
      EditCertificationSheet(entry: entry),
    );
  }

  @override
  State<EditCertificationSheet> createState() =>
      _EditCertificationSheetState();
}

class _EditCertificationSheetState extends State<EditCertificationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.entry?.name ?? '');
  late final _issuer = TextEditingController(text: widget.entry?.issuer ?? '');
  late final _credentialId =
      TextEditingController(text: widget.entry?.credentialId ?? '');
  late final _credentialUrl =
      TextEditingController(text: widget.entry?.credentialUrl ?? '');

  late DateTime _issued = widget.entry?.issueDate ?? DateTime.now();
  late DateTime? _expires = widget.entry?.expiryDate;
  late bool _neverExpires = widget.entry?.expiryDate == null;
  String? _dateError;

  @override
  void dispose() {
    for (final c in [_name, _issuer, _credentialId, _credentialUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final validForm = _formKey.currentState!.validate();
    final expiry = _neverExpires ? null : _expires;
    setState(() {
      _dateError = expiry != null && expiry.isBefore(_issued)
          ? 'Expiry cannot be before the issue date'
          : null;
    });
    if (!validForm || _dateError != null) return;

    Navigator.of(context).pop(
      Certification(
        id: widget.entry?.id ?? '',
        name: _name.text.trim(),
        issuer: _issuer.text.trim(),
        issueDate: _issued,
        expiryDate: expiry,
        credentialId: _credentialId.text.trim().isEmpty
            ? null
            : _credentialId.text.trim(),
        credentialUrl: _credentialUrl.text.trim().isEmpty
            ? null
            : _credentialUrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.entry == null ? 'Add certification' : 'Edit certification',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Certification name',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Certification name'),
            ),
            _Field(
              label: 'Issuing organisation',
              controller: _issuer,
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Issuer'),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MonthField(
                    label: 'Issued',
                    value: _issued,
                    onChanged: (v) => setState(() => _issued = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MonthField(
                    label: 'Expires',
                    value: _expires,
                    enabled: !_neverExpires,
                    placeholder: _neverExpires ? 'No expiry' : 'Select',
                    onChanged: (v) => setState(() => _expires = v),
                  ),
                ),
              ],
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _dateError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                  ),
                ),
              ),
            CheckboxListTile(
              value: _neverExpires,
              onChanged: (v) => setState(() {
                _neverExpires = v ?? false;
                if (_neverExpires) _expires = null;
              }),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'This credential does not expire',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            _Field(
              label: 'Credential ID',
              controller: _credentialId,
              textCapitalization: TextCapitalization.none,
            ),
            _Field(
              label: 'Credential URL',
              controller: _credentialUrl,
              hint: 'https://...',
              keyboardType: TextInputType.url,
              textCapitalization: TextCapitalization.none,
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------ portfolio link --- */

class EditPortfolioLinkSheet extends StatefulWidget {
  const EditPortfolioLinkSheet({super.key, this.entry});

  final PortfolioLink? entry;

  static Future<PortfolioLink?> show(
    BuildContext context, {
    PortfolioLink? entry,
  }) {
    return _showSheet<PortfolioLink>(
      context,
      EditPortfolioLinkSheet(entry: entry),
    );
  }

  @override
  State<EditPortfolioLinkSheet> createState() =>
      _EditPortfolioLinkSheetState();
}

class _EditPortfolioLinkSheetState extends State<EditPortfolioLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.entry?.label ?? '');
  late final _url = TextEditingController(text: widget.entry?.url ?? '');
  late PortfolioLinkKind _kind = widget.entry?.kind ?? PortfolioLinkKind.website;

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    var url = _url.text.trim();
    // Users type "github.com/me"; store something a browser can actually open.
    if (!url.startsWith(RegExp(r'https?://'))) url = 'https://$url';

    Navigator.of(context).pop(
      PortfolioLink(
        id: widget.entry?.id ?? '',
        label: _label.text.trim(),
        url: url,
        kind: _kind,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.entry == null ? 'Add link' : 'Edit link',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Type', style: _labelStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PortfolioLinkKind.values.map((kind) {
                return ChoiceChip(
                  label: Text(ProfileFormat.portfolioKind(kind)),
                  selected: _kind == kind,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _kind = kind;
                    // Prefill the label from the type when it is still blank.
                    if (_label.text.trim().isEmpty) {
                      _label.text = ProfileFormat.portfolioKind(kind);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Label',
              controller: _label,
              hint: 'e.g. GitHub',
              validator: (v) => _required(v, 'Label'),
            ),
            _Field(
              label: 'URL',
              controller: _url,
              hint: 'https://github.com/you',
              keyboardType: TextInputType.url,
              textCapitalization: TextCapitalization.none,
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'URL is required';
                // Accept bare domains; _save adds the scheme before storing.
                final candidate = text.startsWith(RegExp(r'https?://'))
                    ? text
                    : 'https://$text';
                final uri = Uri.tryParse(candidate);
                if (uri == null || !uri.hasAuthority || !uri.host.contains('.')) {
                  return 'Enter a valid URL';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------- preferences --- */

class EditPreferencesSheet extends StatefulWidget {
  const EditPreferencesSheet({super.key, required this.preferences});

  final JobPreferences preferences;

  static Future<JobPreferences?> show(
    BuildContext context,
    JobPreferences preferences,
  ) {
    return _showSheet<JobPreferences>(
      context,
      EditPreferencesSheet(preferences: preferences),
    );
  }

  @override
  State<EditPreferencesSheet> createState() => _EditPreferencesSheetState();
}

class _EditPreferencesSheetState extends State<EditPreferencesSheet> {
  final _formKey = GlobalKey<FormState>();
  late List<String> _roles = [...widget.preferences.preferredRoles];
  late List<String> _locations = [...widget.preferences.preferredLocations];
  late List<WorkMode> _modes = [...widget.preferences.workModes];
  late List<EmploymentType> _types = [...widget.preferences.employmentTypes];
  late bool _relocate = widget.preferences.openToRelocation;
  late DateTime? _availableFrom = widget.preferences.availableFrom;
  late SalaryPeriod _period =
      widget.preferences.salary?.period ?? SalaryPeriod.monthly;

  late final _currency = TextEditingController(
    text: widget.preferences.salary?.currency ?? 'BDT',
  );
  late final _min = TextEditingController(
    text: widget.preferences.salary?.min.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.preferences.salary?.max.toString() ?? '',
  );
  String? _salaryError;

  @override
  void dispose() {
    for (final c in [_currency, _min, _max]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final validForm = _formKey.currentState!.validate();

    final min = int.tryParse(_min.text.trim());
    final max = int.tryParse(_max.text.trim());
    setState(() {
      _salaryError = min != null && max != null && max < min
          ? 'Maximum cannot be lower than the minimum'
          : null;
    });
    if (!validForm || _salaryError != null) return;

    // Salary is optional as a whole: only build it when both bounds are set.
    final salary = (min == null || max == null)
        ? null
        : SalaryExpectation(
            min: min,
            max: max,
            currency: _currency.text.trim().isEmpty
                ? 'BDT'
                : _currency.text.trim().toUpperCase(),
            period: _period,
          );

    Navigator.of(context).pop(
      JobPreferences(
        preferredRoles: _roles,
        preferredLocations: _locations,
        workModes: _modes,
        employmentTypes: _types,
        salary: salary,
        openToRelocation: _relocate,
        availableFrom: _availableFrom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Edit job preferences',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TagEditor(
              label: 'Preferred job roles',
              values: _roles,
              hint: 'e.g. Flutter Developer',
              onChanged: (v) => setState(() => _roles = v),
            ),
            _TagEditor(
              label: 'Preferred locations',
              values: _locations,
              hint: 'e.g. Dhaka, or Remote',
              onChanged: (v) => setState(() => _locations = v),
            ),
            _EnumChips<WorkMode>(
              label: 'Work mode',
              options: WorkMode.values,
              selected: _modes,
              labelOf: ProfileFormat.workMode,
              onChanged: (v) => setState(() => _modes = v),
            ),
            _EnumChips<EmploymentType>(
              label: 'Employment type',
              options: EmploymentType.values,
              selected: _types,
              labelOf: ProfileFormat.employmentType,
              onChanged: (v) => setState(() => _types = v),
            ),
            const Text('Expected salary', style: _labelStyle),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 84,
                  child: TextFormField(
                    controller: _currency,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'BDT'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: 'Min'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: 'Max'),
                  ),
                ),
              ],
            ),
            if (_salaryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _salaryError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: SalaryPeriod.values.map((period) {
                return ChoiceChip(
                  label: Text(ProfileFormat.salaryPeriod(period)),
                  selected: _period == period,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _period = period),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _MonthField(
              label: 'Available from',
              value: _availableFrom,
              placeholder: 'Immediately',
              onChanged: (v) => setState(() => _availableFrom = v),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _relocate,
              onChanged: (v) => setState(() => _relocate = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Open to relocation',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------ shared --- */

/// Start/end month pair plus the "currently here" toggle, which blanks and
/// disables the end date while it is on.
class _DateRangeFields extends StatelessWidget {
  const _DateRangeFields({
    required this.start,
    required this.end,
    required this.isCurrent,
    required this.currentLabel,
    required this.onStart,
    required this.onEnd,
    required this.onCurrent,
    this.error,
  });

  final DateTime start;
  final DateTime? end;
  final bool isCurrent;
  final String currentLabel;
  final ValueChanged<DateTime> onStart;
  final ValueChanged<DateTime> onEnd;
  final ValueChanged<bool> onCurrent;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MonthField(
                label: 'Start',
                value: start,
                onChanged: onStart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MonthField(
                label: 'End',
                value: isCurrent ? null : end,
                enabled: !isCurrent,
                placeholder: isCurrent ? 'Present' : 'Select',
                onChanged: onEnd,
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        CheckboxListTile(
          value: isCurrent,
          onChanged: (v) => onCurrent(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(currentLabel, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
