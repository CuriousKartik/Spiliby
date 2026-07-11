import { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import useStore from '../store/useStore';
import Card from '../components/Card';
import EmptyState from '../components/EmptyState';
import CreateGroupModal from '../components/CreateGroupModal';
import { formatMoney } from '../lib/format';
import { UsersRound, Plus, Search } from 'lucide-react';

export default function Groups() {
  const groups = useStore((s) => s.groups);
  const groupMembers = useStore((s) => s.groupMembers);
  const getGroupSettlement = useStore((s) => s.getGroupSettlement);
  const [query, setQuery] = useState('');
  const [modalOpen, setModalOpen] = useState(false);

  const filtered = groups.filter((g) => g.name.toLowerCase().includes(query.toLowerCase()));

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="font-display font-bold text-2xl text-ink-black-500 dark:text-eggshell-600">Groups</h1>
        <button onClick={() => setModalOpen(true)} className="w-10 h-10 rounded-2xl bg-blue-slate-500 flex items-center justify-center">
          <Plus size={20} className="text-eggshell-500" />
        </button>
      </div>

      {groups.length > 0 && (
        <div className="relative">
          <Search size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-dusty-denim-500" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search groups"
            className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-400 border border-dusty-denim-200 dark:border-deep-space-blue-200 pl-10 pr-4 py-3 text-sm outline-none focus:border-blue-slate-500 text-ink-black-500 dark:text-eggshell-600"
          />
        </div>
      )}

      {groups.length === 0 ? (
        <Card>
          <EmptyState
            icon={UsersRound}
            title="No groups yet"
            message="Start a group for your hostel room, a trip, or anything you split costs for."
            action={
              <button onClick={() => setModalOpen(true)} className="inline-flex items-center gap-1.5 text-sm font-medium text-eggshell-500 bg-blue-slate-500 rounded-full px-4 py-2">
                <Plus size={15} /> Create group
              </button>
            }
          />
        </Card>
      ) : filtered.length === 0 ? (
        <EmptyState icon={Search} title="No matches" message="Try a different search." />
      ) : (
        <div className="space-y-2.5">
          {filtered.map((g) => {
            const memberCount = groupMembers.filter((m) => m.groupId === g.id).length + 1;
            const { balances } = getGroupSettlement(g.id);
            const myBalance = balances['me'] || 0;
            return (
              <Link key={g.id} to={`/groups/${g.id}`}>
                <Card className="!p-4 flex items-center gap-3">
                  <div className="w-12 h-12 rounded-2xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 flex items-center justify-center text-xl shrink-0">
                    {g.icon || '👥'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1.5">
                      <p className="text-sm font-medium text-ink-black-500 dark:text-eggshell-600 truncate">{g.name}</p>
                      {g.status === 'completed' && <span className="text-[9px] font-medium bg-emerald-500/15 text-emerald-600 rounded-full px-1.5 py-0.5 shrink-0">Done</span>}
                    </div>
                    <p className="text-xs text-dusty-denim-500">{memberCount} members</p>
                  </div>
                  <div className="text-right shrink-0">
                    {Math.abs(myBalance) < 0.5 ? (
                      <p className="text-xs text-dusty-denim-500">Settled</p>
                    ) : myBalance > 0 ? (
                      <>
                        <p className="text-xs text-dusty-denim-500">You're owed</p>
                        <p className="text-sm font-semibold text-emerald-600">{formatMoney(myBalance)}</p>
                      </>
                    ) : (
                      <>
                        <p className="text-xs text-dusty-denim-500">You owe</p>
                        <p className="text-sm font-semibold text-red-500">{formatMoney(-myBalance)}</p>
                      </>
                    )}
                  </div>
                </Card>
              </Link>
            );
          })}
        </div>
      )}

      <CreateGroupModal open={modalOpen} onClose={() => setModalOpen(false)} />
    </div>
  );
}
