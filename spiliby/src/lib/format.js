export const formatMoney = (amount) => {
  const n = Number(amount) || 0;
  return `₹${n.toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;
};

export const formatDate = (isoOrDate) => {
  const d = new Date(isoOrDate);
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
};

export const isToday = (isoOrDate) => {
  const d = new Date(isoOrDate);
  const now = new Date();
  return d.toDateString() === now.toDateString();
};

export const isThisMonth = (isoOrDate) => {
  const d = new Date(isoOrDate);
  const now = new Date();
  return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
};

export const initials = (name = '') =>
  name.trim().split(/\s+/).slice(0, 2).map((w) => w[0]?.toUpperCase() || '').join('');
