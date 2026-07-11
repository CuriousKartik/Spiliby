import { useState } from 'react';
import Modal from './Modal';
import useStore from '../store/useStore';
import { Check } from 'lucide-react';

const PRESETS = ['🏠 Hostel Room', '🏖️ Goa Trip', '🎂 Birthday Party', '☕ Cafe Bills', '🎨 Class Picnic'];

export default function CreateGroupModal({ open, onClose, onCreated }) {
  const friends = useStore((s) => s.friends);
  const createGroup = useStore((s) => s.createGroup);
  const [name, setName] = useState('');
  const [selected, setSelected] = useState([]);

  const toggle = (id) =>
    setSelected((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]));

  const canSave = name.trim() && selected.length > 0;

  const save = async () => {
    if (!canSave) return;
    const group = await createGroup({ name: name.trim(), icon: '👥', memberIds: selected });
    setName(''); setSelected([]);
    onCreated?.(group);
    onClose();
  };

  return (
    <Modal open={open} onClose={onClose} title="New group">
      <div className="space-y-4">
        <input
          autoFocus
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Group name"
          className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500"
        />
        <div className="flex flex-wrap gap-2">
          {PRESETS.map((p) => (
            <button
              key={p}
              onClick={() => setName(p.split(' ').slice(1).join(' '))}
              className="text-xs px-3 py-1.5 rounded-full bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600"
            >
              {p}
            </button>
          ))}
        </div>

        <div>
          <p className="text-xs font-medium text-blue-slate-500 dark:text-dusty-denim-600 mb-2">Add members</p>
          {friends.length === 0 ? (
            <p className="text-sm text-dusty-denim-500">Add some friends first, from the Friends tab.</p>
          ) : (
            <div className="space-y-2 max-h-48 overflow-y-auto no-scrollbar">
              {friends.map((f) => {
                const active = selected.includes(f.id);
                return (
                  <button
                    key={f.id}
                    onClick={() => toggle(f.id)}
                    className={`w-full flex items-center justify-between px-4 py-2.5 rounded-2xl border transition-colors ${
                      active
                        ? 'border-blue-slate-500 bg-blue-slate-500/10'
                        : 'border-dusty-denim-200 dark:border-deep-space-blue-200'
                    }`}
                  >
                    <span className="text-sm text-ink-black-500 dark:text-eggshell-600">{f.name}</span>
                    {active && <Check size={16} className="text-blue-slate-600" />}
                  </button>
                );
              })}
            </div>
          )}
        </div>

        <button
          disabled={!canSave}
          onClick={save}
          className="w-full rounded-2xl bg-blue-slate-500 disabled:bg-dusty-denim-200 text-eggshell-500 font-medium py-3 mt-1 transition-colors"
        >
          Create group
        </button>
      </div>
    </Modal>
  );
}
