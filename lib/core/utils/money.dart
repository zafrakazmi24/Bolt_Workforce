/// Money is stored everywhere as an INTEGER number of halalas (1 SAR = 100),
/// never as double - required by the spec for payroll precision.
class Money {
  Money._();

  static int toMinor(num riyals) => (riyals * 100).round();

  /// "SAR 298,803" (rounded to whole riyals for dashboard display).
  static String sar(int minor) => 'SAR ${grouped((minor / 100).round())}';

  /// "298,803.50"
  static String sarExact(int minor) {
    final neg = minor < 0;
    final abs = minor.abs();
    final whole = grouped(abs ~/ 100);
    final frac = (abs % 100).toString().padLeft(2, '0');
    return '${neg ? '-' : ''}SAR $whole.$frac';
  }

  static String grouped(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
