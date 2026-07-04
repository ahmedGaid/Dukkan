/// Arabic-aware search folding — collapses the letter variants people type
/// inconsistently (hamza forms, ة/ه, ي/ى, tashkeel, tatweel) so a query matches
/// a record however either side was spelled. Apply to BOTH the query and the
/// text before comparing; it shapes the comparison key only, never displayed
/// text. Mirrors Conductor's `arabicSearch.ts` / `search_api.fold_arabic`.
library;

final _tashkeel = RegExp('[ً-ْٰ]'); // harakat, tanwin, shadda, sukun, dagger-alef
final _tatweel = RegExp('ـ'); // kashida
final _alef = RegExp('[أإآٱ]'); // أ إ آ ٱ → ا
final _ya = RegExp('[ئي]'); // ئ ي → ى

/// Fold Arabic letter variants to one canonical form.
String foldArabic(String s) {
  s = s.replaceAll(_tashkeel, '');
  s = s.replaceAll(_tatweel, '');
  s = s.replaceAll(_alef, 'ا'); // → ا
  s = s.replaceAll('ؤ', 'و'); // ؤ → و
  s = s.replaceAll(_ya, 'ى'); // → ى
  s = s.replaceAll('ة', 'ه'); // ة → ه
  s = s.replaceAll('ء', ''); // bare hamza ء → drop
  return s;
}

/// Canonical search key: lower-cased (Latin) + Arabic-folded, trimmed.
String normalizeSearch(String s) => foldArabic(s.toLowerCase()).trim();
