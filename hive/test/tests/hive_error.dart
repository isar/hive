import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Hive error',
    () {
      final e = HiveException('test exception');
      final isHiveError = e is HiveError;
      expect(isHiveError, true);
    },
  );
}
