import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/sync_merge.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/qr_upload.dart';
import '../widgets/scan_qr_modal.dart';
import '../widgets/share_qr_modal.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool editing = false;
  late TextEditingController name;
  late TextEditingController btId;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppStore>().profile;
    name = TextEditingController(text: profile?.name ?? '');
    btId = TextEditingController(text: profile?.btId ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    btId.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await context.read<AppStore>().updateProfile(
      name: name.text.trim(),
      btId: btId.text.trim().toUpperCase(),
    );
    setState(() => editing = false);
  }

  Future<void> _exportJson() async {
    final store = context.read<AppStore>();
    final data = store.exportData().toJson();
    final text = const JsonEncoder.withIndent('  ').convert(data);
    await Share.share(text, subject: 'spiliby-backup.json');
  }

  Future<void> _exportCsv() async {
    final store = context.read<AppStore>();
    final data = store.exportData();
    final groupNameById = {for (final g in data.groups) g.id: g.name};
    final rows = <List<String>>[
      ['Title', 'Amount', 'Category', 'Date', 'Group', 'Payer'],
    ];
    for (final e in data.expenses) {
      rows.add([
        e.title,
        e.amount.toString(),
        e.category,
        e.date,
        groupNameById[e.groupId] ?? '',
        e.payerId,
      ]);
    }
    final csv = rows
        .map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(','))
        .join('\n');
    await Share.share(csv, subject: 'spiliby-expenses.csv');
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    try {
      final file = result.files.single;
      final bytes = file.bytes;
      final content = bytes != null
          ? utf8.decode(bytes)
          : await _readPath(file.path!);
      final data = jsonDecode(content) as Map<String, dynamic>;
      await context.read<AppStore>().importData(BackupData.fromJson(data));
      if (mounted) _snack('Backup imported.');
    } catch (_) {
      if (mounted)
        _snack(
          'Could not read that file. Make sure it is a Spiliby JSON backup.',
        );
    }
  }

  Future<String> _readPath(String path) async {
    final f = path.toString();
    return f;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleShareToPhone() async {
    final store = context.read<AppStore>();
    final data = store.exportData().toJson();
    final payload = jsonEncode(data);
    if (payload.length > 4400) {
      _snack(
        'This backup is too large for a single QR code. Try the JSON export option.',
      );
      return;
    }
    if (!mounted) return;
    await showShareQrModal(context, payload: payload);
  }

  Future<void> _handleClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(
          'This deletes every friend, group, and expense on this device. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AppStore>().clearAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final store = context.watch<AppStore>();
    final profile = store.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppFonts.display(
            size: 22,
            weight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: editing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(controller: name, hint: 'Name'),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: btId,
                      hint: 'BT ID',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Save',
                            onPressed: _saveProfile,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppSecondaryButton(
                            label: 'Cancel',
                            onPressed: () => setState(() => editing = false),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => setState(() => editing = true),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (profile?.name.isNotEmpty ?? false)
                              ? profile!.name[0].toUpperCase()
                              : '',
                          style: AppFonts.display(
                            size: 16,
                            weight: FontWeight.w600,
                            color: c.onAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile?.name ?? '',
                              style: AppFonts.body(
                                size: 13,
                                weight: FontWeight.w500,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              profile?.btId ?? '',
                              style: AppFonts.body(
                                size: 11,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.textMuted,
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: QrUpload(
            qrCode: profile?.qrCode,
            onChange: (v) => store.updateProfile(qrCode: v, clearQr: v == null),
            label: 'My payment QR code',
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.share_rounded, size: 17, color: c.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Offline sync between phones',
                          style: AppFonts.body(
                            size: 13,
                            weight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          'Works locally first; use QR sharing when two phones are nearby and no internet is available.',
                          style: AppFonts.body(size: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Share via QR',
                      onPressed: _handleShareToPhone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Scan QR',
                      onPressed: () => showScanQrModal(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingRow(
          icon: store.isDark
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          label: 'Dark mode',
          toggle: true,
          value: store.isDark,
          onToggle: () => store.toggleTheme(),
        ),
        const SizedBox(height: 10),
        _SettingRow(
          icon: Icons.notifications_rounded,
          label: 'Notifications',
          toggle: true,
          value: store.notificationsEnabled,
          onToggle: () =>
              store.setNotificationsEnabled(!store.notificationsEnabled),
        ),
        const SizedBox(height: 10),
        _SettingRow(
          icon: Icons.download_rounded,
          label: 'Export as JSON',
          onTap: _exportJson,
        ),
        const SizedBox(height: 10),
        _SettingRow(
          icon: Icons.download_rounded,
          label: 'Export as CSV',
          onTap: _exportCsv,
        ),
        const SizedBox(height: 10),
        _SettingRow(
          icon: Icons.upload_rounded,
          label: 'Import backup',
          onTap: _importBackup,
        ),
        const SizedBox(height: 10),
        _SettingRow(
          icon: Icons.delete_outline_rounded,
          label: 'Clear all data',
          danger: true,
          onTap: _handleClear,
        ),
        const SizedBox(height: 20),
        Text(
          'Spiliby · works offline first, with QR sharing when you need it.',
          textAlign: TextAlign.center,
          style: AppFonts.body(
            size: 12,
            weight: FontWeight.w500,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool toggle;
  final bool value;
  final VoidCallback? onToggle;
  final bool danger;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.toggle = false,
    this.value = false,
    this.onToggle,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: toggle ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: danger ? c.dangerBg : c.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 17,
              color: danger ? c.danger : c.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppFonts.body(
                size: 13,
                weight: FontWeight.w500,
                color: danger ? c.danger : c.textPrimary,
              ),
            ),
          ),
          if (toggle)
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: value ? c.accent : c.disabledBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            )
          else
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
        ],
      ),
    );
  }
}
