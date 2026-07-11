import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/settlement.dart';
import 'app_modal.dart';
import 'app_text_field.dart';

const Map<String, IconData> _quickIcons = {
  'Cab': Icons.local_taxi_rounded,
  'Food': Icons.restaurant_rounded,
  'Hotel': Icons.hotel_rounded,
  'Tickets': Icons.confirmation_number_rounded,
  'Misc': Icons.more_horiz_rounded,
};

Future<void> showAddExpenseModal(
  BuildContext context, {
  required String groupId,
  required List<Member> members,
  Expense? expense,
  bool disabled = false,
}) {
  return showAppModal(
    context: context,
    title: expense != null ? 'Edit expense' : 'Add expense',
    builder: (_) => _AddExpenseForm(groupId: groupId, members: members, expense: expense, disabled: disabled),
  );
}

class _AddExpenseForm extends StatefulWidget {
  final String groupId;
  final List<Member> members;
  final Expense? expense;
  final bool disabled;
  const _AddExpenseForm({required this.groupId, required this.members, this.expense, this.disabled = false});

  @override
  State<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<_AddExpenseForm> {
  final title = TextEditingController();
  final amount = TextEditingController();
  final customCategory = TextEditingController();
  final notes = TextEditingController();
  late String date;
  String payerId = 'me';
  String category = kQuickCategories.first;
  String splitType = 'Equal';
  final Set<String> excluded = {};
  final Map<String, String> percentages = {};
  final Map<String, String> customAmounts = {};

  bool get isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    date = todayIso();
    final e = widget.expense;
    if (e != null) {
      title.text = e.title;
      amount.text = _trimZero(e.amount);
      payerId = e.payerId;
      final isQuick = kQuickCategories.contains(e.category);
      category = isQuick ? e.category : '__custom';
      if (!isQuick) customCategory.text = e.category;
      notes.text = e.notes;
      date = e.date;
      splitType = e.splitType;
      if (e.splitType == 'Percentage') {
        e.shares.forEach((k, v) => percentages[k] = _trimZero(v));
      } else if (e.splitType == 'Custom') {
        e.shares.forEach((k, v) => customAmounts[k] = _trimZero(v));
      }
      if (e.splitType == 'Equal' || e.splitType == 'Exclude') {
        for (final m in widget.members) {
          if (!(e.shares.containsKey(m.id))) excluded.add(m.id);
        }
      }
    }
  }

  static String _trimZero(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    customCategory.dispose();
    notes.dispose();
    super.dispose();
  }

  double get amountNum => double.tryParse(amount.text) ?? 0;
  String get effectiveCategory => category == '__custom' ? customCategory.text.trim() : category;
  bool get canSave => title.text.trim().isNotEmpty && amountNum > 0 && effectiveCategory.isNotEmpty;

  Map<String, double> get shares {
    final memberIds = widget.members.map((m) => m.id).toList();
    if (splitType == 'Equal' || splitType == 'Exclude') {
      return splitEqually(amountNum, memberIds, excluded.toList());
    }
    if (splitType == 'Percentage') {
      final pct = {for (final e in percentages.entries) e.key: double.tryParse(e.value) ?? 0};
      return splitByPercentage(amountNum, pct);
    }
    if (splitType == 'Custom') {
      return {for (final e in customAmounts.entries) e.key: double.tryParse(e.value) ?? 0};
    }
    return {};
  }

  double get shareTotal => shares.values.fold(0.0, (a, b) => a + b);
  double get percentTotal => percentages.values.fold(0.0, (a, b) => a + (double.tryParse(b) ?? 0));

  Future<void> _save() async {
    if (!canSave || widget.disabled) return;
    final store = context.read<AppStore>();
    final payload = Expense(
      id: widget.expense?.id ?? '',
      groupId: widget.groupId,
      title: title.text.trim(),
      amount: amountNum,
      payerId: payerId,
      category: effectiveCategory,
      notes: notes.text.trim(),
      date: date,
      splitType: splitType,
      shares: shares,
      createdAt: widget.expense?.createdAt ?? '',
    );
    if (isEdit) {
      await store.updateExpense(widget.expense!.id, payload);
    } else {
      await store.addExpense(payload);
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => date = picked.toIso8601String().substring(0, 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: title, hint: 'What was it for?', autofocus: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        AppTextField(
          controller: amount,
          hint: 'Amount (₹)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _payerDropdown(c)),
            const SizedBox(width: 12),
            Expanded(child: _dateField(c)),
          ],
        ),
        const SizedBox(height: 16),
        Text('Category', style: AppFonts.body(size: 12, weight: FontWeight.w600, color: c.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in kQuickCategories) _categoryChip(c, cat, icon: _quickIcons[cat]),
            _categoryChip(c, '__custom', label: 'Custom'),
          ],
        ),
        if (category == '__custom') ...[
          const SizedBox(height: 8),
          AppTextField(controller: customCategory, hint: 'Type a category', onChanged: (_) => setState(() {})),
        ],
        const SizedBox(height: 12),
        AppTextField(controller: notes, hint: 'Notes (optional)'),
        const SizedBox(height: 16),
        Text('Split', style: AppFonts.body(size: 12, weight: FontWeight.w600, color: c.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in kSplitTypes) _splitTypeChip(c, t)],
        ),
        const SizedBox(height: 12),
        _splitEditor(c),
        const SizedBox(height: 16),
        AppPrimaryButton(label: isEdit ? 'Save changes' : 'Add expense', onPressed: canSave ? _save : null),
      ],
    );
  }

  Widget _payerDropdown(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.inputBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: payerId,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.textMuted),
          style: AppFonts.body(size: 13, color: c.textPrimary),
          dropdownColor: c.inputBg,
          items: [
            for (final m in widget.members)
              DropdownMenuItem(value: m.id, child: Text('${m.name} paid', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => payerId = v ?? payerId),
        ),
      ),
    );
  }

  Widget _dateField(AppColors c) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: c.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.inputBorder),
        ),
        child: Text(formatDate(date), style: AppFonts.body(size: 13, color: c.textPrimary)),
      ),
    );
  }

  Widget _categoryChip(AppColors c, String value, {String? label, IconData? icon}) {
    final active = category == value;
    return InkWell(
      onTap: () => setState(() => category = value),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c.accent : c.chipBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: active ? c.onAccent : c.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(label ?? value, style: AppFonts.body(size: 12, color: active ? c.onAccent : c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _splitTypeChip(AppColors c, String t) {
    final active = splitType == t;
    return InkWell(
      onTap: () => setState(() => splitType = t),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: active ? c.accent : c.chipBg, borderRadius: BorderRadius.circular(999)),
        child: Text(t, style: AppFonts.body(size: 12, color: active ? c.onAccent : c.textSecondary)),
      ),
    );
  }

  Widget _splitEditor(AppColors c) {
    if (splitType == 'Equal' || splitType == 'Exclude') {
      final s = shares;
      return Column(
        children: [
          for (final m in widget.members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    m.name,
                    style: AppFonts.body(
                      size: 14,
                      color: excluded.contains(m.id) ? c.textMuted : c.textPrimary,
                      height: 1,
                    ).copyWith(decoration: excluded.contains(m.id) ? TextDecoration.lineThrough : null),
                  ),
                  Row(
                    children: [
                      if (!excluded.contains(m.id))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text('₹${(s[m.id] ?? 0).toStringAsFixed(2)}',
                              style: AppFonts.body(size: 12, color: c.textSecondary)),
                        ),
                      Checkbox(
                        value: !excluded.contains(m.id),
                        activeColor: c.accent,
                        onChanged: (_) => setState(() {
                          if (excluded.contains(m.id)) {
                            excluded.remove(m.id);
                          } else {
                            excluded.add(m.id);
                          }
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (splitType == 'Percentage') {
      return Column(
        children: [
          for (final m in widget.members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(m.name, style: AppFonts.body(size: 14, color: c.textPrimary))),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      style: AppFonts.body(size: 12, color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: '0',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        filled: true,
                        fillColor: c.inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent)),
                      ),
                      onChanged: (v) => setState(() => percentages[m.id] = v),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${percentTotal.round()}% of 100%',
              style: AppFonts.body(size: 11, color: percentTotal.round() != 100 ? c.danger : c.textMuted),
            ),
          ),
        ],
      );
    }

    // Custom
    return Column(
      children: [
        for (final m in widget.members)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(m.name, style: AppFonts.body(size: 14, color: c.textPrimary))),
                SizedBox(
                  width: 80,
                  child: TextField(
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppFonts.body(size: 12, color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: '0',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      filled: true,
                      fillColor: c.inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent)),
                    ),
                    onChanged: (v) => setState(() => customAmounts[m.id] = v),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '₹${shareTotal.toStringAsFixed(2)} of ₹${amountNum.toStringAsFixed(2)}',
            style: AppFonts.body(size: 11, color: (shareTotal - amountNum).abs() > 0.5 ? c.danger : c.textMuted),
          ),
        ),
      ],
    );
  }
}