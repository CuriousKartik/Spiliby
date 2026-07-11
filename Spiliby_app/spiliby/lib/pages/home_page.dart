import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import 'group_details_page.dart';
import 'groups_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final store = context.watch<AppStore>();

    final expenses = store.expenses;
    final groups = store.groups;
    final friends = store.friends;
    final friendById = {for (final f in friends) f.id: f};

    double todaySpend = 0, monthSpend = 0, paidByMe = 0, iOwe = 0, owedToMe = 0;
    int pendingCount = 0;
    final byCategory = <String, double>{};

    for (final e in expenses) {
      if (isToday(e.date)) todaySpend += e.amount;
      if (isThisMonth(e.date)) monthSpend += e.amount;
      if (e.payerId == 'me') paidByMe += e.amount;
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    for (final g in groups) {
      final settlement = store.getGroupSettlement(g.id);
      for (final t in settlement.transactions) {
        if (t.fromId == 'me') {
          iOwe += t.amount;
          pendingCount++;
        }
        if (t.toId == 'me') {
          owedToMe += t.amount;
          pendingCount++;
        }
      }
    }

    final categoryList = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = categoryList.take(5).toList();

    final recentExpenses = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final recent = recentExpenses.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hey ${store.profile?.name.split(' ').first ?? ''},',
            style: AppFonts.body(size: 13, color: c.textSecondary)),
        Text("Here's your money today",
            style: AppFonts.display(size: 22, weight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _StatCard(icon: Icons.receipt_long_rounded, label: 'Today', value: formatMoney(todaySpend)),
            _StatCard(icon: Icons.trending_up_rounded, label: 'This month', value: formatMoney(monthSpend)),
            _StatCard(icon: Icons.account_balance_wallet_rounded, label: 'You paid', value: formatMoney(paidByMe)),
            _StatCard(icon: Icons.groups_rounded, label: 'Active groups', value: '${groups.length}'),
            _StatCard(icon: Icons.arrow_circle_down_rounded, label: 'You owe', value: formatMoney(iOwe), color: c.danger),
            _StatCard(icon: Icons.arrow_circle_up_rounded, label: "You'll receive", value: formatMoney(owedToMe), color: c.success),
          ],
        ),
        if (pendingCount > 0) ...[
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.access_time_rounded, size: 16, color: c.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppFonts.body(size: 13, color: c.textPrimary),
                      children: [
                        TextSpan(text: '$pendingCount', style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: ' pending settlement${pendingCount > 1 ? 's' : ''} across your groups'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (topCategories.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Category-wise spending',
              style: AppFonts.display(size: 15, weight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 10),
          for (final entry in topCategories) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: AppFonts.body(size: 13, color: c.textPrimary)),
                  Text(formatMoney(entry.value), style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.accentHover)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 24 - 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent expenses', style: AppFonts.display(size: 15, weight: FontWeight.w600, color: c.textPrimary)),
            if (groups.isNotEmpty)
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroupsPage(asRoute: true))),
                child: Text('See groups', style: AppFonts.body(size: 12, weight: FontWeight.w500, color: c.accent)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No expenses yet',
              message: 'Create a group and add your first expense to see it here.',
              action: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroupsPage(asRoute: true))),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 15, color: c.onAccent),
                    const SizedBox(width: 6),
                    Text('New group', style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.onAccent)),
                  ]),
                ),
              ),
            ),
          )
        else
          for (final e in recent) ...[
            _RecentExpenseCard(
              expense: e,
              groupName: groups.firstWhere((g) => g.id == e.groupId, orElse: () => Group(id: '', name: '', createdAt: '')).name,
              payerName: e.payerId == 'me' ? 'You' : (friendById[e.payerId]?.name ?? 'Someone'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupDetailsPage(groupId: e.groupId))),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _StatCard({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color ?? c.accent),
          const SizedBox(height: 8),
          Text(label, style: AppFonts.body(size: 11, color: c.textMuted)),
          Text(value,
              style: AppFonts.display(size: 16, weight: FontWeight.w600, color: color ?? c.textPrimary),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RecentExpenseCard extends StatelessWidget {
  final Expense expense;
  final String groupName;
  final String payerName;
  final VoidCallback onTap;
  const _RecentExpenseCard({required this.expense, required this.groupName, required this.payerName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text(initials(expense.title).isNotEmpty ? initials(expense.title) : '₹',
                style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.accentHover)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expense.title,
                    style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text('$groupName · $payerName paid · ${formatDate(expense.date)}',
                    style: AppFonts.body(size: 11, color: c.textMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(formatMoney(expense.amount), style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.textPrimary)),
        ],
      ),
    );
  }
}