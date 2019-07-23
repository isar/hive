import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class BoxBaseMock extends BoxBase with Mock {
  BoxBaseMock(TypeRegistry parent) : super(parent);
}

void main() {
  group('BoxBase', () {
    test('.transaction() & .waitForRunningTransactions()', () async {
      var boxMock = BoxBaseMock(null);

      var finished = false;
      // ignore: unawaited_futures
      boxMock.transaction((trx) async {
        await Future.delayed(Duration(milliseconds: 100));
        await trx.put('key', 'val');
      }).then((_) {
        finished = true;
      });
      expect(finished, false);
      await boxMock.waitForRunningTransactions();
      expect(finished, true);

      verify(boxMock.putAll({'key': 'val'}));
    });
  });
}
