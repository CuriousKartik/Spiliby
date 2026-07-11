import { create } from 'zustand';
import { db, uid } from '../db/db';
import { computeBalances, minimizeTransactions } from '../lib/settlement';
import { notifyExpenseAdded, notifySettlementPending } from '../lib/notifications';
import { mergeBackupData } from '../lib/sync';

const useStore = create((set, get) => ({
  profile: null,
  friends: [],
  groups: [],
  groupMembers: [],
  expenses: [],
  settlements: [],
  theme: 'light',
  ready: false,

  init: async () => {
    const [profile, friends, groups, groupMembers, expenses, settlements, settings] = await Promise.all([
      db.profile.get('me'),
      db.friends.toArray(),
      db.groups.toArray(),
      db.groupMembers.toArray(),
      db.expenses.toArray(),
      db.settlements.toArray(),
      db.settings.get('app'),
    ]);
    const theme = settings?.theme || 'light';
    document.documentElement.classList.toggle('dark', theme === 'dark');
    set({ profile: profile || null, friends, groups, groupMembers, expenses, settlements, theme, ready: true });
  },

  createProfile: async ({ name, btId }) => {
    const profile = { id: 'me', name, btId, createdAt: new Date().toISOString() };
    await db.profile.put(profile);
    await db.settings.put({ id: 'app', theme: 'light', notificationsEnabled: true });
    set({ profile });
  },

  updateProfile: async (patch) => {
    const profile = { ...get().profile, ...patch };
    await db.profile.put(profile);
    set({ profile });
  },

  toggleTheme: async () => {
    const theme = get().theme === 'dark' ? 'light' : 'dark';
    document.documentElement.classList.toggle('dark', theme === 'dark');
    const settings = (await db.settings.get('app')) || { id: 'app' };
    await db.settings.put({ ...settings, theme });
    set({ theme });
  },

  addFriend: async ({ name, btId, qrCode }) => {
    const friend = { id: uid(), name, btId, qrCode: qrCode || null, createdAt: new Date().toISOString() };
    await db.friends.add(friend);
    set({ friends: [...get().friends, friend] });
    return friend;
  },

  updateFriendQr: async (id, qrCode) => {
    const friend = get().friends.find((f) => f.id === id);
    if (!friend) return;
    const updated = { ...friend, qrCode };
    await db.friends.put(updated);
    set({ friends: get().friends.map((f) => (f.id === id ? updated : f)) });
  },

  removeFriend: async (id) => {
    await db.friends.delete(id);
    set({ friends: get().friends.filter((f) => f.id !== id) });
  },

  createGroup: async ({ name, icon, memberIds }) => {
    const group = { id: uid(), name, icon: icon || '👥', status: 'active', completedAt: null, createdAt: new Date().toISOString() };
    await db.groups.add(group);
    const members = memberIds.map((friendId) => ({ id: uid(), groupId: group.id, friendId }));
    await db.groupMembers.bulkAdd(members);
    set({ groups: [...get().groups, group], groupMembers: [...get().groupMembers, ...members] });
    return group;
  },

  completeGroup: async (groupId) => {
    const group = get().groups.find((g) => g.id === groupId);
    if (!group) return;
    const updated = { ...group, status: 'completed', completedAt: new Date().toISOString() };
    await db.groups.put(updated);
    set({ groups: get().groups.map((g) => (g.id === groupId ? updated : g)) });
  },

  reopenGroup: async (groupId) => {
    const group = get().groups.find((g) => g.id === groupId);
    if (!group) return;
    const updated = { ...group, status: 'active', completedAt: null };
    await db.groups.put(updated);
    set({ groups: get().groups.map((g) => (g.id === groupId ? updated : g)) });
  },

  deleteGroup: async (groupId) => {
    await db.groups.delete(groupId);
    await db.groupMembers.where('groupId').equals(groupId).delete();
    await db.expenses.where('groupId').equals(groupId).delete();
    await db.settlements.where('groupId').equals(groupId).delete();
    set({
      groups: get().groups.filter((g) => g.id !== groupId),
      groupMembers: get().groupMembers.filter((m) => m.groupId !== groupId),
      expenses: get().expenses.filter((e) => e.groupId !== groupId),
      settlements: get().settlements.filter((s) => s.groupId !== groupId),
    });
  },

  addExpense: async (expense) => {
    const record = { id: uid(), createdAt: new Date().toISOString(), ...expense };
    await db.expenses.add(record);
    set({ expenses: [...get().expenses, record] });
    notifyExpenseAdded(record.title, record.amount);
    return record;
  },

  updateExpense: async (id, patch) => {
    const existing = get().expenses.find((e) => e.id === id);
    if (!existing) return;
    const updated = { ...existing, ...patch };
    await db.expenses.put(updated);
    set({ expenses: get().expenses.map((e) => (e.id === id ? updated : e)) });
    return updated;
  },

  deleteExpense: async (id) => {
    await db.expenses.delete(id);
    set({ expenses: get().expenses.filter((e) => e.id !== id) });
  },

  // Balances + minimal transactions for a group ("me" is included as a member id)
  getGroupSettlement: (groupId) => {
    const { expenses, groupMembers, settlements } = get();
    const memberIds = ['me', ...groupMembers.filter((m) => m.groupId === groupId).map((m) => m.friendId)];
    const groupExpenses = expenses.filter((e) => e.groupId === groupId);
    const paidIds = new Set(
      settlements.filter((s) => s.groupId === groupId && s.status === 'paid').map((s) => `${s.fromId}->${s.toId}`)
    );
    const balances = computeBalances(groupExpenses, memberIds);
    const transactions = minimizeTransactions(balances).filter(
      (t) => !paidIds.has(`${t.fromId}->${t.toId}`)
    );
    return { balances, transactions };
  },

  markSettled: async (groupId, fromId, toId, amount) => {
    const record = { id: uid(), groupId, fromId, toId, amount, status: 'paid', createdAt: new Date().toISOString() };
    await db.settlements.add(record);
    set({ settlements: [...get().settlements, record] });
    notifySettlementPending('friend', amount);
  },

  unmarkSettled: async (groupId, fromId, toId) => {
    const rec = get().settlements.find(
      (s) => s.groupId === groupId && s.fromId === fromId && s.toId === toId && s.status === 'paid'
    );
    if (!rec) return;
    await db.settlements.delete(rec.id);
    set({ settlements: get().settlements.filter((s) => s.id !== rec.id) });
  },

  exportData: async () => {
    const [profile, friends, groups, groupMembers, expenses, settlements] = await Promise.all([
      db.profile.toArray(),
      db.friends.toArray(),
      db.groups.toArray(),
      db.groupMembers.toArray(),
      db.expenses.toArray(),
      db.settlements.toArray(),
    ]);
    return { profile, friends, groups, groupMembers, expenses, settlements, exportedAt: new Date().toISOString() };
  },

  importData: async (data) => {
    const existing = await Promise.all([
      db.profile.toArray(),
      db.friends.toArray(),
      db.groups.toArray(),
      db.groupMembers.toArray(),
      db.expenses.toArray(),
      db.settlements.toArray(),
      db.settings.toArray(),
    ]);
    const merged = mergeBackupData(
      {
        profile: existing[0],
        friends: existing[1],
        groups: existing[2],
        groupMembers: existing[3],
        expenses: existing[4],
        settlements: existing[5],
        settings: existing[6],
      },
      data
    );

    await db.transaction('rw', db.profile, db.friends, db.groups, db.groupMembers, db.expenses, db.settlements, db.settings, async () => {
      if (merged.profile?.length) await db.profile.clear();
      if (merged.friends?.length) await db.friends.clear();
      if (merged.groups?.length) await db.groups.clear();
      if (merged.groupMembers?.length) await db.groupMembers.clear();
      if (merged.expenses?.length) await db.expenses.clear();
      if (merged.settlements?.length) await db.settlements.clear();
      if (merged.settings?.length) await db.settings.clear();

      if (merged.profile?.length) await db.profile.bulkPut(merged.profile);
      if (merged.friends?.length) await db.friends.bulkPut(merged.friends);
      if (merged.groups?.length) await db.groups.bulkPut(merged.groups);
      if (merged.groupMembers?.length) await db.groupMembers.bulkPut(merged.groupMembers);
      if (merged.expenses?.length) await db.expenses.bulkPut(merged.expenses);
      if (merged.settlements?.length) await db.settlements.bulkPut(merged.settlements);
      if (merged.settings?.length) await db.settings.bulkPut(merged.settings);
    });
    await get().init();
  },

  clearAllData: async () => {
    await db.transaction('rw', db.profile, db.friends, db.groups, db.groupMembers, db.expenses, db.settlements, db.notifications, db.settings, async () => {
      await Promise.all([
        db.profile.clear(), db.friends.clear(), db.groups.clear(), db.groupMembers.clear(),
        db.expenses.clear(), db.settlements.clear(), db.notifications.clear(), db.settings.clear(),
      ]);
    });
    set({ profile: null, friends: [], groups: [], groupMembers: [], expenses: [], settlements: [], theme: 'light' });
  },
}));

export default useStore;
