// Tiny UI sound-effect helper. Respects the same notificationsEnabled
// setting used by lib/notifications.js so users can mute everything at once.
import { db } from '../db/db';

const cache = {};
function getAudio(src) {
  if (!cache[src]) cache[src] = new Audio(src);
  return cache[src];
}

async function soundsEnabled() {
  try {
    const settings = await db.settings.get('app');
    return settings?.notificationsEnabled ?? true;
  } catch {
    return true;
  }
}

async function play(src) {
  try {
    if (!(await soundsEnabled())) return;
    const audio = getAudio(src);
    audio.currentTime = 0;
    audio.play().catch(() => {});
  } catch {
    /* asset missing or autoplay blocked — safe to ignore */
  }
}

export const playClick = () => play('/assets/sounds/click.mp3');
export const playSuccess = () => play('/assets/sounds/success.mp3');
