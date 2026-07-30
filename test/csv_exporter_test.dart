import 'package:dukkan/presentation/console/util/csv_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvExporter.toCsv', () {
    test('prefixes a UTF-8 BOM', () {
      final csv = CsvExporter.toCsv([
        ['a', 'b'],
      ]);
      expect(csv.startsWith('﻿'), isTrue);
    });

    test('leaves a plain field unquoted', () {
      final csv = CsvExporter.toCsv([
        ['plain', '123'],
      ]);
      expect(csv, '﻿plain,123\r\n');
    });

    test('quotes a field containing a comma', () {
      final csv = CsvExporter.toCsv([
        ['a, b', 'c'],
      ]);
      expect(csv, '﻿"a, b",c\r\n');
    });

    test('quotes a field containing a quote and doubles it', () {
      final csv = CsvExporter.toCsv([
        ['say "hi"', 'c'],
      ]);
      expect(csv, '﻿"say ""hi""",c\r\n');
    });

    test('quotes a field containing a newline', () {
      final csv = CsvExporter.toCsv([
        ['line1\nline2', 'c'],
      ]);
      expect(csv, '﻿"line1\nline2",c\r\n');
    });

    test('preserves Arabic text and does not quote it needlessly', () {
      final csv = CsvExporter.toCsv([
        ['دكان النور', 'شارع النصر'],
      ]);
      expect(csv, '﻿دكان النور,شارع النصر\r\n');
    });

    test('joins multiple rows with CRLF', () {
      final csv = CsvExporter.toCsv([
        ['h1', 'h2'],
        ['v1', 'v2'],
      ]);
      expect(csv, '﻿h1,h2\r\nv1,v2\r\n');
    });
  });
}
