
const List<String> kQuickCategories = ['Cab', 'Food', 'Hotel', 'Tickets', 'Misc'];


const List<String> kCategories = [
  'Cab', 'Food', 'Hotel', 'Tickets', 'Misc',
  'Cafe', 'Travel', 'Shopping', 'Hostel',
  'Entertainment', 'Books', 'Party', 'Miscellaneous',
];

const List<String> kSplitTypes = ['Equal', 'Percentage', 'Custom', 'Exclude'];

const List<String> kGroupPresets = [
  ' Hostel Room',
  ' Goa Trip',
  ' Birthday Party',
  ' Cafe Bills',
  ' Class Picnic',
];

class Profile {
  final String id;
  final String name;
  final String btId;
  final String? qrCode; // base64 data-url string
  final String createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.btId,
    this.qrCode,
    required this.createdAt,
  });

  Profile copyWith({String? name, String? btId, String? qrCode}) => Profile(
        id: id,
        name: name ?? this.name,
        btId: btId ?? this.btId,
        qrCode: qrCode ?? this.qrCode,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'btId': btId,
        'qrCode': qrCode,
        'createdAt': createdAt,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] ?? 'me',
        name: j['name'] ?? '',
        btId: j['btId'] ?? '',
        qrCode: j['qrCode'],
        createdAt: j['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

class Friend {
  final String id;
  final String name;
  final String btId;
  final String? qrCode;
  final String createdAt;

  Friend({
    required this.id,
    required this.name,
    required this.btId,
    this.qrCode,
    required this.createdAt,
  });

  Friend copyWith({String? name, String? btId, String? qrCode}) => Friend(
        id: id,
        name: name ?? this.name,
        btId: btId ?? this.btId,
        qrCode: qrCode ?? this.qrCode,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'btId': btId,
        'qrCode': qrCode,
        'createdAt': createdAt,
      };

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        id: j['id'],
        name: j['name'] ?? '',
        btId: j['btId'] ?? '',
        qrCode: j['qrCode'],
        createdAt: j['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

class Group {
  final String id;
  final String name;
  final String icon;
  final String status; // 'active' | 'completed'
  final String? completedAt;
  final String createdAt;

  Group({
    required this.id,
    required this.name,
    this.icon = '👥',
    this.status = 'active',
    this.completedAt,
    required this.createdAt,
  });

  Group copyWith({String? status, String? completedAt, bool clearCompletedAt = false}) => Group(
        id: id,
        name: name,
        icon: icon,
        status: status ?? this.status,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'status': status,
        'completedAt': completedAt,
        'createdAt': createdAt,
      };

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id: j['id'],
        name: j['name'] ?? '',
        icon: j['icon'] ?? '👥',
        status: j['status'] ?? 'active',
        completedAt: j['completedAt'],
        createdAt: j['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

class GroupMember {
  final String id;
  final String groupId;
  final String friendId;

  GroupMember({required this.id, required this.groupId, required this.friendId});

  Map<String, dynamic> toJson() => {'id': id, 'groupId': groupId, 'friendId': friendId};

  factory GroupMember.fromJson(Map<String, dynamic> j) =>
      GroupMember(id: j['id'], groupId: j['groupId'], friendId: j['friendId']);
}

class Expense {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String payerId;
  final String category;
  final String notes;
  final String date; // yyyy-MM-dd
  final String splitType;
  final Map<String, double> shares;
  final String createdAt;

  Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.payerId,
    required this.category,
    this.notes = '',
    required this.date,
    required this.splitType,
    required this.shares,
    required this.createdAt,
  });

  Expense copyWith({
    String? title,
    double? amount,
    String? payerId,
    String? category,
    String? notes,
    String? date,
    String? splitType,
    Map<String, double>? shares,
  }) =>
      Expense(
        id: id,
        groupId: groupId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        payerId: payerId ?? this.payerId,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        splitType: splitType ?? this.splitType,
        shares: shares ?? this.shares,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'title': title,
        'amount': amount,
        'payerId': payerId,
        'category': category,
        'notes': notes,
        'date': date,
        'splitType': splitType,
        'shares': shares,
        'createdAt': createdAt,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'],
        groupId: j['groupId'],
        title: j['title'] ?? '',
        amount: (j['amount'] ?? 0).toDouble(),
        payerId: j['payerId'] ?? 'me',
        category: j['category'] ?? 'Misc',
        notes: j['notes'] ?? '',
        date: j['date'] ?? DateTime.now().toIso8601String().substring(0, 10),
        splitType: j['splitType'] ?? 'Equal',
        shares: Map<String, double>.from(
          (j['shares'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        ),
        createdAt: j['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

class Settlement {
  final String id;
  final String groupId;
  final String fromId;
  final String toId;
  final double amount;
  final String status; // 'paid'
  final String createdAt;

  Settlement({
    required this.id,
    required this.groupId,
    required this.fromId,
    required this.toId,
    required this.amount,
    this.status = 'paid',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'fromId': fromId,
        'toId': toId,
        'amount': amount,
        'status': status,
        'createdAt': createdAt,
      };

  factory Settlement.fromJson(Map<String, dynamic> j) => Settlement(
        id: j['id'],
        groupId: j['groupId'],
        fromId: j['fromId'],
        toId: j['toId'],
        amount: (j['amount'] ?? 0).toDouble(),
        status: j['status'] ?? 'paid',
        createdAt: j['createdAt'] ?? DateTime.now().toIso8601String(),
      );
}

/// A resolved member for display purposes: { id, name, qrCode }
/// Mirrors the `members` array built in GroupDetails.jsx.
class Member {
  final String id;
  final String name;
  final String? qrCode;
  const Member({required this.id, required this.name, this.qrCode});
}

class Transaction {
  final String fromId;
  final String toId;
  final double amount;
  const Transaction({required this.fromId, required this.toId, required this.amount});
}