import { useState } from 'react';
import useStore from '../store/useStore';
import { Wallet } from 'lucide-react';

export default function Onboarding() {
  const createProfile = useStore((s) => s.createProfile);
  const [name, setName] = useState('');
  const [btId, setBtId] = useState('');
  const canSave = name.trim() && btId.trim();

  return (
    <div className="min-h-screen flex flex-col justify-center px-8 bg-eggshell-500 dark:bg-ink-black-400">
      <div className="max-w-sm mx-auto w-full">
        <img src="/assets/images/welcome.png" alt="" className="w-24 h-24 mb-5 object-contain" />
        <div className="w-16 h-16 rounded-2xl bg-blue-slate-500 flex items-center justify-center mb-6">
          <Wallet size={28} className="text-eggshell-500" strokeWidth={2} />
        </div>
        <h1 className="font-display font-bold text-3xl text-ink-black-500 dark:text-eggshell-600 mb-2">Welcome to Spiliby</h1>
        <p className="text-blue-slate-500 dark:text-dusty-denim-600 text-sm mb-8">
          Split bills with your hostel mates in seconds. No login, no password, no internet, no fuss — just tell us who you are.
        </p>

        <div className="space-y-3">
          <input
            autoFocus
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name"
            className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-400 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3.5 text-sm outline-none focus:border-blue-slate-500 text-ink-black-500 dark:text-eggshell-600"
          />
          <input
            value={btId}
            onChange={(e) => setBtId(e.target.value)}
            placeholder="BT ID (e.g. BT25CSE032)"
            className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-400 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3.5 text-sm outline-none focus:border-blue-slate-500 uppercase placeholder:normal-case text-ink-black-500 dark:text-eggshell-600"
          />
        </div>

        <button
          disabled={!canSave}
          onClick={() => createProfile({ name: name.trim(), btId: btId.trim().toUpperCase() })}
          className="w-full rounded-2xl bg-blue-slate-500 disabled:bg-dusty-denim-200 text-eggshell-500 font-medium py-3.5 mt-6 transition-colors"
        >
          Get started
        </button>
        <p className="text-xs text-dusty-denim-500 text-center mt-4">Everything stays on this device. Always.</p>
        <p className="text-[11px] text-dusty-denim-400 text-center mt-2">Free to use · no accounts · protected as a proprietary app.</p>
      </div>
    </div>
  );
}
