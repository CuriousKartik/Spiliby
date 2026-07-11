import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/add_expense_modal.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/qr_modal.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  const GroupDetailsPage({super.key, required this.groupId});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  String tab = 'expenses'; // expenses | settle | summary | dashboard

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final store = context.watch<AppStore>();
    final group = store.groups.where((g) => g.id == widget.groupId).cast<Group?>().firstOrNull;
    if (group == null) {
      return Scaffold(backgroundColor: c.pageBg, body: const SizedBox.shrink());
    }
    final isCompleted = group.status == 'completed';

    final friendById = {for (final f in store.friends) f.id: f};
    final memberIds = store.groupMembers.where((m) => m.groupId == widget.groupId).map((m) => m.friendId);
    final members = <Member>[
      Member(id: 'me', name: store.profile?.name != null ? '${store.profile!.name} (You)' : 'You', qrCode: store.profile?.qrCode),
      for (final id in memberIds) Member(id: id, name: friendById[id]?.name ?? 'Unknown', qrCode: friendById[id]?.qrCode),
    ];
    final memberById = {for (final m in members) m.id: m};
    String nameFor(String id) => memberById[id]?.name ?? 'Someone';

    final groupExpenses = store.expenses.where((e) => e.groupId == widget.groupId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final settlement = store.getGroupSettlement(widget.groupId);
    final paidTx = store.settlements
        .where((s) => s.groupId == widget.groupId && s.status == 'paid')
        .map((s) => Transaction(fromId: s.fromId, toId: s.toId, amount: s.amount))
        .toList();
    bool isPaidTx(Transaction t) => paidTx.any((p) => p.fromId == t.fromId && p.toId == t.toId);

    double total = 0;
    final byCategory = <String, double>{};
    final contribution = <String, double>{};
    for (final e in groupExpenses) {
      total += e.amount;
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      contribution[e.payerId] = (contribution[e.payerId] ?? 0) + e.amount;
    }
    final categoryList = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    Future<void> handleComplete() async {
      await store.completeGroup(widget.groupId);
      setState(() => tab = 'summary');
    }

    Future<void> toggleSettled(Transaction t, bool isPaid) async {
      if (isPaid) {
        await store.unmarkSettled(widget.groupId, t.fromId, t.toId);
      } else {
        await store.markSettled(widget.groupId, t.fromId, t.toId, t.amount);
      }
    }

    void openQr(String memberId) {
      final m = memberById[memberId];
      showQrModal(context, name: m?.name ?? '', qrCode: m?.qrCode);
    }

    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 512),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _RoundIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text('${group.icon} ${group.name}',
                                          style: AppFonts.display(size: 18, weight: FontWeight.w700, color: c.textPrimary),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (isCompleted) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(999)),
                                        child: Text('Completed', style: AppFonts.body(size: 9, weight: FontWeight.w500, color: c.success)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text('${members.length} members', style: AppFonts.body(size: 11, color: c.textMuted)),
                              ],
                            ),
                          ),
                          if (isCompleted)
                            _RoundIconButton(
                              icon: Icons.replay_rounded,
                              onTap: () => store.reopenGroup(widget.groupId),
                            )
                          else
                            _RoundIconButton(
                              icon: Icons.outlined_flag_rounded,
                              color: c.success,
                              onTap: () async {
                                if (await _confirm('Mark this trip as completed? A final settlement summary will be generated.')) {
                                  await handleComplete();
                                }
                              },
                            ),
                          const SizedBox(width: 8),
                          _RoundIconButton(
                            icon: Icons.delete_outline_rounded,
                            color: c.danger,
                            onTap: () async {
                              if (await _confirm('Delete this group and all its expenses?')) {
                                await store.deleteGroup(widget.groupId);
                                if (context.mounted) Navigator.of(context).maybePop();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Expenses',
                              active: tab == 'expenses',
                              onTap: () => setState(() => tab = 'expenses'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TabButton(
                              label: isCompleted ? 'Summary' : 'Settle up',
                              active: tab == 'settle' || tab == 'summary',
                              onTap: () => setState(() => tab = isCompleted ? 'summary' : 'settle'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TabButton(
                              label: 'Dashboard',
                              active: tab == 'dashboard',
                              onTap: () => setState(() => tab = 'dashboard'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (tab == 'expenses')
                        groupExpenses.isEmpty
                            ? AppCard(
                                child: EmptyState(
                                  icon: Icons.receipt_long_rounded,
                                  title: 'No expenses yet',
                                  message: 'Add the first expense for this group.',
                                  action: isCompleted
                                      ? null
                                      : InkWell(
                                          onTap: () => showAddExpenseModal(context, groupId: widget.groupId, members: members),
                                          borderRadius: BorderRadius.circular(999),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(999)),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.add_rounded, size: 15, color: c.onAccent),
                                              const SizedBox(width: 6),
                                              Text('Add expense', style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.onAccent)),
                                            ]),
                                          ),
                                        ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final e in groupExpenses) ...[
                                    _ExpenseRow(
                                      expense: e,
                                      payerName: nameFor(e.payerId),
                                      isCompleted: isCompleted,
                                      onTap: isCompleted
                                          ? null
                                          : () => showAddExpenseModal(context, groupId: widget.groupId, members: members, expense: e),
                                      onDelete: () => store.deleteExpense(e.id),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              )
                      else if (tab == 'dashboard')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total trip expense', style: AppFonts.body(size: 11, color: c.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(formatMoney(total), style: AppFonts.display(size: 24, weight: FontWeight.w600, color: c.textPrimary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(children: [
                              Icon(Icons.pie_chart_rounded, size: 14, color: c.accent),
                              const SizedBox(width: 6),
                              Text('Category-wise spending', style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.textPrimary)),
                            ]),
                            const SizedBox(height: 8),
                            if (categoryList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('No expenses yet.', style: AppFonts.body(size: 12, color: c.textMuted)),
                              )
                            else
                              for (final entry in categoryList) ...[
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
                            const SizedBox(height: 8),
                            Text('Member contribution & balance', style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.textPrimary)),
                            const SizedBox(height: 8),
                            for (final m in members) ...[
                              AppCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: Text(m.name, style: AppFonts.body(size: 13, color: c.textPrimary), overflow: TextOverflow.ellipsis)),
                                    Builder(builder: (_) {
                                      final bal = settlement.balances[m.id] ?? 0;
                                      final settled = bal.abs() < 0.5;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Paid ${formatMoney(contribution[m.id] ?? 0)}', style: AppFonts.body(size: 11, color: c.textMuted)),
                                          Text(
                                            settled ? 'Settled' : (bal > 0 ? 'Owed ${formatMoney(bal)}' : 'Owes ${formatMoney(-bal)}'),
                                            style: AppFonts.body(
                                              size: 11,
                                              weight: FontWeight.w500,
                                              color: settled ? c.textMuted : (bal > 0 ? c.success : c.danger),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        )
                      else if (tab == 'summary')
                        settlement.transactions.isEmpty
                            ? AppCard(
                                child: const EmptyState(
                                  title: 'All settled up',
                                  message: 'Nobody owes anybody in this trip.',
                                  icon: Icons.check_circle_outline,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      'Final settlement summary · minimum ${settlement.transactions.length} transaction${settlement.transactions.length > 1 ? 's' : ''} needed.',
                                      style: AppFonts.body(size: 11, color: c.textMuted),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (final t in settlement.transactions) ...[
                                    _SettleRow(
                                      t: t,
                                      nameFor: nameFor,
                                      isPaid: isPaidTx(t),
                                      showCheckbox: true,
                                      showPay: memberById[t.toId]?.qrCode != null && !isPaidTx(t),
                                      onToggle: () => toggleSettled(t, isPaidTx(t)),
                                      onPay: () => openQr(t.toId),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              )
                      else
                        settlement.transactions.isEmpty
                            ? AppCard(
                                child: const EmptyState(
                                  title: 'All settled up',
                                  message: 'Nobody owes anybody in this group right now.',
                                  icon: Icons.check_circle_outlined,
                                ),
                              )
                            : Column(
                                children: [
                                  for (final t in settlement.transactions) ...[
                                    _SettleRow(
                                      t: t,
                                      nameFor: nameFor,
                                      isPaid: false,
                                      showCheckbox: false,
                                      showPay: memberById[t.toId]?.qrCode != null,
                                      onToggle: () => toggleSettled(t, false),
                                      onPay: () => openQr(t.toId),
                                      showMarkPaid: true,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                    ],
                  ),
                ),
                if (tab == 'expenses' && groupExpenses.isNotEmpty && !isCompleted)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: InkWell(
                      onTap: () => showAddExpenseModal(context, groupId: widget.groupId, members: members),
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: c.accent.withValues(alpha :0.4), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Icon(Icons.add_rounded, size: 24, color: c.onAccent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: c.cardBorder),
        ),
        child: Icon(icon, size: 16, color: color ?? c.textSecondary),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? c.accent : c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: active ? null : Border.all(color: c.cardBorder),
        ),
        child: Text(label, style: AppFonts.body(size: 13, weight: FontWeight.w500, color: active ? c.onAccent : c.textSecondary)),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final String payerName;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  const _ExpenseRow({required this.expense, required this.payerName, required this.isCompleted, this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expense.title, style: AppFonts.body(size: 13, weight: FontWeight.w500, color: c.textPrimary), overflow: TextOverflow.ellipsis),
                Text('${expense.category} · $payerName paid · ${formatDate(expense.date)}',
                    style: AppFonts.body(size: 11, color: c.textMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(formatMoney(expense.amount), style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.textPrimary)),
          if (!isCompleted) ...[
            const SizedBox(width: 8),
            InkWell(onTap: onDelete, child: Icon(Icons.delete_outline_rounded, size: 15, color: c.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _SettleRow extends StatelessWidget {
  final Transaction t;
  final String Function(String) nameFor;
  final bool isPaid;
  final bool showCheckbox;
  final bool showPay;
  final bool showMarkPaid;
  final VoidCallback onToggle;
  final VoidCallback onPay;
  const _SettleRow({
    required this.t,
    required this.nameFor,
    required this.isPaid,
    required this.showCheckbox,
    required this.showPay,
    required this.onToggle,
    required this.onPay,
    this.showMarkPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    final textStyle = AppFonts.body(
      size: 13,
      weight: FontWeight.w500,
      color: isPaid ? c.textMuted : c.textPrimary,
    ).copyWith(decoration: isPaid ? TextDecoration.lineThrough : null);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (showCheckbox) ...[
            Checkbox(value: isPaid, activeColor: c.accent, onChanged: (_) => onToggle()),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(nameFor(t.fromId), style: textStyle, overflow: TextOverflow.ellipsis)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: c.textMuted),
                ),
                Flexible(child: Text(nameFor(t.toId), style: textStyle, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Text(formatMoney(t.amount), style: AppFonts.body(size: 13, weight: FontWeight.w600, color: c.accentHover)),
          if (showPay) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onPay,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.qr_code_rounded, size: 13, color: c.accentHover),
                  const SizedBox(width: 4),
                  Text('Pay', style: AppFonts.body(size: 11, weight: FontWeight.w500, color: c.accentHover)),
                ]),
              ),
            ),
          ],
          if (showMarkPaid) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: c.chipBg, borderRadius: BorderRadius.circular(999)),
                child: Text('Mark paid', style: AppFonts.body(size: 11, weight: FontWeight.w500, color: c.accentHover)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}