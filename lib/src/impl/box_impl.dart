part of hive;

class _BoxImpl<E> implements Box<E> {
  _BoxImpl(this.isar) : collection = isar.frames;

  final Isar isar;
  final IsarCollection<int, Frame> collection;

  bool? writeTxn;

  @override
  bool get isOpen => isar.isOpen;

  @override
  String get name => isar.name;

  @override
  String get directory => isar.directory;

  @override
  int get length => collection.count();

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  @override
  T read<T>(T Function() callback) {
    if (writeTxn == null) {
      return isar.read((isar) {
        writeTxn = false;
        try {
          return callback();
        } finally {
          writeTxn = null;
        }
      });
    } else {
      return callback();
    }
  }

  @override
  T write<T>(T Function() callback) {
    if (writeTxn == null) {
      return isar.write((isar) {
        writeTxn = true;
        try {
          return callback();
        } finally {
          writeTxn = null;
        }
      });
    } else if (writeTxn!) {
      return callback();
    } else {
      throw StateError('Cannot write inside a read transaction.');
    }
  }

  @override
  List<String> get keys {
    return collection.where().keyIsNotNull().keyProperty().findAll().cast();
  }

  @override
  String? keyAt(int index) {
    final frame = collection.where().findFirst(offset: index);

    if (frame == null) {
      throw IndexError.withLength(index, length);
    }

    return frame.key;
  }

  E _frameFromJson(Frame frame) {
    return Hive._typeRegistry.fromJson(frame.typeId, frame.value);
  }

  @override
  bool containsKey(String key) {
    return !collection.where().keyEqualTo(key).isEmpty();
  }

  @override
  E? get(String key, {E? defaultValue}) {
    final frame = collection.where().keyEqualTo(key).findFirst();
    return frame != null ? _frameFromJson(frame) : defaultValue;
  }

  @override
  E getAt(int index) {
    final frame = collection.where().findFirst(offset: index);

    if (frame == null) {
      throw IndexError.withLength(index, length);
    }

    return _frameFromJson(frame);
  }

  @override
  E? operator [](dynamic key) {
    if (key is int) {
      return getAt(key);
    } else if (key is String) {
      return get(key);
    } else {
      throw ArgumentError.value(key, 'key', 'must be a String or int');
    }
  }

  @override
  List<E?> getAll(Iterable<String> keys) {
    if (keys.isEmpty) return [];

    final frames = collection
        .where()
        // ignore: inference_failure_on_function_invocation
        .anyOf(
          keys,
          (q, key) => q.keyEqualTo(key),
        )
        .findAll();

    return frames.map(_frameFromJson).toList();
  }

  @override
  List<E> getRange(int start, int end) {
    if (start == 0 && end == 0) {
      return [];
    }

    final frames = collection
        .where()
        .findAll(offset: start, limit: end - start)
        .map(_frameFromJson)
        .toList();

    if (frames.length != end - start) {
      RangeError.checkValidRange(start, end, length);
    }

    return frames;
  }

  @override
  List<E> getBetween({String? startKey, String? endKey}) {
    final frames = collection
        .where()
        .optional(
          endKey != null,
          (q) => q.keyBetween(startKey ?? '', endKey),
        )
        .optional(
          endKey == null,
          (q) => q.keyGreaterThanOrEqualTo(startKey ?? ''),
        )
        .findAll()
        .map(_frameFromJson)
        .toList();

    return frames;
  }

  @override
  void put(String key, E value) {
    write(() {
      final frame = Frame(
        id: collection.autoIncrement(),
        typeId: Hive._typeRegistry.findTypeId(value),
        key: key,
        value: value,
      );
      collection.put(frame);
    });
  }

  @override
  void putAt(int index, E value) {
    write(() {
      final idAtIndex =
          collection.where().idProperty().findFirst(offset: index);
      if (idAtIndex == null) {
        throw IndexError.withLength(index, length);
      }

      final frame = Frame(
        id: idAtIndex,
        typeId: Hive._typeRegistry.findTypeId(value),
        value: value,
      );
      collection.put(frame);
    });
  }

  @override
  void operator []=(Object key, E value) {
    if (key is int) {
      putAt(key, value);
    } else if (key is String) {
      put(key, value);
    } else {
      throw ArgumentError.value(key, 'key', 'must be a String or int');
    }
  }

  @override
  void putAll(Map<String, E> entries) {
    write(() {
      if (entries.isEmpty) return;

      final frames = <Frame>[];
      for (final entry in entries.entries) {
        final frame = Frame(
          id: collection.autoIncrement(),
          typeId: Hive._typeRegistry.findTypeId(entry.value),
          key: entry.key,
          value: entry.value,
        );
        frames.add(frame);
      }
      collection.putAll(frames);
    });
  }

  @override
  void putRange(int start, int end, Iterable<E> values) {
    write(() {
      if (start == 0 && end == 0) {
        return;
      }

      final idsInRange = collection
          .where()
          .idProperty()
          .findAll(offset: start, limit: end - start);

      if (idsInRange.length != end - start) {
        RangeError.checkValidRange(start, end, length);
        throw ArgumentError.value(
          values,
          'values',
          'must have the same length as the range',
        );
      }

      final frames = <Frame>[];
      for (final value in values) {
        final frame = Frame(
          id: idsInRange[frames.length],
          typeId: Hive._typeRegistry.findTypeId(value),
          value: value,
        );
        frames.add(frame);
      }
      collection.putAll(frames);
    });
  }

  @override
  void add(E value, {String? key}) {
    write(() {
      final frame = Frame(
        id: collection.autoIncrement(),
        typeId: Hive._typeRegistry.findTypeId(value),
        key: key,
        value: value,
      );
      collection.put(frame);
    });
  }

  @override
  void addAll(Iterable<E> values) {
    write(() {
      final frames = <Frame>[];
      for (final value in values) {
        final frame = Frame(
          id: collection.autoIncrement(),
          typeId: Hive._typeRegistry.findTypeId(value),
          value: value,
        );
        frames.add(frame);
      }
      collection.putAll(frames);
    });
  }

  @override
  bool delete(String key) {
    return write(() {
      return collection.where().keyEqualTo(key).deleteFirst();
    });
  }

  @override
  void deleteAt(int index) {
    return write(() {
      final deleted = collection.where().deleteFirst(offset: index);
      if (!deleted) {
        throw IndexError.withLength(index, length);
      }
    });
  }

  @override
  int deleteAll(Iterable<String> keys) {
    return write(() {
      if (keys.isEmpty) return 0;
      return collection
          .where()
          // ignore: inference_failure_on_function_invocation
          .anyOf(keys, (q, key) => q.keyEqualTo(key))
          .deleteAll();
    });
  }

  @override
  void deleteRange(int start, int end) {
    return write(() {
      if (start == 0 && end == 0) {
        return;
      }

      final deleted =
          collection.where().deleteAll(offset: start, limit: end - start);

      if (deleted != end - start) {
        RangeError.checkValidRange(start, end, length);
      }
    });
  }

  @override
  void clear({bool notify = true}) {
    isar.write((isar) {
      collection.clear();
    });
  }

  @override
  void close() {
    Hive._openBoxes.remove(name);
    isar.close();
  }

  @override
  void deleteFromDisk() {
    Hive._openBoxes.remove(name);
    isar.close(deleteFromDisk: true);
  }

  @override
  Stream<E?> watchKey(String key) {
    return isar.frames.where().keyEqualTo(key).watch().map((frames) {
      final frame = frames.firstOrNull;
      if (frame == null) {
        return null;
      } else {
        return _frameFromJson(frame);
      }
    });
  }

  @override
  Stream<void> watch() {
    return isar.frames.watchLazy();
  }
}
