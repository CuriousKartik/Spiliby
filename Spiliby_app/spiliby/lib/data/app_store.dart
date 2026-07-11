import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../../utils/ids.dart';
import '../../utils/settlement.dart';
import '../../utils/sync_merge.dart';
import '../local_db.dart';

class GroupSettlement {
  final Map<String, double> balances;
  final List<Transaction> transactions;
  const GroupSettlement({required this.balances, required this.transactions});
}

class AppStore extends ChangeNotifier {
  Profile? profile;
  List<Friend> friends = [];
  List<Group> groups = [];
  List<GroupMember> groupMembers = [];
  List<Expense> expenses = [];
  List<Settlement> settlements = [];
  String theme = 'light';
  bool notificationsEnabled = true;
  bool ready = false;

  bool get isDark => theme == 'dark';

  Future<void> init() async {
    final profileJson = await LocalDb.getProfile();
    final friendsJson = await LocalDb.getFriends();
    final groupsJson = await LocalDb.getGroups();
    final groupMembersJson = await LocalDb.getGroupMembers();
    final expensesJson = await LocalDb.getExpenses();
    final settlementsJson = await LocalDb.getSettlements();
    final settings = await LocalDb.getSettings();

    profile = profileJson != null ? Profile.fromJson(profileJson) : null;
    friends = friendsJson.map((e) => Friend.fromJson(e)).toList();
    groups = groupsJson.map((e) => Group.fromJson(e)).toList();
    groupMembers = groupMembersJson.map((e) => GroupMember.fromJson(e)).toList();
    expenses = expensesJson.map((e) => Expense.fromJson(e)).toList();
    settlements = settlementsJson.map((e) => Settlement.fromJson(e)).toList();
    theme = settings['theme'] ?? 'light';
    notificationsEnabled = settings['notificationsEnabled'] ?? true;
    ready = true;
    notifyListeners();
  }

  Future<void> createProfile({required String name, required String btId}) async {
    profile = Profile(id: 'me', name: name, btId: btId, createdAt: nowIso());
    await LocalDb.setProfile(profile!.toJson());
    await LocalDb.setSettings({'id': 'app', 'theme': 'light', 'notificationsEnabled': true});
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? btId, String? qrCode, bool clearQr = false}) async {
    if (profile == null) return;
    profile = profile!.copyWith(name: name, btId: btId, qrCode: clearQr ? null : qrCode);
    await LocalDb.setProfile(profile!.toJson());
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    theme = theme == 'dark' ? 'light' : 'dark';
    final settings = await LocalDb.getSettings();
    settings['theme'] = theme;
    await LocalDb.setSettings(settings);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    final settings = await LocalDb.getSettings();
    settings['notificationsEnabled'] = value;
    await LocalDb.setSettings(settings);
    notifyListeners();
  }

  Future<Friend> addFriend({required String name, required String btId, String? qrCode}) async {
    final friend = Friend(id: uid(), name: name, btId: btId, qrCode: qrCode, createdAt: nowIso());
    friends = [...friends, friend];
    await LocalDb.setFriends(friends.map((f) => f.toJson()).toList());
    notifyListeners();
    return friend;
  }

  Future<void> updateFriendQr(String id, String? qrCode) async {
    friends = friends.map((f) => f.id == id ? f.copyWith(qrCode: qrCode) : f).toList();
    await LocalDb.setFriends(friends.map((f) => f.toJson()).toList());
    notifyListeners();
  }

  Future<void> removeFriend(String id) async {
    friends = friends.where((f) => f.id != id).toList();
    await LocalDb.setFriends(friends.map((f) => f.toJson()).toList());
    notifyListeners();
  }

  Future<Group> createGroup({required String name, String icon = '👥', required List<String> memberIds}) async {
    final group = Group(id: uid(), name: name, icon: icon, status: 'active', createdAt: nowIso());
    final members = memberIds.map((friendId) => GroupMember(id: uid(), groupId: group.id, friendId: friendId)).toList();
    groups = [...groups, group];
    groupMembers = [...groupMembers, ...members];
    await LocalDb.setGroups(groups.map((g) => g.toJson()).toList());
    await LocalDb.setGroupMembers(groupMembers.map((m) => m.toJson()).toList());
    notifyListeners();
    return group;
  }

  Future<void> completeGroup(String groupId) async {
    groups = groups.map((g) => g.id == groupId ? g.copyWith(status: 'completed', completedAt: nowIso()) : g).toList();
    await LocalDb.setGroups(groups.map((g) => g.toJson()).toList());
    notifyListeners();
  }

  Future<void> reopenGroup(String groupId) async {
    groups = groups
        .map((g) => g.id == groupId ? g.copyWith(status: 'active', clearCompletedAt: true) : g)
        .toList();
    await LocalDb.setGroups(groups.map((g) => g.toJson()).toList());
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    groups = groups.where((g) => g.id != groupId).toList();
    groupMembers = groupMembers.where((m) => m.groupId != groupId).toList();
    expenses = expenses.where((e) => e.groupId != groupId).toList();
    settlements = settlements.where((s) => s.groupId != groupId).toList();
    await LocalDb.setGroups(groups.map((g) => g.toJson()).toList());
    await LocalDb.setGroupMembers(groupMembers.map((m) => m.toJson()).toList());
    await LocalDb.setExpenses(expenses.map((e) => e.toJson()).toList());
    await LocalDb.setSettlements(settlements.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  Future<Expense> addExpense(Expense expense) async {
    final record = Expense(
      id: uid(),
      groupId: expense.groupId,
      title: expense.title,
      amount: expense.amount,
      payerId: expense.payerId,
      category: expense.category,
      notes: expense.notes,
      date: expense.date,
      splitType: expense.splitType,
      shares: expense.shares,
      createdAt: nowIso(),
    );
    expenses = [...expenses, record];
    await LocalDb.setExpenses(expenses.map((e) => e.toJson()).toList());
    notifyListeners();
    return record;
  }

  Future<void> updateExpense(String id, Expense patch) async {
    expenses = expenses.map((e) => e.id == id ? patch : e).toList();
    await LocalDb.setExpenses(expenses.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    expenses = expenses.where((e) => e.id != id).toList();
    await LocalDb.setExpenses(expenses.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  /// Balances + minimal transactions for a group ("me" is included as a member id)
  GroupSettlement getGroupSettlement(String groupId) {
    final memberIds = ['me', ...groupMembers.where((m) => m.groupId == groupId).map((m) => m.friendId)];
    final groupExpenses = expenses.where((e) => e.groupId == groupId).toList();
    final paidIds = settlements
        .where((s) => s.groupId == groupId && s.status == 'paid')
        .map((s) => '${s.fromId}->${s.toId}')
        .toSet();
    final balances = computeBalances(groupExpenses, memberIds);
    final transactions =
        minimizeTransactions(balances).where((t) => !paidIds.contains('${t.fromId}->${t.toId}')).toList();
    return GroupSettlement(balances: balances, transactions: transactions);
  }

  Future<void> markSettled(String groupId, String fromId, String toId, double amount) async {
    final record = Settlement(id: uid(), groupId: groupId, fromId: fromId, toId: toId, amount: amount, status: 'paid', createdAt: nowIso());
    settlements = [...settlements, record];
    await LocalDb.setSettlements(settlements.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  Future<void> unmarkSettled(String groupId, String fromId, String toId) async {
    Settlement? rec;
    for (final s in settlements) {
      if (s.groupId == groupId && s.fromId == fromId && s.toId == toId && s.status == 'paid') {
        rec = s;
        break;
      }
    }
    if (rec == null) return;
    settlements = settlements.where((s) => s.id != rec!.id).toList();
    await LocalDb.setSettlements(settlements.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  BackupData exportData() {
    return BackupData(
      profile: profile,
      friends: friends,
      groups: groups,
      groupMembers: groupMembers,
      expenses: expenses,
      settlements: settlements,
    );
  }

  Future<void> importData(BackupData incoming) async {
    final local = BackupData(
      profile: profile,
      friends: friends,
      groups: groups,
      groupMembers: groupMembers,
      expenses: expenses,
      settlements: settlements,
    );
    final merged = mergeBackupData(local, incoming);

    profile = merged.profile;
    friends = merged.friends;
    groups = merged.groups;
    groupMembers = merged.groupMembers;
    expenses = merged.expenses;
    settlements = merged.settlements;

    await LocalDb.setProfile(profile?.toJson());
    await LocalDb.setFriends(friends.map((f) => f.toJson()).toList());
    await LocalDb.setGroups(groups.map((g) => g.toJson()).toList());
    await LocalDb.setGroupMembers(groupMembers.map((m) => m.toJson()).toList());
    await LocalDb.setExpenses(expenses.map((e) => e.toJson()).toList());
    await LocalDb.setSettlements(settlements.map((s) => s.toJson()).toList());
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await LocalDb.clearAll();
    profile = null;
    friends = [];
    groups = [];
    groupMembers = [];
    expenses = [];
    settlements = [];
    theme = 'light';
    notifyListeners();
  }
}