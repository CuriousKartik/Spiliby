import { useState, useMemo, useEffect } from 'react';
import Modal from './Modal';
import useStore from '../store/useStore';
import { CATEGORIES, QUICK_CATEGORIES } from '../db/db';
import { splitEqually, splitByPercentage } from '../lib/settlement';
import { playClick } from '../lib/sounds';
import { Car, Utensils, Hotel, Ticket, MoreHorizontal } from 'lucide-react';

const SPLIT_TYPES = ['Equal', 'Percentage', 'Custom', 'Exclude'];

const QUICK_ICONS = { Cab: Car, Food: Utensils, Hotel: Hotel, Tickets: Ticket, Misc: MoreHorizontal };

export default function AddExpenseModal({ open, onClose, groupId, members, expense, disabled }) {
  // members: [{ id, name }] — includes { id: 'me', name: 'You' }
  const addExpense = useStore((s) => s.addExpense);
  const updateExpense = useStore((s) => s.updateExpense);
  const isEdit = !!expense;

  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [payerId, setPayerId] = useState('me');
  const [category, setCategory] = useState(QUICK_CATEGORIES[0]);
  const [customCategory, setCustomCategory] = useState('');
  const [notes, setNotes] = useState('');
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [splitType, setSplitType] = useState('Equal');
  const [excluded, setExcluded] = useState([]);
  const [percentages, setPercentages] = useState({});
  const [customAmounts, setCustomAmounts] = useState({});

  useEffect(() => {
    if (!open) return;
    if (expense) {
      setTitle(expense.title || '');
      setAmount(String(expense.amount ?? ''));
      setPayerId(expense.payerId || 'me');
      const isQuick = QUICK_CATEGORIES.includes(expense.category);
      setCategory(isQuick ? expense.category : '__custom');
      setCustomCategory(isQuick ? '' : expense.category || '');
      setNotes(expense.notes || '');
      setDate(expense.date || new Date().toISOString().slice(0, 10));
      setSplitType(expense.splitType || 'Equal');
      setPercentages(expense.splitType === 'Percentage' ? expense.shares || {} : {});
      setCustomAmounts(expense.splitType === 'Custom' ? expense.shares || {} : {});
      const memberIds = members.map((m) => m.id);
      setExcluded(expense.splitType === 'Equal' || expense.splitType === 'Exclude'
        ? memberIds.filter((id) => !(expense.shares || {})[id])
        : []);
    } else {
      reset();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, expense]);

  const amountNum = parseFloat(amount) || 0;
  const effectiveCategory = category === '__custom' ? customCategory.trim() : category;

  const canSave = title.trim() && amountNum > 0 && effectiveCategory;

  const reset = () => {
    setTitle(''); setAmount(''); setPayerId('me'); setCategory(QUICK_CATEGORIES[0]); setCustomCategory('');
    setNotes(''); setDate(new Date().toISOString().slice(0, 10)); setSplitType('Equal');
    setExcluded([]); setPercentages({}); setCustomAmounts({});
  };

  const memberIds = members.map((m) => m.id);

  const shares = useMemo(() => {
    if (splitType === 'Equal') return splitEqually(amountNum, memberIds, excluded);
    if (splitType === 'Exclude') return splitEqually(amountNum, memberIds, excluded);
    if (splitType === 'Percentage') return splitByPercentage(amountNum, percentages);
    if (splitType === 'Custom') {
      const out = {};
      for (const [id, v] of Object.entries(customAmounts)) out[id] = parseFloat(v) || 0;
      return out;
    }
    return {};
  }, [splitType, amountNum, excluded, percentages, customAmounts, memberIds]);

  const shareTotal = Object.values(shares).reduce((a, b) => a + b, 0);
  const percentTotal = Object.values(percentages).reduce((a, b) => a + (parseFloat(b) || 0), 0);

  const save = async () => {
    if (!canSave || disabled) return;
    const payload = {
      groupId, title: title.trim(), amount: amountNum, payerId, category: effectiveCategory,
      notes: notes.trim(), date, splitType, shares,
    };
    if (isEdit) {
      await updateExpense(expense.id, payload);
    } else {
      await addExpense(payload);
    }
    reset();
    onClose();
  };

  const pickQuickCategory = (c) => {
    playClick();
    setCategory(c);
  };

  return (
    <Modal open={open} onClose={onClose} title={isEdit ? 'Edit expense' : 'Add expense'}>
      <div className="space-y-3">
        <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)} placeholder="What was it for?"
          className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500" />

        <input value={amount} onChange={(e) => setAmount(e.target.value)} type="number" inputMode="decimal" placeholder="Amount (₹)"
          className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500" />

        <div className="grid grid-cols-2 gap-3">
          <select value={payerId} onChange={(e) => setPayerId(e.target.value)}
            className="rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-3 py-3 text-sm outline-none">
            {members.map((m) => <option key={m.id} value={m.id}>{m.name} paid</option>)}
          </select>
          <input value={date} onChange={(e) => setDate(e.target.value)} type="date"
            className="rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-3 py-3 text-sm outline-none" />
        </div>

        <div>
          <p className="text-xs font-medium text-blue-slate-500 dark:text-dusty-denim-600 mb-2">Category</p>
          <div className="flex flex-wrap gap-2 mb-2">
            {QUICK_CATEGORIES.map((c) => {
              const Icon = QUICK_ICONS[c];
              const active = category === c;
              return (
                <button
                  key={c}
                  type="button"
                  onClick={() => pickQuickCategory(c)}
                  className={`flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-full transition-colors ${
                    active
                      ? 'bg-blue-slate-500 text-eggshell-500'
                      : 'bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600'
                  }`}
                >
                  {Icon && <Icon size={13} />} {c}
                </button>
              );
            })}
            <button
              type="button"
              onClick={() => { playClick(); setCategory('__custom'); }}
              className={`flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-full transition-colors ${
                category === '__custom'
                  ? 'bg-blue-slate-500 text-eggshell-500'
                  : 'bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600'
              }`}
            >
              Custom
            </button>
          </div>
          {category === '__custom' && (
            <input
              value={customCategory}
              onChange={(e) => setCustomCategory(e.target.value)}
              placeholder="Type a category"
              list="category-options"
              className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500"
            />
          )}
          <datalist id="category-options">
            {CATEGORIES.map((c) => <option key={c} value={c} />)}
          </datalist>
        </div>

        <input value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Notes (optional)"
          className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500" />

        <div>
          <p className="text-xs font-medium text-blue-slate-500 dark:text-dusty-denim-600 mb-2">Split</p>
          <div className="flex gap-2 mb-3">
            {SPLIT_TYPES.map((t) => (
              <button key={t} onClick={() => setSplitType(t)}
                className={`text-xs px-3 py-1.5 rounded-full ${splitType === t ? 'bg-blue-slate-500 text-eggshell-500' : 'bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600'}`}>
                {t}
              </button>
            ))}
          </div>

          {(splitType === 'Equal' || splitType === 'Exclude') && (
            <div className="space-y-1.5">
              {members.map((m) => {
                const isExcluded = excluded.includes(m.id);
                return (
                  <label key={m.id} className="flex items-center justify-between text-sm px-1">
                    <span className={isExcluded ? 'line-through text-dusty-denim-400' : 'text-ink-black-500 dark:text-eggshell-600'}>{m.name}</span>
                    <div className="flex items-center gap-2">
                      {!isExcluded && <span className="text-blue-slate-500 dark:text-dusty-denim-600 text-xs">₹{(shares[m.id] || 0).toFixed(2)}</span>}
                      <input type="checkbox" checked={!isExcluded}
                        onChange={() => setExcluded((ex) => isExcluded ? ex.filter((x) => x !== m.id) : [...ex, m.id])} />
                    </div>
                  </label>
                );
              })}
            </div>
          )}

          {splitType === 'Percentage' && (
            <div className="space-y-1.5">
              {members.map((m) => (
                <div key={m.id} className="flex items-center justify-between text-sm px-1 gap-2">
                  <span className="text-ink-black-500 dark:text-eggshell-600">{m.name}</span>
                  <input type="number" value={percentages[m.id] || ''} placeholder="0"
                    onChange={(e) => setPercentages((p) => ({ ...p, [m.id]: e.target.value }))}
                    className="w-16 rounded-lg bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-2 py-1 text-xs text-right outline-none" />
                </div>
              ))}
              <p className={`text-xs text-right ${Math.round(percentTotal) !== 100 ? 'text-red-500' : 'text-blue-slate-500'}`}>{percentTotal}% of 100%</p>
            </div>
          )}

          {splitType === 'Custom' && (
            <div className="space-y-1.5">
              {members.map((m) => (
                <div key={m.id} className="flex items-center justify-between text-sm px-1 gap-2">
                  <span className="text-ink-black-500 dark:text-eggshell-600">{m.name}</span>
                  <input type="number" value={customAmounts[m.id] || ''} placeholder="0"
                    onChange={(e) => setCustomAmounts((c) => ({ ...c, [m.id]: e.target.value }))}
                    className="w-20 rounded-lg bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-2 py-1 text-xs text-right outline-none" />
                </div>
              ))}
              <p className={`text-xs text-right ${Math.abs(shareTotal - amountNum) > 0.5 ? 'text-red-500' : 'text-blue-slate-500'}`}>₹{shareTotal.toFixed(2)} of ₹{amountNum.toFixed(2)}</p>
            </div>
          )}
        </div>

        <button disabled={!canSave} onClick={save}
          className="w-full rounded-2xl bg-blue-slate-500 disabled:bg-dusty-denim-200 text-eggshell-500 font-medium py-3 mt-2 transition-colors">
          {isEdit ? 'Save changes' : 'Add expense'}
        </button>
      </div>
    </Modal>
  );
}
