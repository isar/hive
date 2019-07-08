import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:test/test.dart';

import 'common.dart';

Future<BufferedFileReader> openReaderWithBytes(
    List<int> bytes, int chunkSize) async {
  var file = await getTempFile();
  await file.writeAsBytes(bytes);
  return await BufferedFileReader.fromFile(file, chunkSize);
}

void main() {
  test("skip", () async {
    var reader = await openReaderWithBytes(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], 3);

    var bytes = await reader.read(1);
    expect(bytes.first, 1);
    expect(reader.offset, 1);

    var skipped = await reader.skip(2);
    expect(skipped, 2);
    expect(reader.offset, 3);

    bytes = await reader.read(1);
    expect(bytes.first, 4);

    skipped = await reader.skip(2);
    expect(skipped, 2);
    expect(reader.offset, 6);

    skipped = await reader.skip(1);
    expect(skipped, 1);
    expect(reader.offset, 7);

    bytes = await reader.read(1);
    expect(bytes.first, 8);

    skipped = await reader.skip(5);
    expect(skipped, 5); // 1 left in buffer, 4 additional read
    expect(reader.offset, 13);

    skipped = await reader.skip(3);
    expect(skipped, 1);
    expect(reader.offset, 14);

    await reader.close();
  });

  test("read", () async {
    var reader = await openReaderWithBytes(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], 4);

    var bytes = await reader.read(1);
    expect(bytes.first, 1);
    expect(reader.offset, 1);

    bytes = await reader.read(3);
    expect(bytes, [2, 3, 4]);
    expect(reader.offset, 4);

    bytes = await reader.read(4);
    expect(bytes, [5, 6, 7, 8]);
    expect(reader.offset, 8);

    bytes = await reader.read(5);
    expect(bytes, [9, 10, 11, 12, 13]);
    expect(reader.offset, 13);

    bytes = await reader.read(3);
    expect(bytes, [14]);
    expect(reader.offset, 14);

    bytes = await reader.read(1);
    expect(bytes, []);
    expect(reader.offset, 14);

    await reader.close();
  });

  test("setPosition", () {
    // TODO add test
  });

  test("close", () async {
    var reader = await openReaderWithBytes([1, 2, 3, 4], 3);

    var bytes = await reader.read(1);
    expect(bytes.first, 1);
    expect(reader.offset, 1);

    await reader.close();

    expect(() => reader.file.read(1), throwsA(anything));
  });
}
