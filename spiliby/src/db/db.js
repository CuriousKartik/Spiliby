import Dexie from 'dexie';

// Local-first database. Everything lives on-device, no server involved.
export const db = new Dexie('spiliby');

db.version(1).stores({
  profile: 'id',
  friends: 'id, name, btId',
  groups: 'id, name, createdAt',
  groupMembers: 'id, groupId, friendId',
  expenses: 'id, groupId, date, category, payerId',
  settlements: 'id, groupId, fromId, toId, status, createdAt',
  notifications: 'id, createdAt, read',
  settings: 'id',
});

export const CATEGORIES = [
  'Cab', 'Food', 'Hotel', 'Tickets', 'Misc',
  'Cafe', 'Travel', 'Shopping', 'Hostel',
  'Entertainment', 'Books', 'Party', 'Miscellaneous',
];

// Quick-select chips shown first in the expense form.
export const QUICK_CATEGORIES = ['Cab', 'Food', 'Hotel', 'Tickets', 'Misc'];

export const uid = () => crypto.randomUUID();

export default db;
