import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/create_group_modal.dart';
import '../widgets/empty_state.dart';
import 'group_details_page.dart';

class GroupsPage extends StatefulWidget {
  /// When pushed as a standalone route (e.g. from Home's "See groups" link)
  /// this wraps the content in its own Scaffold with a back button.
  final bool asRoute;
  const GroupsPage({super.key, this.asRoute = false});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final store = context.watch<AppStore>();
    final groups = store.groups;
    final q = query.text.toLowerCase();
    final filtered = groups.where((g) => g.name.toLowerCase().contains(q)).toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Groups', style: AppFonts.display(size: 22, weight: FontWeight.w700, color: c.textPrimary)),
            InkWell(
              onTap: () => showCreateGroupModal(context),
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
        if (groups.isNotEmpty) ...[
          _SearchField(controller: query, hint: 'Search groups', onChanged: () => setState(() {})),
          const SizedBox(height: 16),
        ],
        if (groups.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.groups_rounded,
              title: 'No groups yet',
              message: 'Start a group for your hostel room, a trip, or anything you split costs for.',
              action: InkWell(
                onTap: () => showCreateGroupModal(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 15, color: c.onAccent),
                    const SizedBox(width: 6),
                    Text('Create group', style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.onAccent)),
                  ]),
                ),
              ),
            ),
          )
        else if (filtered.isEmpty)
          EmptyState(icon: Icons.search_rounded, title: 'No matches', message: 'Try a different search.')
        else
          for (final g in filtered) ...[
            _GroupRow(groupId: g.id),
            const SizedBox(height: 10),
          ],
      ],
    );

    if (!widget.asRoute) return content;

    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 512),
            child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: content),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  const _SearchField({required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: AppFonts.body(size: 14, color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.body(size: 14, color: c.textMuted),
        prefixIcon: Icon(Icons.search_rounded, size: 16, color: c.textMuted),
        filled: true,
        fillColor: c.inputBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.accent)),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final String groupId;
  const _GroupRow({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final store = context.watch<AppStore>();
    final g = store.groups.firstWhere((x) => x.id == groupId);
    final memberCount = store.groupMembers.where((m) => m.groupId == groupId).length + 1;
    final settlement = store.getGroupSettlement(groupId);
    final myBalance = settlement.balances['me'] ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupDetailsPage(groupId: groupId))),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text(g.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(g.name,
                          style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (g.status == 'completed') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(999)),
                        child: Text('Done', style: AppFonts.body(size: 9, weight: FontWeight.w500, color: c.success)),
                      ),
                    ],
                  ],
                ),
                Text('$memberCount members', style: AppFonts.body(size: 11, color: c.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: myBalance.abs() < 0.5
                ? [Text('Settled', style: AppFonts.body(size: 11, color: c.textMuted))]
                : myBalance > 0
                    ? [
                        Text("You're owed", style: AppFonts.body(size: 11, color: c.textMuted)),
                        Text(formatMoney(myBalance), style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.success)),
                      ]
                    : [
                        Text('You owe', style: AppFonts.body(size: 11, color: c.textMuted)),
                        Text(formatMoney(-myBalance), style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.danger)),
                      ],
          ),
        ],
      ),
    );
  }
}