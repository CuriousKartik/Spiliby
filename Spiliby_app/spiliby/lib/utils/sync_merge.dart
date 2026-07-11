import '../models/models.dart';
import 'ids.dart';

class BackupData {
  final Profile? profile;
  final List<Friend> friends;
  final List<Group> groups;
  final List<GroupMember> groupMembers;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final Map<String, dynamic>? settings;

  BackupData({
    this.profile,
    this.friends = const [],
    this.groups = const [],
    this.groupMembers = const [],
    this.expenses = const [],
    this.settlements = const [],
    this.settings,
  });

  Map<String, dynamic> toJson() => {
        'profile': profile == null ? [] : [profile!.toJson()],
        'friends': friends.map((f) => f.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'groupMembers': groupMembers.map((m) => m.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'settlements': settlements.map((s) => s.toJson()).toList(),
        'exportedAt': nowIso(),
      };

  factory BackupData.fromJson(Map<String, dynamic> j) {
    final profileList = (j['profile'] as List?) ?? [];
    return BackupData(
      profile: profileList.isNotEmpty ? Profile.fromJson(profileList.first) : null,
      friends: ((j['friends'] as List?) ?? []).map((e) => Friend.fromJson(e)).toList(),
      groups: ((j['groups'] as List?) ?? []).map((e) => Group.fromJson(e)).toList(),
      groupMembers: ((j['groupMembers'] as List?) ?? []).map((e) => GroupMember.fromJson(e)).toList(),
      expenses: ((j['expenses'] as List?) ?? []).map((e) => Expense.fromJson(e)).toList(),
      settlements: ((j['settlements'] as List?) ?? []).map((e) => Settlement.fromJson(e)).toList(),
      settings: (j['settings'] is Map) ? Map<String, dynamic>.from(j['settings']) : null,
    );
  }
}

bool _sameFriend(Friend a, Friend b) {
  if (a.btId.isNotEmpty && b.btId.isNotEmpty && a.btId == b.btId) return true;
  return a.name.trim().toLowerCase() == b.name.trim().toLowerCase();
}

bool _sameGroup(Group a, Group b) {
  if (a.id == b.id) return true;
  return a.name.trim().toLowerCase() == b.name.trim().toLowerCase();
}


BackupData mergeBackupData(BackupData local, BackupData incoming) {
  final mergedProfile = local.profile ?? incoming.profile;

  final friendIdMap = <String, String>{};
  final mergedFriends = <Friend>[];
  final seenFriends = <String>{};

  void addFriend(Friend f) {
    final key = f.btId.isNotEmpty ? f.btId : f.name.trim().toLowerCase();
    if (seenFriends.contains(key)) return;
    seenFriends.add(key);
    final normalized = Friend(
      id: f.id.isNotEmpty ? f.id : uid(),
      name: f.name,
      btId: f.btId,
      qrCode: f.qrCode,
      createdAt: f.createdAt,
    );
    mergedFriends.add(normalized);
    friendIdMap[f.id] = normalized.id;
  }

  for (final f in local.friends) {
    addFriend(f);
  }
  for (final f in incoming.friends) {
    Friend? existing;
    for (final entry in mergedFriends) {
      if (_sameFriend(entry, f)) {
        existing = entry;
        break;
      }
    }
    if (existing != null) {
      friendIdMap[f.id] = existing.id;
    } else {
      addFriend(f);
    }
  }

  final groupIdMap = <String, String>{};
  final mergedGroups = <Group>[];
  final seenGroups = <String>{};

  void addGroup(Group g) {
    final key = g.name.trim().toLowerCase();
    if (seenGroups.contains(key)) return;
    seenGroups.add(key);
    final normalized = Group(
      id: g.id.isNotEmpty ? g.id : uid(),
      name: g.name,
      icon: g.icon,
      status: g.status,
      completedAt: g.completedAt,
      createdAt: g.createdAt,
    );
    mergedGroups.add(normalized);
    groupIdMap[g.id] = normalized.id;
  }

  for (final g in local.groups) {
    addGroup(g);
  }
  for (final g in incoming.groups) {
    Group? existing;
    for (final entry in mergedGroups) {
      if (_sameGroup(entry, g)) {
        existing = entry;
        break;
      }
    }
    if (existing != null) {
      groupIdMap[g.id] = existing.id;
    } else {
      addGroup(g);
    }
  }

  String remapMember(String id) {
    if (id == 'me') return 'me';
    return friendIdMap[id] ?? id;
  }

  String remapGroup(String id) => groupIdMap[id] ?? id;

  final mergedGroupMembers = <GroupMember>[];
  final seenGroupMembers = <String>{};
  void addGroupMember(GroupMember m) {
    final groupId = remapGroup(m.groupId);
    final friendId = remapMember(m.friendId);
    final key = '$groupId:$friendId';
    if (seenGroupMembers.contains(key)) return;
    seenGroupMembers.add(key);
    mergedGroupMembers.add(GroupMember(id: m.id.isNotEmpty ? m.id : uid(), groupId: groupId, friendId: friendId));
  }

  for (final m in local.groupMembers) {
    addGroupMember(m);
  }
  for (final m in incoming.groupMembers) {
    addGroupMember(m);
  }

  final mergedExpenses = <Expense>[];
  final seenExpenses = <String>{};
  void addExpense(Expense e) {
    final groupId = remapGroup(e.groupId);
    final payerId = remapMember(e.payerId);
    final shares = {for (final entry in e.shares.entries) remapMember(entry.key): entry.value};
    final signature = '$groupId:${e.title}:${e.amount}:${e.date}:$payerId:${e.category}';
    if (seenExpenses.contains(signature)) return;
    seenExpenses.add(signature);
    mergedExpenses.add(Expense(
      id: e.id.isNotEmpty ? e.id : uid(),
      groupId: groupId,
      title: e.title,
      amount: e.amount,
      payerId: payerId,
      category: e.category,
      notes: e.notes,
      date: e.date,
      splitType: e.splitType,
      shares: shares,
      createdAt: e.createdAt,
    ));
  }

  for (final e in local.expenses) {
    addExpense(e);
  }
  for (final e in incoming.expenses) {
    addExpense(e);
  }

  final mergedSettlements = <Settlement>[];
  final seenSettlements = <String>{};
  void addSettlement(Settlement s) {
    final groupId = remapGroup(s.groupId);
    final fromId = remapMember(s.fromId);
    final toId = remapMember(s.toId);
    final signature = '$groupId:$fromId:$toId:${s.amount}:${s.status}';
    if (seenSettlements.contains(signature)) return;
    seenSettlements.add(signature);
    mergedSettlements.add(Settlement(
      id: s.id.isNotEmpty ? s.id : uid(),
      groupId: groupId,
      fromId: fromId,
      toId: toId,
      amount: s.amount,
      status: s.status,
      createdAt: s.createdAt,
    ));
  }

  for (final s in local.settlements) {
    addSettlement(s);
  }
  for (final s in incoming.settlements) {
    addSettlement(s);
  }

  return BackupData(
    profile: mergedProfile,
    friends: mergedFriends,
    groups: mergedGroups,
    groupMembers: mergedGroupMembers,
    expenses: mergedExpenses,
    settlements: mergedSettlements,
    settings: local.settings ?? incoming.settings,
  );
}