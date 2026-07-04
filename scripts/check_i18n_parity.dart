// Fails (exit 1) if lib/l10n/app_ar.arb and app_en.arb don't have the exact
// same set of keys. Run: dart run scripts/check_i18n_parity.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final arFile = File('lib/l10n/app_ar.arb');
  final enFile = File('lib/l10n/app_en.arb');

  final arKeys = _messageKeys(arFile);
  final enKeys = _messageKeys(enFile);

  final missingInEn = arKeys.difference(enKeys);
  final missingInAr = enKeys.difference(arKeys);

  if (missingInEn.isEmpty && missingInAr.isEmpty) {
    stdout.writeln('i18n parity OK (${arKeys.length} keys).');
    return;
  }

  if (missingInEn.isNotEmpty) {
    stderr.writeln('Missing in app_en.arb: ${missingInEn.join(', ')}');
  }
  if (missingInAr.isNotEmpty) {
    stderr.writeln('Missing in app_ar.arb: ${missingInAr.join(', ')}');
  }
  exit(1);
}

Set<String> _messageKeys(File file) {
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return json.keys
      .where((key) => !key.startsWith('@'))
      .toSet();
}
