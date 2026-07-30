import 'dart:io';

/// Turns board rows into an Excel-friendly CSV and saves it locally (FC17).
/// No `share_plus`/`csv` package — this is small enough to own directly and
/// CLAUDE.md forbids a new dependency without asking.
class CsvExporter {
  const CsvExporter._();

  /// RFC 4180 quoting (comma/quote/newline triggers a quoted field, embedded
  /// quotes doubled) + a leading UTF-8 BOM so Excel opens Arabic text as
  /// Arabic instead of mojibake. Rows joined with CRLF per the RFC.
  static String toCsv(List<List<String>> rows) {
    final buffer = StringBuffer('﻿');
    for (final row in rows) {
      buffer.write(row.map(_quoteField).join(','));
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  static String _quoteField(String field) {
    final needsQuoting =
        field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r');
    if (!needsQuoting) return field;
    return '"${field.replaceAll('"', '""')}"';
  }

  /// Writes [csv] to a local file named [name] (include the `.csv`
  /// extension) and returns the absolute path. Desktop saves under the
  /// user's `Downloads/` folder (`dart:io`, no plugin); mobile has no
  /// documents-dir plugin here (`path_provider` would be a new dependency),
  /// so it saves under the app's system temp dir instead — good enough since
  /// the caller shows the path as selectable text rather than opening it.
  static Future<String> saveCsv(String name, String csv) async {
    final dir = await _targetDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsString(csv, flush: true);
    return file.path;
  }

  static Future<Directory> _targetDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return Directory('${Directory.systemTemp.path}${Platform.pathSeparator}dukkan-exports');
    }
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return Directory('${Directory.systemTemp.path}${Platform.pathSeparator}dukkan-exports');
    }
    return Directory('$home${Platform.pathSeparator}Downloads');
  }
}
