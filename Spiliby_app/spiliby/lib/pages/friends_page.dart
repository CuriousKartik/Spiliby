import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/add_friend_modal.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/qr_upload.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final query = TextEditingController();
  String? qrFor;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final store = context.watch<AppStore>();
    final friends = store.friends;
    final q = query.text.toLowerCase();
    final filtered = friends
        .where((f) => f.name.toLowerCase().contains(q) || f.btId.toLowerCase().contains(q))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Friends', style: AppFonts.display(size: 22, weight: FontWeight.w700, color: c.textPrimary)),
            InkWell(
              onTap: () => showAddFriendModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.add_rounded, size: 20, color: c.onAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (friends.isNotEmpty) ...[
          TextField(
            controller: query,
            onChanged: (_) => setState(() {}),
            style: AppFonts.body(size: 14, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or BT ID',
              hintStyle: AppFonts.body(size: 14, color: c.textMuted),
              prefixIcon: Icon(Icons.search_rounded, size: 16, color: c.textMuted),
              filled: true,
              fillColor: c.inputBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.accent)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (friends.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.people_alt_rounded,
              title: 'No friends yet',
              message: 'Add your roommates and classmates so you can split bills with them.',
              action: InkWell(
                onTap: () => showAddFriendModal(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 15, color: c.onAccent),
                    const SizedBox(width: 6),
                    Text('Add friend', style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.onAccent)),
                  ]),
                ),
              ),
            ),
          )
        else if (filtered.isEmpty)
          EmptyState(icon: Icons.search_rounded, title: 'No matches', message: 'Try a different search.')
        else
          for (final f in filtered) ...[
            _FriendCard(
              friend: f,
              showQr: qrFor == f.id,
              onToggleQr: () => setState(() => qrFor = qrFor == f.id ? null : f.id),
              onRemove: () => store.removeFriend(f.id),
              onQrChange: (v) => store.updateFriendQr(f.id, v),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Friend friend;
  final bool showQr;
  final VoidCallback onToggleQr;
  final VoidCallback onRemove;
  final ValueChanged<String?> onQrChange;
  const _FriendCard({
    required this.friend,
    required this.showQr,
    required this.onToggleQr,
    required this.onRemove,
    required this.onQrChange,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text(initials(friend.name), style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.accentHover)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(friend.name,
                        style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    Text(friend.btId, style: AppFonts.body(size: 11, color: c.textMuted)),
                  ],
                ),
              ),
              InkWell(
                onTap: onToggleQr,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(999)),
                  child: Text('QR', style: AppFonts.body(size: 11, weight: FontWeight.w500, color: c.accentHover)),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onRemove,
                child: Icon(Icons.delete_outline_rounded, size: 16, color: c.textMuted),
              ),
            ],
          ),
          if (showQr) ...[
            const SizedBox(height: 12),
            Divider(color: c.chipBg, height: 1),
            const SizedBox(height: 12),
            QrUpload(qrCode: friend.qrCode, onChange: onQrChange, label: "${friend.name}'s payment QR"),
          ],
        ],
      ),
    );
  }
}