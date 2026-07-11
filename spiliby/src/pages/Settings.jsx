import { useEffect, useRef, useState } from 'react';
import useStore from '../store/useStore';
import Card from '../components/Card';
import Modal from '../components/Modal';
import QrUpload from '../components/QrUpload';
import { requestPermission } from '../lib/notifications';
import { db } from '../db/db';
import { SyncManager } from '../services/SyncManager';
import {
  Moon, Sun, Bell, Download, Upload, User, Trash2, ChevronRight, Share2, ScanLine,
} from 'lucide-react';

export default function Settings() {
  const profile = useStore((s) => s.profile);
  const theme = useStore((s) => s.theme);
  const toggleTheme = useStore((s) => s.toggleTheme);
  const updateProfile = useStore((s) => s.updateProfile);
  const exportData = useStore((s) => s.exportData);
  const importData = useStore((s) => s.importData);
  const clearAllData = useStore((s) => s.clearAllData);

  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(profile?.name || '');
  const [btId, setBtId] = useState(profile?.btId || '');
  const [notifOn, setNotifOn] = useState(true);
  const [shareModalOpen, setShareModalOpen] = useState(false);
  const [shareQr, setShareQr] = useState('');
  const [shareBusy, setShareBusy] = useState(false);
  const [scanModalOpen, setScanModalOpen] = useState(false);
  const [scanStatus, setScanStatus] = useState('Point your camera at a Spiliby QR code.');
  const fileRef = useRef();
  const qrFileRef = useRef();
  const scannerRef = useRef(null);

  const saveProfile = async () => {
    await updateProfile({ name: name.trim(), btId: btId.trim().toUpperCase() });
    setEditing(false);
  };

  const download = (data, filename, mime) => {
    const blob = new Blob([data], { type: mime });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = filename; a.click();
    URL.revokeObjectURL(url);
  };

  const handleExportJson = async () => {
    const data = await exportData();
    download(JSON.stringify(data, null, 2), 'spiliby-backup.json', 'application/json');
  };

  const handleExportCsv = async () => {
    const data = await exportData();
    const rows = [['Title', 'Amount', 'Category', 'Date', 'Group', 'Payer']];
    const groupById = Object.fromEntries(data.groups.map((g) => [g.id, g.name]));
    for (const e of data.expenses) {
      rows.push([e.title, e.amount, e.category, e.date, groupById[e.groupId] || '', e.payerId]);
    }
    const csv = rows.map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n');
    download(csv, 'spiliby-expenses.csv', 'text/csv');
  };

  const handleImport = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    try {
      const data = JSON.parse(text);
      await importData(data);
      alert('Backup imported.');
    } catch {
      alert('Could not read that file. Make sure it is a Spiliby JSON backup.');
    }
    e.target.value = '';
  };

  const handleShareToPhone = async () => {
    try {
      setShareBusy(true);
      const data = await exportData();
      const qrDataUrl = await SyncManager.generateQrForBackup(data);
      setShareQr(qrDataUrl);
      setShareModalOpen(true);
    } catch (error) {
      alert(error instanceof Error ? error.message : 'Unable to create a share QR.');
    } finally {
      setShareBusy(false);
    }
  };

  const handleImportQr = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = async () => {
      try {
        const data = await SyncManager.importFromQrImage(reader.result);
        await importData(data);
        alert('Backup imported from QR code.');
      } catch (error) {
        alert(error instanceof Error ? error.message : 'Could not read that QR code.');
      } finally {
        e.target.value = '';
      }
    };
    reader.readAsDataURL(file);
  };

  const startScanner = () => {
    setScanModalOpen(true);
    setScanStatus('Point your camera at a Spiliby QR code.');
  };

  useEffect(() => {
    if (!scanModalOpen) return;

    let cancelled = false;
    let scanner;

    const initScanner = async () => {
      const { Html5QrcodeScanner } = await import('html5-qrcode');
      if (cancelled) return;

      const elementId = 'spiliby-qr-scanner';
      scanner = new Html5QrcodeScanner(
        elementId,
        { fps: 10, qrbox: { width: 260, height: 260 }, aspectRatio: 1.0 },
        false
      );

      scannerRef.current = scanner;
      scanner.render(async (text) => {
        try {
          setScanStatus('Reading data…');
          const data = await SyncManager.importFromQrImage(text);
          await importData(data);
          setScanStatus('Imported successfully.');
          setTimeout(() => {
            setScanModalOpen(false);
            setScanStatus('Point your camera at a Spiliby QR code.');
          }, 800);
        } catch (error) {
          setScanStatus(error instanceof Error ? error.message : 'Unable to read QR code.');
        }
      }, () => {
        setScanStatus('Scanning… keep the QR in view.');
      });
    };

    initScanner();

    return () => {
      cancelled = true;
      scanner?.clear?.().catch(() => undefined);
      scannerRef.current = null;
    };
  }, [scanModalOpen, importData]);

  const handleNotifToggle = async () => {
    const next = !notifOn;
    setNotifOn(next);
    if (next) await requestPermission();
    const settings = (await db.settings.get('app')) || { id: 'app' };
    await db.settings.put({ ...settings, notificationsEnabled: next });
  };

  const handleClear = async () => {
    if (confirm('This deletes every friend, group, and expense on this device. Continue?')) {
      await clearAllData();
    }
  };

  return (
    <div className="space-y-5">
      <h1 className="font-display font-bold text-2xl text-ink-black-500 dark:text-eggshell-600">Settings</h1>

      <Card>
        {editing ? (
          <div className="space-y-3">
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Name"
              className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500" />
            <input value={btId} onChange={(e) => setBtId(e.target.value)} placeholder="BT ID"
              className="w-full rounded-2xl bg-white dark:bg-deep-space-blue-300 border border-dusty-denim-200 dark:border-deep-space-blue-200 px-4 py-3 text-sm outline-none focus:border-blue-slate-500 uppercase" />
            <div className="flex gap-2">
              <button onClick={saveProfile} className="flex-1 rounded-2xl bg-blue-slate-500 text-eggshell-500 font-medium py-2.5">Save</button>
              <button onClick={() => setEditing(false)} className="flex-1 rounded-2xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600 font-medium py-2.5">Cancel</button>
            </div>
          </div>
        ) : (
          <button onClick={() => setEditing(true)} className="w-full flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-blue-slate-500 flex items-center justify-center text-eggshell-500 font-display font-semibold">
              {profile?.name?.[0]?.toUpperCase()}
            </div>
            <div className="flex-1 text-left min-w-0">
              <p className="text-sm font-medium text-ink-black-500 dark:text-eggshell-600 truncate">{profile?.name}</p>
              <p className="text-xs text-dusty-denim-500">{profile?.btId}</p>
            </div>
            <ChevronRight size={18} className="text-dusty-denim-400" />
          </button>
        )}
      </Card>

      <Card>
        <QrUpload qrCode={profile?.qrCode} onChange={(qrCode) => updateProfile({ qrCode })} label="My payment QR code" />
      </Card>

      <Card className="!p-3.5">
        <div className="space-y-3">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-blue-slate-500/10 flex items-center justify-center shrink-0">
              <Share2 size={17} className="text-blue-slate-600" />
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium text-ink-black-500 dark:text-eggshell-600">Offline sync between phones</p>
              <p className="text-xs text-dusty-denim-500">Works locally first; use QR sharing when two phones are nearby and no internet is available.</p>
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={handleShareToPhone} className="flex-1 rounded-2xl bg-blue-slate-500 text-eggshell-500 font-medium py-2.5">
              {shareBusy ? 'Preparing…' : 'Share via QR'}
            </button>
            <button onClick={startScanner} className="flex-1 rounded-2xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 text-blue-slate-600 dark:text-dusty-denim-600 font-medium py-2.5 flex items-center justify-center gap-2">
              <ScanLine size={16} />
              Scan QR
            </button>
          </div>
          <input ref={qrFileRef} type="file" accept="image/*" hidden onChange={handleImportQr} />
        </div>
      </Card>

      <div className="space-y-2.5">
        <SettingRow icon={theme === 'dark' ? Moon : Sun} label="Dark mode" toggle value={theme === 'dark'} onToggle={toggleTheme} />
        <SettingRow icon={Bell} label="Notifications" toggle value={notifOn} onToggle={handleNotifToggle} />
        <SettingRow icon={Download} label="Export as JSON" onClick={handleExportJson} />
        <SettingRow icon={Download} label="Export as CSV" onClick={handleExportCsv} />
        <SettingRow icon={Upload} label="Import backup" onClick={() => fileRef.current?.click()} />
        <input ref={fileRef} type="file" accept="application/json" hidden onChange={handleImport} />
        <SettingRow icon={Trash2} label="Clear all data" danger onClick={handleClear} />
      </div>

      <Modal open={shareModalOpen} onClose={() => setShareModalOpen(false)} title="Share backup">
        <div className="space-y-3">
          <p className="text-sm text-dusty-denim-500">This is the offline fallback for sharing group data between nearby phones. If needed, you can also use the internet and send the JSON backup file.</p>
          {shareQr ? <img src={shareQr} alt="Backup QR code" className="w-full max-w-[280px] mx-auto rounded-2xl bg-white p-3" /> : <p className="text-sm text-dusty-denim-500">Preparing your share code…</p>}
        </div>
      </Modal>

      <Modal open={scanModalOpen} onClose={() => setScanModalOpen(false)} title="Scan QR code">
        <div className="space-y-3">
          <p className="text-sm text-dusty-denim-500">{scanStatus}</p>
          <div id="spiliby-qr-scanner" className="w-full rounded-2xl overflow-hidden bg-black" />
        </div>
      </Modal>

      <p className="text-center text-[11px] sm:text-xs leading-5 text-blue-slate-700 dark:text-eggshell-600 pt-4 px-2 font-medium">Spiliby · works offline first, with QR sharing when you need it.</p>
    </div>
  );
}

function SettingRow({ icon: Icon, label, onClick, toggle, value, onToggle, danger }) {
  return (
    <Card className="!p-3.5 flex items-center gap-3" onClick={toggle ? undefined : onClick}>
      <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${danger ? 'bg-red-500/10' : 'bg-dusty-denim-100 dark:bg-deep-space-blue-300'}`}>
        <Icon size={17} className={danger ? 'text-red-500' : 'text-blue-slate-600 dark:text-dusty-denim-600'} />
      </div>
      <span className={`flex-1 text-sm font-medium ${danger ? 'text-red-500' : 'text-ink-black-500 dark:text-eggshell-600'}`}>{label}</span>
      {toggle ? (
        <button onClick={onToggle} className={`w-11 h-6 rounded-full p-0.5 transition-colors ${value ? 'bg-blue-slate-500' : 'bg-dusty-denim-200 dark:bg-deep-space-blue-200'}`}>
          <div className={`w-5 h-5 rounded-full bg-white transition-transform ${value ? 'translate-x-5' : ''}`} />
        </button>
      ) : (
        <ChevronRight size={18} className="text-dusty-denim-400" />
      )}
    </Card>
  );
}
