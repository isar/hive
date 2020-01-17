import 'package:hive/hive.dart';
import 'package:hive/src/util/string_extension.dart';

class Frame {
  final dynamic key;
  final dynamic value;
  final bool deleted;
  final bool lazy;

  int length;
  int offset = -1;

  Frame(this.key, this.value, {this.length, this.offset = -1})
      : lazy = false,
        deleted = false {
    assert(assertKey(key));
  }

  Frame.deleted(this.key, {this.length})
      : value = null,
        lazy = false,
        deleted = true,
        offset = -1 {
    assert(assertKey(key));
  }

  Frame.lazy(this.key, {this.length, this.offset = -1})
      : value = null,
        lazy = true,
        deleted = false {
    assert(assertKey(key));
  }

  static bool assertKey(dynamic key) {
    if (key is int) {
      if (key < 0 || key > 0xFFFFFFFF) {
        throw HiveError('Integer keys need to be in the range 0 - 0xFFFFFFFF');
      }
    } else if (key is String) {
      if (key.length > 0xFF || !key.isAscii) {
        throw HiveError(
            'String keys need to be ASCII Strings with a max length of 255');
      }
    } else {
      throw HiveError('Keys need to be Strings or integers');
    }

    return true;
  }

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

class FrameKeyType {
  static const uintT = 0;
  static const asciiStringT = 1;
}

class FrameValueType {
  static const nullT = 0;
  static const intT = 1;
  static const doubleT = 2;
  static const boolT = 3;
  static const stringT = 4;
  static const byteListT = 5;
  static const intListT = 6;
  static const doubleListT = 7;
  static const boolListT = 8;
  static const stringListT = 9;
  static const listT = 10;
  static const mapT = 11;
  static const hiveListT = 12;
}
