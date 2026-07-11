import Modal from './Modal';
import { QrCode } from 'lucide-react';

export default function QrModal({ open, onClose, name, qrCode }) {
  return (
    <Modal open={open} onClose={onClose} title={`Pay ${name || ''}`}>
      {qrCode ? (
        <div className="flex flex-col items-center">
          <div className="rounded-3xl bg-white p-3 border border-dusty-denim-100">
            <img src={qrCode} alt={`${name}'s payment QR`} className="w-64 h-64 object-contain rounded-2xl" />
          </div>
          <p className="text-xs text-dusty-denim-500 mt-4 text-center">Scan this code in any UPI app to pay {name}.</p>
        </div>
      ) : (
        <div className="flex flex-col items-center py-8">
          <div className="w-16 h-16 rounded-2xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 flex items-center justify-center mb-3">
            <QrCode size={28} className="text-blue-slate-500 dark:text-dusty-denim-500" />
          </div>
          <p className="text-sm text-dusty-denim-500 text-center">{name} hasn't uploaded a payment QR yet.</p>
        </div>
      )}
    </Modal>
  );
}
