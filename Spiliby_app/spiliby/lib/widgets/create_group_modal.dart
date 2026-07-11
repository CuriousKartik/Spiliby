import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_modal.dart';
import 'app_text_field.dart';

Future<void> showCreateGroupModal(BuildContext context) {
  return showAppModal(
    context: context,
    title: 'New group',
    builder: (_) => const _CreateGroupForm(),
  );
}

class _CreateGroupForm extends StatefulWidget {
  const _CreateGroupForm();
  @override
  State<_CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<_CreateGroupForm> {
  final name = TextEditingController();
  final Set<String> selected = {};

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  bool get canSave => name.text.trim().isNotEmpty && selected.isNotEmpty;

  Future<void> _save() async {
    if (!canSave) return;
    final store = context.read<AppStore>();
    await store.createGroup(name: name.text.trim(), icon: '👥', memberIds: selected.toList());
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final friends = context.watch<AppStore>().friends;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: name, hint: 'Group name', autofocus: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in kGroupPresets)
              InkWell(
                onTap: () => setState(() => name.text = p.split(' ').skip(1).join(' ')),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(p, style: AppFonts.body(size: 12, color: c.textSecondary)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Add members', style: AppFonts.body(size: 12, weight: FontWeight.w600, color: c.textSecondary)),
        const SizedBox(height: 8),
        if (friends.isEmpty)
          Text('Add some friends first, from the Friends tab.', style: AppFonts.body(size: 13, color: c.textMuted))
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 192),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final f in friends) ...[
                    _FriendPickRow(
                      friend: f,
                      active: selected.contains(f.id),
                      onTap: () => setState(() {
                        if (selected.contains(f.id)) {
                          selected.remove(f.id);
                        } else {
                          selected.add(f.id);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        AppPrimaryButton(label: 'Create group', onPressed: canSave ? _save : null),
      ],
    );
  }
}

class _FriendPickRow extends StatelessWidget {
  final Friend friend;
  final bool active;
  final VoidCallback onTap;
  const _FriendPickRow({required this.friend, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? c.accent : c.inputBorder),
          color: active ? c.accent.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(friend.name, style: AppFonts.body(size: 14, color: c.textPrimary)),
            if (active) Icon(Icons.check_rounded, size: 16, color: c.accentHover),
          ],
        ),
      ),
    );
  }
}