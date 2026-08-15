import 'package:intl/intl.dart';

import '../../../../shared/models/career_profile_models.dart';

/// Display helpers shared by the profile screen and its edit sheets. Kept out of
/// the models so the model layer stays free of formatting and locale concerns.
abstract final class ProfileFormat {
  static final _monthYear = DateFormat('MMM yyyy');
  static final _dayMonthYear = DateFormat('d MMM yyyy');
  static final _thousands = NumberFormat.decimalPattern();

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String fullDate(DateTime date) => _dayMonthYear.format(date);

  /// "Mar 2024 — Present" / "Jul 2023 — Feb 2024".
  static String dateRange(DateTime start, DateTime? end, {bool isCurrent = false}) {
    final tail = isCurrent || end == null ? 'Present' : _monthYear.format(end);
    return '${_monthYear.format(start)} — $tail';
  }

  /// "2 yr 5 mo", "7 mo", or "—" for a zero span.
  static String duration(int months) {
    if (months <= 0) return '—';
    final years = months ~/ 12;
    final rest = months % 12;
    if (years == 0) return '$rest mo';
    if (rest == 0) return '$years yr';
    return '$years yr $rest mo';
  }

  /// "BDT 70,000 – 110,000 · Monthly". Collapses to a single figure when the
  /// range has no spread, which is what most people enter.
  static String salary(SalaryExpectation salary) {
    final min = _thousands.format(salary.min);
    final max = _thousands.format(salary.max);
    final amount = salary.min == salary.max ? min : '$min – $max';
    return '${salary.currency} $amount · ${salaryPeriod(salary.period)}';
  }

  /// "BDT 70k – 110k/mo" — the short form the design uses in the Location &
  /// Salary tile, where the full figure would be truncated.
  static String salaryCompact(SalaryExpectation salary) {
    final min = compactAmount(salary.min);
    final max = compactAmount(salary.max);
    final amount = salary.min == salary.max ? min : '$min – $max';
    return '${salary.currency} $amount${salaryPeriodSuffix(salary.period)}';
  }

  /// 110000 -> "110k", 1500 -> "1.5k", 800 -> "800".
  static String compactAmount(int value) {
    if (value < 1000) return '$value';
    final thousands = value / 1000;
    final text = thousands == thousands.roundToDouble()
        ? thousands.toInt().toString()
        : thousands.toStringAsFixed(1);
    return '${text}k';
  }

  static String salaryPeriodSuffix(SalaryPeriod period) => switch (period) {
        SalaryPeriod.hourly => '/hr',
        SalaryPeriod.monthly => '/mo',
        SalaryPeriod.yearly => '/yr',
      };

  static String salaryPeriod(SalaryPeriod period) => switch (period) {
        SalaryPeriod.hourly => 'Hourly',
        SalaryPeriod.monthly => 'Monthly',
        SalaryPeriod.yearly => 'Yearly',
      };

  static String workMode(WorkMode mode) => switch (mode) {
        WorkMode.onsite => 'On-site',
        WorkMode.hybrid => 'Hybrid',
        WorkMode.remote => 'Remote',
      };

  static String employmentType(EmploymentType type) => switch (type) {
        EmploymentType.fullTime => 'Full-time',
        EmploymentType.partTime => 'Part-time',
        EmploymentType.contract => 'Contract',
        EmploymentType.internship => 'Internship',
        EmploymentType.freelance => 'Freelance',
      };

  static String skillLevel(SkillLevel level) => switch (level) {
        SkillLevel.beginner => 'Beginner',
        SkillLevel.intermediate => 'Intermediate',
        SkillLevel.advanced => 'Advanced',
        SkillLevel.expert => 'Expert',
      };

  /// 0..1, used to fill the strength bar next to each skill.
  static double skillLevelFraction(SkillLevel level) => switch (level) {
        SkillLevel.beginner => 0.25,
        SkillLevel.intermediate => 0.5,
        SkillLevel.advanced => 0.75,
        SkillLevel.expert => 1,
      };

  static String portfolioKind(PortfolioLinkKind kind) => switch (kind) {
        PortfolioLinkKind.website => 'Website',
        PortfolioLinkKind.github => 'GitHub',
        PortfolioLinkKind.linkedin => 'LinkedIn',
        PortfolioLinkKind.behance => 'Behance',
        PortfolioLinkKind.dribbble => 'Dribbble',
        PortfolioLinkKind.other => 'Link',
      };

  /// Strips the scheme and any trailing slash so links read cleanly in a list.
  static String prettyUrl(String url) {
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  static String lastUpdated(DateTime? updatedAt) {
    if (updatedAt == null) return 'Not saved yet';
    return 'Updated ${_dayMonthYear.format(updatedAt)}';
  }

  /// "Last updated just now" / "2 days ago", falling back to a date once the
  /// gap is wide enough that a relative phrase stops being useful.
  static String relative(DateTime? updatedAt, {DateTime? now}) {
    if (updatedAt == null) return 'Not saved yet';

    final reference = now ?? DateTime.now();
    final gap = reference.difference(updatedAt);

    if (gap.isNegative || gap.inMinutes < 1) return 'Last updated just now';
    if (gap.inHours < 1) {
      final m = gap.inMinutes;
      return 'Last updated $m minute${m == 1 ? '' : 's'} ago';
    }
    if (gap.inDays < 1) {
      final h = gap.inHours;
      return 'Last updated $h hour${h == 1 ? '' : 's'} ago';
    }
    if (gap.inDays < 30) {
      final d = gap.inDays;
      return 'Last updated $d day${d == 1 ? '' : 's'} ago';
    }
    return 'Last updated ${_dayMonthYear.format(updatedAt)}';
  }
}
