import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/community_models.dart';
import '../widgets/community_visuals.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Technology';
  String _visualKey = 'code';

  static const _categories = [
    'Technology',
    'Job role',
    'Career stage',
    'Creative',
    'Industry',
    'Interest',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CreateCommunityRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        visualKey: _visualKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = CommunityVisuals.colorFor(_visualKey);
    return Scaffold(
      appBar: AppBar(title: const Text('Create community')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          children: [
            const ScreenIntro(
              eyebrow: 'Build your circle',
              title: 'Create a community',
              description:
                  'Bring people together around a skill, career path, or shared professional interest.',
            ),
            const SizedBox(height: 22),
            _CommunityPreview(
              name: _nameController.text.trim(),
              category: _category,
              visualKey: _visualKey,
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 45,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Community name',
                hintText: 'e.g. Flutter Developers Bangladesh',
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 3) {
                  return 'Enter at least 3 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 180,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What will members learn and discuss here?',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 15) {
                  return 'Describe the community in at least 15 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 20),
            Text('Choose an identity',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: CommunityVisuals.keys.map((key) {
                final selected = key == _visualKey;
                final optionColor = CommunityVisuals.colorFor(key);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _visualKey = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? optionColor.withOpacity(0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? optionColor : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(CommunityVisuals.iconFor(key), color: optionColor),
                        const SizedBox(height: 5),
                        Text(
                          CommunityVisuals.labelFor(key),
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Create community'),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPreview extends StatelessWidget {
  const _CommunityPreview({
    required this.name,
    required this.category,
    required this.visualKey,
  });

  final String name;
  final String category;
  final String visualKey;

  @override
  Widget build(BuildContext context) {
    final color = CommunityVisuals.colorFor(visualKey);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, AppColors.cyan, 0.65)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(17),
            ),
            child:
                Icon(CommunityVisuals.iconFor(visualKey), color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Your community' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$category · You will be the first member',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const Icon(
            Icons.public_rounded,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }
}
