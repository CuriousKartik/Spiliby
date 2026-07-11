import { InviteService } from './InviteService';

export const SyncManager = {
  status: 'idle',
  lastError: null,

  generateQrForBackup: async (data) => {
    try {
      const qrDataUrl = await InviteService.generateInviteQr(data);
      SyncManager.status = 'ready';
      SyncManager.lastError = null;
      return qrDataUrl;
    } catch (error) {
      SyncManager.status = 'error';
      SyncManager.lastError = error instanceof Error ? error.message : 'Unable to generate QR backup.';
      throw error;
    }
  },

  importFromQrImage: async (imageDataUrl) => {
    try {
      const payload = await InviteService.redeemInviteQr(imageDataUrl);
      const data = JSON.parse(payload);
      SyncManager.status = 'ready';
      SyncManager.lastError = null;
      return data;
    } catch (error) {
      SyncManager.status = 'error';
      SyncManager.lastError = error instanceof Error ? error.message : 'Unable to read QR backup.';
      throw error;
    }
  },

  syncNow: async () => {
    return { status: SyncManager.status, lastError: SyncManager.lastError };
  },
};
