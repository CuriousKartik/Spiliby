import '../models/models.dart';

Map<String, double> computeBalances(List<Expense> expenses, List<String> memberIds) {
  final balances = {for (final id in memberIds) id: 0.0};

  for (final exp in expenses) {
    balances[exp.payerId] = (balances[exp.payerId] ?? 0) + exp.amount;
    for (final entry in exp.shares.entries) {
      balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
    }
  }

  for (final id in balances.keys.toList()) {
    balances[id] = (balances[id]! * 100).round() / 100;
  }
  return balances;
}

/// Minimises the number of payments required to settle everyone up using a
/// greedy max-debtor / max-creditor match.
List<Transaction> minimizeTransactions(Map<String, double> balances) {
  final creditors = <MapEntry<String, double>>[];
  final debtors = <MapEntry<String, double>>[];

  balances.forEach((id, amt) {
    if (amt > 0.005) {
      creditors.add(MapEntry(id, amt));
    } else if (amt < -0.005) {
      debtors.add(MapEntry(id, -amt));
    }
  });

  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => b.value.compareTo(a.value));

  final creditAmt = [for (final c in creditors) c.value];
  final debtAmt = [for (final d in debtors) d.value];

  final transactions = <Transaction>[];
  int i = 0, j = 0;

  while (i < debtors.length && j < creditors.length) {
    final amount = debtAmt[i] < creditAmt[j] ? debtAmt[i] : creditAmt[j];

    if (amount > 0.005) {
      transactions.add(Transaction(
        fromId: debtors[i].key,
        toId: creditors[j].key,
        amount: (amount * 100).round() / 100,
      ));
    }

    debtAmt[i] -= amount;
    creditAmt[j] -= amount;

    if (debtAmt[i] <= 0.005) i++;
    if (creditAmt[j] <= 0.005) j++;
  }

  return transactions;
}

Map<String, double> splitEqually(double amount, List<String> memberIds, List<String> excludedIds) {
  final included = memberIds.where((id) => !excludedIds.contains(id)).toList();
  final share = included.isNotEmpty ? amount / included.length : 0.0;
  final rounded = (share * 100).round() / 100;
  return {for (final id in included) id: rounded};
}

Map<String, double> splitByPercentage(double amount, Map<String, double> percentages) {
  final shares = <String, double>{};
  percentages.forEach((id, pct) {
    shares[id] = ((amount * pct) / 100 * 100).round() / 100;
  });
  return shares;
}