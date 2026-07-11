import { useState, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import useStore from '../store/useStore';
import Card from '../components/Card';
import EmptyState from '../components/EmptyState';
import AddExpenseModal from '../components/AddExpenseModal';
import QrModal from '../components/QrModal';
import { formatMoney, formatDate } from '../lib/format';
import { playSuccess, playClick } from '../lib/sounds';
import { ChevronLeft, Plus, Receipt, ArrowRight, Trash2, Check, QrCode, FlagOff, RotateCcw, PieChart } from 'lucide-react';

export default function GroupDetails() {
  const { groupId } = useParams();
  const navigate = useNavigate();
  const profile = useStore((s) => s.profile);
  const groups = useStore((s) => s.groups);
  const groupMembers = useStore((s) => s.groupMembers);
  const friends = useStore((s) => s.friends);
  const expenses = useStore((s) => s.expenses);
  const settlements = useStore((s) => s.settlements);
  const getGroupSettlement = useStore((s) => s.getGroupSettlement);
  const deleteExpense = useStore((s) => s.deleteExpense);
  const deleteGroup = useStore((s) => s.deleteGroup);
  const markSettled = useStore((s) => s.markSettled);
  const unmarkSettled = useStore((s) => s.unmarkSettled);
  const completeGroup = useStore((s) => s.completeGroup);
  const reopenGroup = useStore((s) => s.reopenGroup);

  const [modalOpen, setModalOpen] = useState(false);
  const [editingExpense, setEditingExpense] = useState(null);
  const [tab, setTab] = useState('expenses');
  const [qrTarget, setQrTarget] = useState(null); // { id, name, qrCode }

  const group = groups.find((g) => g.id === groupId);
  const friendById = Object.fromEntries(friends.map((f) => [f.id, f]));
  const isCompleted = group?.status === 'completed';

  const members = useMemo(() => {
    const ids = groupMembers.filter((m) => m.groupId === groupId).map((m) => m.friendId);
    return [
      { id: 'me', name: profile?.name ? `${profile.name} (You)` : 'You', qrCode: profile?.qrCode },
      ...ids.map((id) => ({ id, name: friendById[id]?.name || 'Unknown', qrCode: friendById[id]?.qrCode })),
    ];
  }, [groupMembers, groupId, friends, profile]);

  const memberById = Object.fromEntries(members.map((m) => [m.id, m]));
  const nameFor = (id) => memberById[id]?.name || 'Someone';

  const groupExpenses = expenses
    .filter((e) => e.groupId === groupId)
    .sort((a, b) => new Date(b.date) - new Date(a.date));

  const { transactions, balances } = getGroupSettlement(groupId);

  const paidTransactions = useMemo(() => {
    return settlements
      .filter((s) => s.groupId === groupId && s.status === 'paid')
      .map((s) => ({ fromId: s.fromId, toId: s.toId, amount: s.amount }));
  }, [settlements, groupId]);

  const dashboard = useMemo(() => {
    const total = groupExpenses.reduce((a, e) => a + e.amount, 0);
    const byCategory = {};
    for (const e of groupExpenses) {
      byCategory[e.category] = (byCategory[e.category] || 0) + e.amount;
    }
    const categoryList = Object.entries(byCategory).sort((a, b) => b[1] - a[1]);
    const contribution = {};
    for (const e of groupExpenses) {
      contribution[e.payerId] = (contribution[e.payerId] || 0) + e.amount;
    }
    return { total, categoryList, contribution };
  }, [groupExpenses]);

  if (!group) return null;

  const openQr = (memberId) => {
    const m = memberById[memberId];
    setQrTarget({ id: memberId, name: m?.name, qrCode: m?.qrCode });
  };

  const handleComplete = async () => {
    playSuccess();
    await completeGroup(groupId);
    setTab('summary');
  };

  const toggleSettled = async (t, isPaid) => {
    playClick();
    if (isPaid) {
      await unmarkSettled(groupId, t.fromId, t.toId);
    } else {
      await markSettled(groupId, t.fromId, t.toId, t.amount);
      playSuccess();
    }
  };

  const isPaidTx = (t) => paidTransactions.some((p) => p.fromId === t.fromId && p.toId === t.toId);

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3">
        <button onClick={() => navigate('/groups')} className="w-9 h-9 rounded-full bg-white dark:bg-deep-space-blue-400 flex items-center justify-center border border-dusty-denim-100 dark:border-deep-space-blue-300">
          <ChevronLeft size={18} className="text-blue-slate-600 dark:text-dusty-denim-600" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h1 className="font-display font-bold text-xl text-ink-black-500 dark:text-eggshell-600 truncate">{group.icon} {group.name}</h1>
            {isCompleted && <span className="text-[10px] font-medium bg-emerald-500/15 text-emerald-600 rounded-full px-2 py-0.5 shrink-0">Completed</span>}
          </div>
          <p className="text-xs text-dusty-denim-500">{members.length} members</p>
        </div>
        {isCompleted ? (
          <button
            onClick={() => reopenGroup(groupId)}
            className="w-9 h-9 rounded-full bg-white dark:bg-deep-space-blue-400 flex items-center justify-center border border-dusty-denim-100 dark:border-deep-space-blue-300"
            title="Reopen trip"
          >
            <RotateCcw size={16} className="text-blue-slate-600 dark:text-dusty-denim-600" />
          </button>
        ) : (
          <button
            onClick={() => { if (confirm('Mark this trip as completed? A final settlement summary will be generated.')) handleComplete(); }}
            className="w-9 h-9 rounded-full bg-white dark:bg-deep-space-blue-400 flex items-center justify-center border border-dusty-denim-100 dark:border-deep-space-blue-300"
            title="Complete trip"
          >
            <FlagOff size={16} className="text-emerald-600" />
          </button>
        )}
        <button
          onClick={() => { if (confirm('Delete this group and all its expenses?')) { deleteGroup(groupId); navigate('/groups'); } }}
          className="w-9 h-9 rounded-full bg-white dark:bg-deep-space-blue-400 flex items-center justify-center border border-dusty-denim-100 dark:border-deep-space-blue-300"
        >
          <Trash2 size={16} className="text-red-500" />
        </button>
      </div>

      <div className="flex gap-2">
        <button onClick={() => setTab('expenses')} className={`flex-1 text-sm font-medium py-2.5 rounded-2xl ${tab === 'expenses' ? 'bg-blue-slate-500 text-eggshell-500' : 'bg-white dark:bg-deep-space-blue-400 text-blue-slate-600 dark:text-dusty-denim-600 border border-dusty-denim-100 dark:border-deep-space-blue-300'}`}>Expenses</button>
        <button onClick={() => setTab(isCompleted ? 'summary' : 'settle')} className={`flex-1 text-sm font-medium py-2.5 rounded-2xl ${(tab === 'settle' || tab === 'summary') ? 'bg-blue-slate-500 text-eggshell-500' : 'bg-white dark:bg-deep-space-blue-400 text-blue-slate-600 dark:text-dusty-denim-600 border border-dusty-denim-100 dark:border-deep-space-blue-300'}`}>{isCompleted ? 'Summary' : 'Settle up'}</button>
        <button onClick={() => setTab('dashboard')} className={`flex-1 text-sm font-medium py-2.5 rounded-2xl ${tab === 'dashboard' ? 'bg-blue-slate-500 text-eggshell-500' : 'bg-white dark:bg-deep-space-blue-400 text-blue-slate-600 dark:text-dusty-denim-600 border border-dusty-denim-100 dark:border-deep-space-blue-300'}`}>Dashboard</button>
      </div>

      {tab === 'expenses' ? (
        groupExpenses.length === 0 ? (
          <Card>
            <EmptyState
              icon={Receipt}
              title="No expenses yet"
              message="Add the first expense for this group."
              action={
                !isCompleted && (
                  <button onClick={() => setModalOpen(true)} className="inline-flex items-center gap-1.5 text-sm font-medium text-eggshell-500 bg-blue-slate-500 rounded-full px-4 py-2">
                    <Plus size={15} /> Add expense
                  </button>
                )
              }
            />
          </Card>
        ) : (
          <div className="space-y-2.5">
            {groupExpenses.map((e) => (
              <Card key={e.id} className="!p-3.5 flex items-center gap-3" onClick={isCompleted ? undefined : () => setEditingExpense(e)}>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-ink-black-500 dark:text-eggshell-600 truncate">{e.title}</p>
                  <p className="text-xs text-dusty-denim-500 truncate">{e.category} · {nameFor(e.payerId)} paid · {formatDate(e.date)}</p>
                </div>
                <p className="text-sm font-semibold text-ink-black-500 dark:text-eggshell-600 shrink-0">{formatMoney(e.amount)}</p>
                {!isCompleted && (
                  <button onClick={(ev) => { ev.stopPropagation(); deleteExpense(e.id); }} className="text-dusty-denim-400 shrink-0">
                    <Trash2 size={15} />
                  </button>
                )}
              </Card>
            ))}
          </div>
        )
      ) : tab === 'dashboard' ? (
        <div className="space-y-4">
          <Card className="!p-4 space-y-1">
            <p className="text-xs text-dusty-denim-500">Total trip expense</p>
            <p className="font-display font-semibold text-2xl text-ink-black-500 dark:text-eggshell-600">{formatMoney(dashboard.total)}</p>
          </Card>

          <div>
            <div className="flex items-center gap-1.5 mb-2">
              <PieChart size={14} className="text-blue-slate-500" />
              <h3 className="text-sm font-semibold text-ink-black-500 dark:text-eggshell-600">Category-wise spending</h3>
            </div>
            {dashboard.categoryList.length === 0 ? (
              <p className="text-xs text-dusty-denim-500 px-1">No expenses yet.</p>
            ) : (
              <div className="space-y-2">
                {dashboard.categoryList.map(([cat, amt]) => (
                  <Card key={cat} className="!p-3 flex items-center justify-between">
                    <span className="text-sm text-ink-black-500 dark:text-eggshell-600">{cat}</span>
                    <span className="text-sm font-semibold text-blue-slate-600 dark:text-dusty-denim-500">{formatMoney(amt)}</span>
                  </Card>
                ))}
              </div>
            )}
          </div>

          <div>
            <h3 className="text-sm font-semibold text-ink-black-500 dark:text-eggshell-600 mb-2">Member contribution & balance</h3>
            <div className="space-y-2">
              {members.map((m) => {
                const bal = balances[m.id] || 0;
                return (
                  <Card key={m.id} className="!p-3 flex items-center justify-between gap-2">
                    <span className="text-sm text-ink-black-500 dark:text-eggshell-600 truncate">{m.name}</span>
                    <div className="text-right shrink-0">
                      <p className="text-xs text-dusty-denim-500">Paid {formatMoney(dashboard.contribution[m.id] || 0)}</p>
                      <p className={`text-xs font-medium ${Math.abs(bal) < 0.5 ? 'text-dusty-denim-500' : bal > 0 ? 'text-emerald-600' : 'text-red-500'}`}>
                        {Math.abs(bal) < 0.5 ? 'Settled' : bal > 0 ? `Owed ${formatMoney(bal)}` : `Owes ${formatMoney(-bal)}`}
                      </p>
                    </div>
                  </Card>
                );
              })}
            </div>
          </div>
        </div>
      ) : tab === 'summary' ? (
        transactions.length === 0 ? (
          <Card>
            <EmptyState image="/assets/images/success.png" title="All settled up" message="Nobody owes anybody in this trip." />
          </Card>
        ) : (
          <div className="space-y-2.5">
            <p className="text-xs text-dusty-denim-500 px-1">Final settlement summary · minimum {transactions.length} transaction{transactions.length > 1 ? 's' : ''} needed.</p>
            {transactions.map((t, i) => {
              const isPaid = isPaidTx(t);
              const recipient = memberById[t.toId];
              return (
                <Card key={i} className="!p-4 flex items-center gap-3">
                  <input type="checkbox" checked={isPaid} onChange={() => toggleSettled(t, isPaid)} className="w-4 h-4 shrink-0" />
                  <div className="flex-1 flex items-center gap-2 text-sm min-w-0">
                    <span className={`font-medium truncate ${isPaid ? 'line-through text-dusty-denim-400' : 'text-ink-black-500 dark:text-eggshell-600'}`}>{nameFor(t.fromId)}</span>
                    <ArrowRight size={14} className="text-dusty-denim-400 shrink-0" />
                    <span className={`font-medium truncate ${isPaid ? 'line-through text-dusty-denim-400' : 'text-ink-black-500 dark:text-eggshell-600'}`}>{nameFor(t.toId)}</span>
                  </div>
                  <p className="text-sm font-semibold text-blue-slate-600 dark:text-dusty-denim-500 shrink-0">{formatMoney(t.amount)}</p>
                  {recipient?.qrCode && !isPaid && (
                    <button onClick={() => openQr(t.toId)} className="text-xs font-medium bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600 rounded-full px-3 py-1.5 shrink-0 flex items-center gap-1">
                      <QrCode size={13} /> Pay
                    </button>
                  )}
                </Card>
              );
            })}
          </div>
        )
      ) : transactions.length === 0 ? (
        <Card>
          <EmptyState image="/assets/images/success.png" title="All settled up" message="Nobody owes anybody in this group right now." />
        </Card>
      ) : (
        <div className="space-y-2.5">
          {transactions.map((t, i) => {
            const recipient = memberById[t.toId];
            return (
              <Card key={i} className="!p-4 flex items-center gap-3">
                <div className="flex-1 flex items-center gap-2 text-sm min-w-0">
                  <span className="font-medium text-ink-black-500 dark:text-eggshell-600 truncate">{nameFor(t.fromId)}</span>
                  <ArrowRight size={14} className="text-dusty-denim-400 shrink-0" />
                  <span className="font-medium text-ink-black-500 dark:text-eggshell-600 truncate">{nameFor(t.toId)}</span>
                </div>
                <p className="text-sm font-semibold text-blue-slate-600 dark:text-dusty-denim-500 shrink-0">{formatMoney(t.amount)}</p>
                {recipient?.qrCode && (
                  <button onClick={() => openQr(t.toId)} className="text-xs font-medium bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600 rounded-full px-3 py-1.5 shrink-0 flex items-center gap-1">
                    <QrCode size={13} /> Pay
                  </button>
                )}
                <button
                  onClick={() => toggleSettled(t, false)}
                  className="text-xs font-medium bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600 rounded-full px-3 py-1.5 shrink-0"
                >
                  Mark paid
                </button>
              </Card>
            );
          })}
        </div>
      )}

      {tab === 'expenses' && groupExpenses.length > 0 && !isCompleted && (
        <button onClick={() => setModalOpen(true)} className="fixed bottom-24 right-6 w-14 h-14 rounded-full bg-blue-slate-500 shadow-lg flex items-center justify-center">
          <Plus size={24} className="text-eggshell-500" />
        </button>
      )}

      <AddExpenseModal open={modalOpen} onClose={() => setModalOpen(false)} groupId={groupId} members={members} disabled={isCompleted} />
      <AddExpenseModal open={!!editingExpense} onClose={() => setEditingExpense(null)} groupId={groupId} members={members} expense={editingExpense} disabled={isCompleted} />
      <QrModal open={!!qrTarget} onClose={() => setQrTarget(null)} name={qrTarget?.name} qrCode={qrTarget?.qrCode} />
    </div>
  );
}
