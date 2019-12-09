import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/crypto_helper.dart';

class Frame {
  final dynamic key;
  final dynamic value;
  final bool deleted;
  final bool lazy;

  int length;
  int offset = -1;

  Frame(this.key, this.value, {this.length, this.offset = -1})
      : lazy = false,
        deleted = false,
        assert(
            (key is int && key >= 0 && key <= 0xFFFFFFFF) ||
                (key is String && key.length <= 0xFF),
            'Unsupported key');

  Frame.deleted(this.key, {this.length})
      : value = null,
        lazy = false,
        deleted = true,
        offset = -1,
        assert(
            (key is int && key >= 0 && key <= 0xFFFFFFFF) ||
                (key is String && key.length <= 0xFF),
            'Unsupported key');

  Frame.lazy(this.key, {this.length, this.offset = -1})
      : value = null,
        lazy = true,
        deleted = false,
        assert(
            (key is int && key >= 0 && key <= 0xFFFFFFFF) ||
                (key is String && key.length <= 0xFF),
            'Unsupported key');

  Frame toLazy() {
    if (deleted) return this;
    return Frame.lazy(
      key,
      length: length,
      offset: offset,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is Frame) {
      return key == other.key &&
          value == other.value &&
          length == other.length &&
          deleted == other.deleted;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    if (deleted) {
      return 'Frame.deleted(key: $key, length: $length)';
    } else if (lazy) {
      return 'Frame.lazy(key: $key, length: $length, offset: $offset)';
    } else {
      return 'Frame(key: $key, value: $value, '
          'length: $length, offset: $offset)';
    }
  }
}

enum FrameKeyType {
  uintT,
  asciiStringT,
}

enum FrameValueType {
  nullT,
  intT,
  doubleT,
  boolT,
  stringT,
  byteListT,
  intListT,
  doubleListT,
  boolListT,
  stringListT,
  listT,
  mapT,
}
