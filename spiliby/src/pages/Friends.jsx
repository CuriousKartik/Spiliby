import { useState } from 'react';
import useStore from '../store/useStore';
import Card from '../components/Card';
import EmptyState from '../components/EmptyState';
import AddFriendModal from '../components/AddFriendModal';
import QrUpload from '../components/QrUpload';
import { initials } from '../lib/format';
import { Users, Plus, Search, Trash2 } from 'lucide-react';

export default function Friends() {
  const friends = useStore((s) => s.friends);
  const removeFriend = useStore((s) => s.removeFriend);
  const updateFriendQr = useStore((s) => s.updateFriendQr);
  const [query, setQuery] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [qrFor, setQrFor] = useState(null);

  const filtered = friends.filter((f) =>
    f.name.toLowerCase().includes(query.toLowerCase()) || f.btId.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="font-display font-bold text-2xl text-ink-black-500 dark:text-eggshell-600">Friends</h1>
        <button onClick={() => setModalOpen(true)} className="w-10 h-10 rounded-2xl bg-blue-slate-500 flex items-center justify-center">
          <Plus size={20} className="text-eggshell-500" />
        </button>
      </div>

      {friends.length > 0 && (
        <div className="relative">
          <Search size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-dusty-denim-500" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by name or BT ID"
            className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-400 border border-dusty-denim-200 dark:border-deep-space-blue-200 pl-10 pr-4 py-3 text-sm outline-none focus:border-blue-slate-500 text-ink-black-500 dark:text-eggshell-600"
          />
        </div>
      )}

      {friends.length === 0 ? (
        <Card>
          <EmptyState
            icon={Users}
            title="No friends yet"
            message="Add your roommates and classmates so you can split bills with them."
            action={
              <button onClick={() => setModalOpen(true)} className="inline-flex items-center gap-1.5 text-sm font-medium text-eggshell-500 bg-blue-slate-500 rounded-full px-4 py-2">
                <Plus size={15} /> Add friend
              </button>
            }
          />
        </Card>
      ) : filtered.length === 0 ? (
        <EmptyState icon={Search} title="No matches" message="Try a different search." />
      ) : (
        <div className="space-y-2.5">
          {filtered.map((f) => (
            <Card key={f.id} className="!p-4 space-y-3">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-2xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 flex items-center justify-center text-sm font-medium text-blue-slate-600 dark:text-dusty-denim-600 shrink-0">
                  {initials(f.name)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-ink-black-500 dark:text-eggshell-600 truncate">{f.name}</p>
                  <p className="text-xs text-dusty-denim-500">{f.btId}</p>
                </div>
                <button onClick={() => setQrFor(qrFor === f.id ? null : f.id)} className="text-xs font-medium bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600 rounded-full px-3 py-1.5 shrink-0">
                  QR
                </button>
                <button onClick={() => removeFriend(f.id)} className="text-dusty-denim-400 shrink-0">
                  <Trash2 size={16} />
                </button>
              </div>
              {qrFor === f.id && (
                <div className="pt-1 border-t border-dusty-denim-100 dark:border-deep-space-blue-300">
                  <div className="pt-3">
                    <QrUpload qrCode={f.qrCode} onChange={(qrCode) => updateFriendQr(f.id, qrCode)} label={`${f.name}'s payment QR`} />
                  </div>
                </div>
              )}
            </Card>
          ))}
        </div>
      )}

      <AddFriendModal open={modalOpen} onClose={() => setModalOpen(false)} />
    </div>
  );
}
