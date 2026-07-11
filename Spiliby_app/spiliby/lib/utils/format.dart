import 'package:intl/intl.dart';

final _inr = NumberFormat.decimalPattern('en_IN');

String formatMoney(num? amount) {
  final n = amount ?? 0;
  return '₹${_inr.format(n)}';
}

DateTime _parse(String isoOrDate) => DateTime.tryParse(isoOrDate) ?? DateTime.now();

String formatDate(String isoOrDate) {
  final d = _parse(isoOrDate);
  return DateFormat('d MMM').format(d);
}

bool isToday(String isoOrDate) {
  final d = _parse(isoOrDate);
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

bool isThisMonth(String isoOrDate) {
  final d = _parse(isoOrDate);
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month;
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
  return parts.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);