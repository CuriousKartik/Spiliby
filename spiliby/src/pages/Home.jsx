import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import useStore from '../store/useStore';
import Card from '../components/Card';
import EmptyState from '../components/EmptyState';
import { formatMoney, formatDate, isToday, isThisMonth, initials } from '../lib/format';
import { Receipt, TrendingUp, Wallet, UsersRound, Plus, ArrowDownCircle, ArrowUpCircle, Clock } from 'lucide-react';

export default function Home() {
  const profile = useStore((s) => s.profile);
  const expenses = useStore((s) => s.expenses);
  const groups = useStore((s) => s.groups);
  const friends = useStore((s) => s.friends);
  const getGroupSettlement = useStore((s) => s.getGroupSettlement);

  const stats = useMemo(() => {
    const todaySpend = expenses.filter((e) => isToday(e.date)).reduce((a, e) => a + e.amount, 0);
    const monthSpend = expenses.filter((e) => isThisMonth(e.date)).reduce((a, e) => a + e.amount, 0);
    let pending = 0;
    let pendingCount = 0;
    let iOwe = 0;
    let owedToMe = 0;
    const paidByMe = expenses.filter((e) => e.payerId === 'me').reduce((a, e) => a + e.amount, 0);
    const byCategory = {};
    for (const e of expenses) byCategory[e.category] = (byCategory[e.category] || 0) + e.amount;

    for (const g of groups) {
      const { transactions } = getGroupSettlement(g.id);
      for (const t of transactions) {
        if (t.fromId === 'me') { iOwe += t.amount; pendingCount++; }
        if (t.toId === 'me') { owedToMe += t.amount; pendingCount++; }
      }
      pending += transactions.filter((t) => t.fromId === 'me' || t.toId === 'me')
        .reduce((a, t) => a + t.amount, 0);
    }
    const categoryList = Object.entries(byCategory).sort((a, b) => b[1] - a[1]).slice(0, 5);
    return { todaySpend, monthSpend, pending, activeGroups: groups.length, paidByMe, iOwe, owedToMe, pendingCount, categoryList };
  }, [expenses, groups, getGroupSettlement]);

  const recentExpenses = [...expenses].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 5);
  const friendById = Object.fromEntries(friends.map((f) => [f.id, f]));

  return (
    <div className="space-y-6">
      <div>
        <p className="text-sm text-blue-slate-500 dark:text-dusty-denim-600">Hey {profile?.name?.split(' ')[0]},</p>
        <h1 className="font-display font-bold text-2xl text-ink-black-500 dark:text-eggshell-600">Here's your money today</h1>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <Card className="!p-4">
          <Receipt size={18} className="text-blue-slate-500 mb-2" />
          <p className="text-xs text-dusty-denim-500">Today</p>
          <p className="font-display font-semibold text-lg text-ink-black-500 dark:text-eggshell-600">{formatMoney(stats.todaySpend)}</p>
        </Card>
        <Card className="!p-4">
          <TrendingUp size={18} className="text-blue-slate-500 mb-2" />
          <p className="text-xs text-dusty-denim-500">This month</p>
          <p className="font-display font-semibold text-lg text-ink-black-500 dark:text-eggshell-600">{formatMoney(stats.monthSpend)}</p>
        </Card>
        <Card className="!p-4">
          <Wallet size={18} className="text-blue-slate-500 mb-2" />
          <p className="text-xs text-dusty-denim-500">You paid</p>
          <p className="font-display font-semibold text-lg text-ink-black-500 dark:text-eggshell-600">{formatMoney(stats.paidByMe)}</p>
        </Card>
        <Card className="!p-4">
          <UsersRound size={18} className="text-blue-slate-500 mb-2" />
          <p className="text-xs text-dusty-denim-500">Active groups</p>
          <p className="font-display font-semibold text-lg text-ink-black-500 dark:text-eggshell-600">{stats.activeGroups}</p>
        </Card>
        <Card className="!p-4">
          <ArrowDownCircle size={18} className="text-red-500 mb-2" />
          <p className="text-xs text-dusty-denim-500">You owe</p>
          <p className="font-display font-semibold text-lg text-red-500">{formatMoney(stats.iOwe)}</p>
        </Card>
        <Card className="!p-4">
          <ArrowUpCircle size={18} className="text-emerald-600 mb-2" />
          <p className="text-xs text-dusty-denim-500">You'll receive</p>
          <p className="font-display font-semibold text-lg text-emerald-600">{formatMoney(stats.owedToMe)}</p>
        </Card>
      </div>

      {stats.pendingCount > 0 && (
        <Card className="!p-4 flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-blue-slate-500/10 flex items-center justify-center shrink-0">
            <Clock size={16} className="text-blue-slate-500" />
          </div>
          <p className="text-sm text-ink-black-500 dark:text-eggshell-600 flex-1">
            <span className="font-semibold">{stats.pendingCount}</span> pending settlement{stats.pendingCount > 1 ? 's' : ''} across your groups
          </p>
        </Card>
      )}

      {stats.categoryList.length > 0 && (
        <div>
          <h2 className="font-display font-semibold text-base text-ink-black-500 dark:text-eggshell-600 mb-3">Category-wise spending</h2>
          <div className="space-y-2">
            {stats.categoryList.map(([cat, amt]) => (
              <Card key={cat} className="!p-3 flex items-center justify-between">
                <span className="text-sm text-ink-black-500 dark:text-eggshell-600">{cat}</span>
                <span className="text-sm font-semibold text-blue-slate-600 dark:text-dusty-denim-500">{formatMoney(amt)}</span>
              </Card>
            ))}
          </div>
        </div>
      )}

      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-display font-semibold text-base text-ink-black-500 dark:text-eggshell-600">Recent expenses</h2>
          {groups.length > 0 && <Link to="/groups" className="text-xs text-blue-slate-500 font-medium">See groups</Link>}
        </div>

        {recentExpenses.length === 0 ? (
          <Card>
            <EmptyState
              icon={Receipt}
              title="No expenses yet"
              message="Create a group and add your first expense to see it here."
              action={
                <Link to="/groups" className="inline-flex items-center gap-1.5 text-sm font-medium text-eggshell-500 bg-blue-slate-500 rounded-full px-4 py-2">
                  <Plus size={15} /> New group
                </Link>
              }
            />
          </Card>
        ) : (
          <div className="space-y-2">
            {recentExpenses.map((e) => {
              const group = groups.find((g) => g.id === e.groupId);
              const payer = e.payerId === 'me' ? 'You' : friendById[e.payerId]?.name || 'Someone';
              return (
                <Card key={e.id} className="!p-3.5 flex items-center gap-3">
                  <div className="w-10 h-10 rounded-2xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 flex items-center justify-center text-sm font-medium text-blue-slate-600 dark:text-dusty-denim-600 shrink-0">
                    {initials(e.title) || '₹'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-ink-black-500 dark:text-eggshell-600 truncate">{e.title}</p>
                    <p className="text-xs text-dusty-denim-500 truncate">{group?.name} · {payer} paid · {formatDate(e.date)}</p>
                  </div>
                  <p className="text-sm font-semibold text-ink-black-500 dark:text-eggshell-600 shrink-0">{formatMoney(e.amount)}</p>
                </Card>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
