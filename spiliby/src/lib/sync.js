import { uid } from '../db/db';

const asArray = (value) => Array.isArray(value) ? value : [];

const sameFriend = (left, right) => {
  if (!left || !right) return false;
  if (left.btId && right.btId && left.btId === right.btId) return true;
  return !!(left.name && right.name && left.name.trim().toLowerCase() === right.name.trim().toLowerCase());
};

const sameGroup = (left, right) => {
  if (!left || !right) return false;
  if (left.id && right.id && left.id === right.id) return true;
  return !!(left.name && right.name && left.name.trim().toLowerCase() === right.name.trim().toLowerCase());
};

export function mergeBackupData(localData = {}, incomingData = {}) {
  const local = {
    profile: asArray(localData.profile),
    friends: asArray(localData.friends),
    groups: asArray(localData.groups),
    groupMembers: asArray(localData.groupMembers),
    expenses: asArray(localData.expenses),
    settlements: asArray(localData.settlements),
    settings: asArray(localData.settings),
  };
  const incoming = {
    profile: asArray(incomingData.profile),
    friends: asArray(incomingData.friends),
    groups: asArray(incomingData.groups),
    groupMembers: asArray(incomingData.groupMembers),
    expenses: asArray(incomingData.expenses),
    settlements: asArray(incomingData.settlements),
    settings: asArray(incomingData.settings),
  };

  const mergedProfile = local.profile.length ? [...local.profile] : (incoming.profile.length ? [...incoming.profile] : []);

  const friendIdMap = new Map();
  const mergedFriends = [];
  const seenFriends = new Set();

  const addFriend = (friend) => {
    if (!friend || !friend.name) return null;
    const key = friend.btId || friend.name.trim().toLowerCase();
    if (seenFriends.has(key)) return null;
    seenFriends.add(key);
    const normalized = { ...friend, id: friend.id || uid() };
    mergedFriends.push(normalized);
    if (friend.id) friendIdMap.set(friend.id, normalized.id);
    else friendIdMap.set(key, normalized.id);
    return normalized;
  };

  local.friends.forEach((friend) => addFriend(friend));
  incoming.friends.forEach((friend) => {
    const existing = mergedFriends.find((entry) => sameFriend(entry, friend));
    if (existing) {
      friendIdMap.set(friend.id, existing.id);
      return;
    }
    addFriend(friend);
  });

  const groupIdMap = new Map();
  const mergedGroups = [];
  const seenGroups = new Set();

  const addGroup = (group) => {
    if (!group || !group.name) return null;
    const key = group.name.trim().toLowerCase();
    if (seenGroups.has(key)) return null;
    seenGroups.add(key);
    const normalized = { ...group, id: group.id || uid() };
    mergedGroups.push(normalized);
    if (group.id) groupIdMap.set(group.id, normalized.id);
    return normalized;
  };

  local.groups.forEach((group) => addGroup(group));
  incoming.groups.forEach((group) => {
    const existing = mergedGroups.find((entry) => sameGroup(entry, group));
    if (existing) {
      groupIdMap.set(group.id, existing.id);
      return;
    }
    addGroup(group);
  });

  const remapMemberId = (memberId) => {
    if (!memberId || memberId === 'me') return 'me';
    if (friendIdMap.has(memberId)) return friendIdMap.get(memberId);
    return memberId;
  };

  const remapGroupId = (groupId) => {
    if (!groupId) return groupId;
    if (groupIdMap.has(groupId)) return groupIdMap.get(groupId);
    return groupId;
  };

  const mergedGroupMembers = [];
  const seenGroupMembers = new Set();
  const addGroupMember = (record) => {
    if (!record) return;
    const groupId = remapGroupId(record.groupId);
    const friendId = remapMemberId(record.friendId);
    if (!groupId || !friendId) return;
    const key = `${groupId}:${friendId}`;
    if (seenGroupMembers.has(key)) return;
    seenGroupMembers.add(key);
    mergedGroupMembers.push({ ...record, id: record.id || uid(), groupId, friendId });
  };

  local.groupMembers.forEach(addGroupMember);
  incoming.groupMembers.forEach(addGroupMember);

  const mergedExpenses = [];
  const seenExpenses = new Set();
  const addExpense = (record) => {
    if (!record) return;
    const groupId = remapGroupId(record.groupId);
    const payerId = remapMemberId(record.payerId);
    const shares = Object.fromEntries(
      Object.entries(record.shares || {}).map(([memberId, value]) => [remapMemberId(memberId), value])
    );
    const signature = `${groupId}:${record.title || ''}:${record.amount || 0}:${record.date || ''}:${payerId}:${record.category || ''}`;
    if (!groupId || seenExpenses.has(signature)) return;
    seenExpenses.add(signature);
    mergedExpenses.push({ ...record, id: record.id || uid(), groupId, payerId, shares });
  };

  local.expenses.forEach(addExpense);
  incoming.expenses.forEach(addExpense);

  const mergedSettlements = [];
  const seenSettlements = new Set();
  const addSettlement = (record) => {
    if (!record) return;
    const groupId = remapGroupId(record.groupId);
    const fromId = remapMemberId(record.fromId);
    const toId = remapMemberId(record.toId);
    const signature = `${groupId}:${fromId}:${toId}:${record.amount || 0}:${record.status || ''}`;
    if (!groupId || !fromId || !toId || seenSettlements.has(signature)) return;
    seenSettlements.add(signature);
    mergedSettlements.push({ ...record, id: record.id || uid(), groupId, fromId, toId });
  };

  local.settlements.forEach(addSettlement);
  incoming.settlements.forEach(addSettlement);

  const mergedSettings = local.settings.length ? [...local.settings] : [...incoming.settings];

  return {
    profile: mergedProfile,
    friends: mergedFriends,
    groups: mergedGroups,
    groupMembers: mergedGroupMembers,
    expenses: mergedExpenses,
    settlements: mergedSettlements,
    settings: mergedSettings,
  };
}
