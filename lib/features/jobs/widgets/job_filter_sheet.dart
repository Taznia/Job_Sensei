import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../job_search_models.dart';

/// The Module 3 filter sheet: company, location, skills, job type, working
/// arrangement, experience level, and salary range.
///
/// Edits a local copy and pops the finished [JobSearchQuery], so dismissing it
/// leaves the current search untouched. Choices are offered from
/// [JobFilterOptions] — values the API says actually exist — so the user cannot
/// build a filter that is guaranteed to return nothing.
class JobFilterSheet extends StatefulWidget {
  const JobFilterSheet({
    super.key,
    required this.query,
    required this.options,
  });

  final JobSearchQuery query;
  final JobFilterOptions options;

  static Future<JobSearchQuery?> show(
    BuildContext context, {
    required JobSearchQuery query,
    required JobFilterOptions options,
  }) {
    return showModalBottomSheet<JobSearchQuery>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobFilterSheet(query: query, options: options),
    );
  }

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  late final _company = TextEditingController(text: widget.query.company);
  late final _location = TextEditingController(text: widget.query.location);
  late final _salaryMin = TextEditingController(
    text: widget.query.salaryMin?.toString() ?? '',
  );
  late final _salaryMax = TextEditingController(
    text: widget.query.salaryMax?.toString() ?? '',
  );

  late List<String> _skills = [...widget.query.skills];
  late String? _type = widget.query.type;
  late String? _workMode = widget.query.workMode;
  late String? _experienceLevel = widget.query.experienceLevel;
  String? _salaryError;

  @override
  void dispose() {
    for (final c in [_company, _location, _salaryMin, _salaryMax]) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply() {
    final min = int.tryParse(_salaryMin.text.trim());
    final max = int.tryParse(_salaryMax.text.trim());

    setState(() {
      _salaryError = (min != null && max != null && max < min)
          ? 'Maximum cannot be lower than the minimum'
          : null;
    });
    if (_salaryError != null) return;

    Navigator.of(context).pop(
      widget.query.copyWith(
        company: _company.text.trim(),
        location: _location.text.trim(),
        skills: _skills,
        type: _type,
        workMode: _workMode,
        experienceLevel: _experienceLevel,
        salaryMin: min,
        salaryMax: max,
        clearType: _type == null,
        clearWorkMode: _workMode == null,
        clearExperienceLevel: _experienceLevel == null,
        clearSalary: min == null && max == null,
        // A changed filter invalidates the current page.
        page: 1,
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _company.clear();
      _location.clear();
      _salaryMin.clear();
      _salaryMax.clear();
      _skills = [];
      _type = null;
      _workMode = null;
      _experienceLevel = null;
      _salaryError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter jobs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear all'),
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
                // A scroll view rather than a ListView: the control set is small and
                // fixed, and a lazy list would leave the lower filters unbuilt
                // until scrolled to.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _SuggestField(
                      label: 'Company',
                      controller: _company,
                      hint: 'e.g. Northwind Labs',
                      suggestions: widget.options.companies,
                    ),
                    _SuggestField(
                      label: 'Location',
                      controller: _location,
                      hint: 'e.g. Dhaka, or Remote',
                      suggestions: widget.options.locations,
                    ),
                    _SkillPicker(
                      selected: _skills,
                      available: widget.options.skills,
                      onChanged: (value) => setState(() => _skills = value),
                    ),
                    _ChoiceRow(
                      label: 'Job type',
                      values: widget.options.types,
                      selected: _type,
                      labelOf: _humanise,
                      onChanged: (value) => setState(() => _type = value),
                    ),
                    _ChoiceRow(
                      label: 'Working arrangement',
                      values: widget.options.workModes,
                      selected: _workMode,
                      labelOf: _humanise,
                      onChanged: (value) => setState(() => _workMode = value),
                    ),
                    _ChoiceRow(
                      label: 'Experience level',
                      values: widget.options.experienceLevels,
                      selected: _experienceLevel,
                      labelOf: _humanise,
                      onChanged: (value) =>
                          setState(() => _experienceLevel = value),
                    ),
                    _SalaryRange(
                      min: _salaryMin,
                      max: _salaryMax,
                      error: _salaryError,
                      hintMin: widget.options.salaryMin,
                      hintMax: widget.options.salaryMax,
                    ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Show results'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "full-time" -> "Full time", "entry" -> "Entry".
  static String _humanise(String value) {
    final words = value.replaceAll('-', ' ').split(' ');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/* ---------------------------------------------------------------- parts --- */

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Free text with tap-to-fill suggestions drawn from what exists in the data.
class _SuggestField extends StatefulWidget {
  const _SuggestField({
    required this.label,
    required this.controller,
    required this.suggestions,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final List<String> suggestions;
  final String? hint;

  @override
  State<_SuggestField> createState() => _SuggestFieldState();
}

class _SuggestFieldState extends State<_SuggestField> {
  @override
  Widget build(BuildContext context) {
    // Only the first handful, or a long list swamps the sheet.
    final shown = widget.suggestions.take(6).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(widget.label),
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(hintText: widget.hint),
            onChanged: (_) => setState(() {}),
          ),
          if (shown.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shown
                  .map(
                    (value) => ActionChip(
                      label: Text(value, overflow: TextOverflow.ellipsis),
                      onPressed: () => setState(() {
                        widget.controller.text = value;
                      }),
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

/// Multi-select over the skills present in open jobs.
class _SkillPicker extends StatelessWidget {
  const _SkillPicker({
    required this.selected,
    required this.available,
    required this.onChanged,
  });

  final List<String> selected;
  final List<String> available;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    // Selected skills always show, even if they fall outside the top slice.
    final shown = <String>{...selected, ...available.take(24)}.toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(
            selected.isEmpty ? 'Skills' : 'Skills (${selected.length})',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shown.map((skill) {
              final isOn = selected.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isOn,
                showCheckmark: false,
                onSelected: (_) => onChanged(
                  isOn
                      ? selected.where((s) => s != skill).toList()
                      : [...selected, skill],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Single-select chips where tapping the active one clears it.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final String Function(String) labelOf;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final isOn = selected == value;
              return ChoiceChip(
                label: Text(labelOf(value)),
                selected: isOn,
                showCheckmark: false,
                onSelected: (_) => onChanged(isOn ? null : value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SalaryRange extends StatelessWidget {
  const _SalaryRange({
    required this.min,
    required this.max,
    required this.error,
    this.hintMin,
    this.hintMax,
  });

  final TextEditingController min;
  final TextEditingController max;
  final String? error;
  final int? hintMin;
  final int? hintMax;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Salary range'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: min,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: hintMin == null ? 'Min' : 'Min (${hintMin!})',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: max,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: hintMax == null ? 'Max' : 'Max (${hintMax!})',
                ),
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
        const SizedBox(height: 6),
        const Text(
          'A job matches when its range overlaps yours, so a role paying up to '
          'your minimum still appears.',
          style: TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.35),
        ),
      ],
    );
  }
}
