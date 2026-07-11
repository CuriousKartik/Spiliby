import { X } from 'lucide-react';

export default function Modal({ open, onClose, title, children }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-ink-black-500/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative w-full sm:max-w-md max-h-[88vh] overflow-y-auto no-scrollbar bg-eggshell-500 dark:bg-deep-space-blue-400 rounded-t-3xl sm:rounded-3xl p-5 pb-8 animate-[slideUp_0.2s_ease-out]">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-display font-semibold text-lg text-ink-black-500 dark:text-eggshell-600">{title}</h2>
          <button onClick={onClose} className="w-8 h-8 rounded-full flex items-center justify-center bg-dusty-denim-100 dark:bg-deep-space-blue-300">
            <X size={16} className="text-blue-slate-500 dark:text-dusty-denim-600" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
