/// The design gives each section a single "Edit" link rather than per-row
/// controls, so Edit opens this sheet: the section's entries with add, edit,
/// and delete in one place.
library;

import 'package:flutter/material.dart';

import '../../../../shared/models/career_profile_models.dart';
import '../controllers/career_profile_controller.dart';
import 'profile_design.dart';

/// Generic over the entry type so education, experience, certifications, and
/// links all share one implementation.
///
/// It rebuilds from [controller] rather than a captured list, so adds and
/// deletes made inside the sheet appear immediately without the caller having
/// to close and reopen it.
class ManageSectionSheet<T> extends StatelessWidget {
  const ManageSectionSheet({
    super.key,
    required this.controller,
    required this.title,
    required this.addLabel,
    required this.emptyMessage,
    required this.itemsOf,
    required this.titleOf,
    required this.subtitleOf,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final CareerProfileController controller;
  final String title;
  final String addLabel;
  final String emptyMessage;
  final List<T> Function(CareerProfile) itemsOf;
  final String Function(T) titleOf;
  final String? Function(T) subtitleOf;
  final Future<void> Function() onAdd;
  final Future<void> Function(T) onEdit;
  final Future<void> Function(T) onDelete;

  static Future<void> show<T>({
    required BuildContext context,
    required ManageSectionSheet<T> sheet,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: ProfileDesign.surface,
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
                color: ProfileDesign.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: ProfileDesign.appBarTitle),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: ProfileDesign.muted,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Flexible(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final profile = controller.profile;
                  final items = profile == null
                      ? <T>[]
                      : itemsOf(profile);

                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: ProfileDesign.entryBody,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final subtitle = subtitleOf(item);
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: index == 0
                            ? null
                            : const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: ProfileDesign.border),
                                ),
                              ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleOf(item),
                                    style: ProfileDesign.entryTitle,
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitle,
                                      style: ProfileDesign.entryBody,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => onEdit(item),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: ProfileDesign.primary,
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              onPressed: () => onDelete(item),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              color: ProfileDesign.danger,
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: ProfileDesign.border),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: Text(addLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: ProfileDesign.primary,
                    foregroundColor: Colors.white,
                    textStyle: ProfileDesign.ctaLabel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
