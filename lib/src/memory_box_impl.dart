import 'dart:collection';

import 'package:hive/src/box_impl.dart';
import 'package:hive/src/box_options.dart';
import 'package:hive/src/hive_instance_impl.dart';
import 'package:hive/src/io/synced_file.dart';

class MemoryBoxImpl extends BoxImpl {
  var _cache = HashMap<String, dynamic>();

  MemoryBoxImpl(HiveInstanceImpl hive, String name, BoxOptions options,
      SyncedFile hiveFile)
      : super(hive, name, options, hiveFile);

  @override
  Future<int> clear() {
    _cache.clear();
    return super.clear();
  }

  @override
  Future<List<bool>> deleteAll(Iterable<String> keys) {
    for (var key in keys) {
      _cache.remove(key);
    }
    return super.deleteAll(keys);
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) {
    return Future.value(_cache[key]?.value);
  }

  @override
  Future<void> put(String key, value) {
    _cache[key] = value;
    return super.put(key, value);
  }

  @override
  Future<void> putAll(Map<String, dynamic> entries) {
    _cache.addAll(entries);
    return super.putAll(entries);
  }

  @override
  Future<Map<String, dynamic>> toMap() {
    return Future.value(_cache.map((k, entry) => entry.value));
  }
}
