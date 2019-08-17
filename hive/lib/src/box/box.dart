part of hive;

class BoxEvent {
  final dynamic key;
  final dynamic value;
  final bool deleted;

  BoxEvent(this.key, this.value, this.deleted);

  @override
  bool operator ==(dynamic other) {
    if (other is BoxEvent) {
      return other.key == key && other.value == value;
    }
    return false;
  }
}

abstract class Box implements TypeRegistry {
  String get name;

  bool get isOpen;

  String get path;

  bool get lazy;

  Iterable<dynamic> get keys;

  int get length;

  Iterable<dynamic> get values;

  dynamic keyAt(int index);

  Stream<BoxEvent> watch({dynamic key});

  bool containsKey(dynamic key);

  dynamic get(dynamic key, {dynamic defaultValue});

  dynamic getAt(int index, {dynamic defaultValue});

  Future<void> put(dynamic key, dynamic value);

  Future<void> putAt(int index, dynamic value);

  Future<void> putAll(Map<dynamic, dynamic> entries);

  Future<int> add(dynamic value);

  Future<List<int>> addAll(List<dynamic> values);

  Future<void> delete(dynamic key);

  Future<void> deleteAt(int index);

  Future<void> deleteAll(List<dynamic> keys);

  Map<dynamic, dynamic> toMap();

  Future<void> compact();

  Future<int> clear();

  Future<void> close();

  Future<void> deleteFromDisk();
}
