import 'package:intl/intl.dart';

/// Money lives as integer **piasters** everywhere on the wire (Firestore,
/// domain entities) — `double` is banned for money (Shoppy mistake: rounding
/// drift on totals). This is the one place that crosses to a display string
/// or back, so no other file should touch currency formatting/parsing.
class Money {
  const Money._();

  static const _symbolAr = 'ج.م';
  static const _symbolEn = 'EGP';

  /// Formats piasters as a pound amount, e.g. 125050 -> "1,250.50 ج.م" (ar) or
  /// "EGP 1,250.50" (en). Drops the decimals when the amount is a whole pound.
  static String format(int minor, {required String languageCode}) {
    final isArabic = languageCode == 'ar';
    final pounds = minor / 100;
    final whole = minor % 100 == 0;
    final formatter = NumberFormat.currency(
      locale: isArabic ? 'ar' : 'en',
      symbol: '',
      decimalDigits: whole ? 0 : 2,
    );
    final amount = formatter.format(pounds).trim();
    return isArabic ? '$amount $_symbolAr' : '$_symbolEn $amount';
  }

  /// Parses a user-typed pound amount (Arabic-Indic or Western digits, e.g.
  /// owner price entry in S2) into integer piasters. Returns null on anything
  /// that isn't a plain non-negative number.
  static int? parseToMinor(String input) {
    final western = _toWesternDigits(input.trim());
    final pounds = double.tryParse(western);
    if (pounds == null || pounds < 0) return null;
    return (pounds * 100).round();
  }

  static String _toWesternDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final digit = arabicIndic.indexOf(char);
      buffer.write(digit == -1 ? char : digit.toString());
    }
    return buffer.toString();
  }
}
