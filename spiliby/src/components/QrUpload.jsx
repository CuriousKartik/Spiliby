import { useRef } from 'react';
import { Upload, Trash2, QrCode } from 'lucide-react';

// Converts a selected image file to a base64 data URL and hands it back via
// onChange(dataUrl | null). Storage itself (IndexedDB) happens upstream.
export default function QrUpload({ qrCode, onChange, label = 'Payment QR code' }) {
  const fileRef = useRef();

  const handleFile = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => onChange(reader.result);
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  return (
    <div className="flex items-center gap-3">
      <div className="w-14 h-14 rounded-2xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 flex items-center justify-center overflow-hidden shrink-0">
        {qrCode ? (
          <img src={qrCode} alt="QR" className="w-full h-full object-cover" />
        ) : (
          <QrCode size={22} className="text-blue-slate-500 dark:text-dusty-denim-500" />
        )}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-ink-black-500 dark:text-eggshell-600">{label}</p>
        <p className="text-xs text-dusty-denim-500">{qrCode ? 'Uploaded · shown when others settle up' : 'Upload so friends can pay you instantly'}</p>
      </div>
      <button onClick={() => fileRef.current?.click()} className="w-9 h-9 rounded-xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 flex items-center justify-center shrink-0">
        <Upload size={15} className="text-blue-slate-600 dark:text-dusty-denim-600" />
      </button>
      {qrCode && (
        <button onClick={() => onChange(null)} className="w-9 h-9 rounded-xl bg-red-500/10 flex items-center justify-center shrink-0">
          <Trash2 size={15} className="text-red-500" />
        </button>
      )}
      <input ref={fileRef} type="file" accept="image/*" hidden onChange={handleFile} />
    </div>
  );
}
