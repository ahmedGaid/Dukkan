// test/failures_test.dart
import 'package:dukkan/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ServerFailure defaults code to null (existing call sites unaffected)', () {
    const failure = ServerFailure('boom');
    expect(failure.message, 'boom');
    expect(failure.code, isNull);
  });

  test('ServerFailure carries a structured code when given one', () {
    const failure = ServerFailure('The order was already updated', 'permission-denied');
    expect(failure.code, 'permission-denied');
  });

  test('two ServerFailures with the same message but different codes are not equal', () {
    expect(
      const ServerFailure('x', 'unavailable') == const ServerFailure('x', 'permission-denied'),
      isFalse,
    );
  });
}
