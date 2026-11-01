/// Date / period helpers (no intl dependency).
class Fmt {
  Fmt._();
  static const _m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String _2(int v) => v.toString().padLeft(2, '0');
  static String date(DateTime? d) => d == null ? '-' : '${_2(d.day)} ${_m[d.month - 1]} ${d.year}';
  static String ymd(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)}';
  static String period(DateTime d) => '${d.year}-${_2(d.month)}';
  static String dateTime(DateTime d) => '${date(d)} ${_2(d.hour)}:${_2(d.minute)}';

  /// 'YYYY-MM' list, newest first.
  static List<String> lastPeriods([int n = 12]) {
    final now = DateTime.now();
    return [for (var i = 0; i < n; i++) period(DateTime(now.year, now.month - i))];
  }

  /// Whole days from today (negative = already past).
  static int daysUntil(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(d.year, d.month, d.day).difference(today).inDays;
  }
}
