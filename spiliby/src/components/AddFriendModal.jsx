import { useState } from 'react';
import Modal from './Modal';
import useStore from '../store/useStore';

export default function AddFriendModal({ open, onClose, onAdded }) {
  const addFriend = useStore((s) => s.addFriend);
  const [name, setName] = useState('');
  const [btId, setBtId] = useState('');
  const canSave = name.trim() && btId.trim();

  const save = async () => {
    if (!canSave) return;
    const friend = await addFriend({ name: name.trim(), btId: btId.trim().toUpperCase() });
    setName(''); setBtId('');
    onAdded?.(friend);
    onClose();
  };

  return (
    <Modal open={open} onClose={onClose} title="Add friend">
      <div className="space-y-3">
        <input
          autoFocus
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Name"
          className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500"
        />
        <input
          value={btId}
          onChange={(e) => setBtId(e.target.value)}
          placeholder="BT ID (e.g. BT25ACS032)"
          className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500 uppercase placeholder:normal-case"
        />
        <button
          disabled={!canSave}
          onClick={save}
          className="w-full rounded-2xl bg-blue-slate-500 disabled:bg-dusty-denim-200 text-eggshell-500 font-medium py-3 mt-2 transition-colors"
        >
          Add friend
        </button>
      </div>
    </Modal>
  );
}
