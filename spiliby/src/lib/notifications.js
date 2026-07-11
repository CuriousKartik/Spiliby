// Local notification layer. Runs entirely in the browser today via the
// Notifications API + an in-app bell. When this ships as an Android APK
// (via Bubblewrap) this module is the single seam to swap in native
// Android notifications — nothing outside this file should need to change.
import { db, uid } from '../db/db';

// TODO(native-android): replace this with the default system notification
// sound, or let the OS-level channel own the sound entirely.
const NOTIFICATION_SOUND_URL = '/assets/sounds/notification.mp3';

let audio;
function playSound() {
  try {
    audio = audio || new Audio(NOTIFICATION_SOUND_URL);
    audio.currentTime = 0;
    audio.play().catch(() => {});
  } catch {
    /* sound asset not present yet — safe to ignore */
  }
}

export async function requestPermission() {
  if (!('Notification' in window)) return 'unsupported';
  if (Notification.permission === 'default') {
    return Notification.requestPermission();
  }
  return Notification.permission;
}

export async function notify(title, body, { sound = true } = {}) {
  await db.notifications.add({ id: uid(), title, body, createdAt: new Date().toISOString(), read: false });

  const settings = await db.settings.get('app');
  const enabled = settings?.notificationsEnabled ?? true;
  if (!enabled) return;

  if (sound) playSound();

  // TODO(native-android): swap browser Notification for a native call.
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, { body, icon: '/pwa-192.png' });
  }
}

export const notifyExpenseAdded = (title, amount) =>
  notify('Expense added', `${title} was added to your group.`);

export const notifySettlementPending = (name, amount) =>
  notify('Payment pending', `You owe ${name}. Settle up when you can.`);

export const notifyBudgetReminder = (message) =>
  notify('Budget reminder', message);
