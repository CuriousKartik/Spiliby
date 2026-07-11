import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import 'app_modal.dart';
import 'app_text_field.dart';

Future<void> showAddFriendModal(BuildContext context) {
  return showAppModal(
    context: context,
    title: 'Add friend',
    builder: (_) => const _AddFriendForm(),
  );
}

class _AddFriendForm extends StatefulWidget {
  const _AddFriendForm();
  @override
  State<_AddFriendForm> createState() => _AddFriendFormState();
}

class _AddFriendFormState extends State<_AddFriendForm> {
  final name = TextEditingController();
  final btId = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    btId.dispose();
    super.dispose();
  }

  bool get canSave => name.text.trim().isNotEmpty && btId.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!canSave) return;
    final store = context.read<AppStore>();
    await store.addFriend(name: name.text.trim(), btId: btId.text.trim().toUpperCase());
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: name, hint: 'Name', autofocus: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        AppTextField(
          controller: btId,
          hint: 'BT ID (e.g. BT25CSEXXX)',
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppPrimaryButton(label: 'Add friend', onPressed: canSave ? _save : null),
      ],
    );
  }
}