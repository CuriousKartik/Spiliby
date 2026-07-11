// Smart Settlement Engine
// Given a list of expenses (with shares per member) for a group, computes
// net balances per member, then minimizes the number of payments required
// to settle everyone up using a greedy max-debtor / max-creditor match.

export function computeBalances(expenses, memberIds) {
  const balances = Object.fromEntries(memberIds.map((id) => [id, 0]));

  for (const exp of expenses) {
    // exp.payerId paid exp.amount; exp.shares = { memberId: amountOwed }
    balances[exp.payerId] = (balances[exp.payerId] || 0) + exp.amount;
    for (const [memberId, share] of Object.entries(exp.shares || {})) {
      balances[memberId] = (balances[memberId] || 0) - share;
    }
  }

  // round to avoid floating point dust
  for (const id of Object.keys(balances)) {
    balances[id] = Math.round(balances[id] * 100) / 100;
  }
  return balances;
}

export function minimizeTransactions(balances) {
  const creditors = [];
  const debtors = [];

  for (const [id, amt] of Object.entries(balances)) {
    if (amt > 0.005) creditors.push({ id, amt });
    else if (amt < -0.005) debtors.push({ id, amt: -amt });
  }

  creditors.sort((a, b) => b.amt - a.amt);
  debtors.sort((a, b) => b.amt - a.amt);

  const transactions = [];
  let i = 0, j = 0;

  while (i < debtors.length && j < creditors.length) {
    const debtor = debtors[i];
    const creditor = creditors[j];
    const amount = Math.min(debtor.amt, creditor.amt);

    if (amount > 0.005) {
      transactions.push({
        fromId: debtor.id,
        toId: creditor.id,
        amount: Math.round(amount * 100) / 100,
      });
    }

    debtor.amt -= amount;
    creditor.amt -= amount;

    if (debtor.amt <= 0.005) i++;
    if (creditor.amt <= 0.005) j++;
  }

  return transactions;
}

export function splitEqually(amount, memberIds, excludedIds = []) {
  const included = memberIds.filter((id) => !excludedIds.includes(id));
  const share = included.length ? amount / included.length : 0;
  return Object.fromEntries(included.map((id) => [id, Math.round(share * 100) / 100]));
}

export function splitByPercentage(amount, percentages) {
  const shares = {};
  for (const [id, pct] of Object.entries(percentages)) {
    shares[id] = Math.round(((amount * pct) / 100) * 100) / 100;
  }
  return shares;
}
