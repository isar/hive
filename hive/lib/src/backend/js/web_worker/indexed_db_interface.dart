import 'dart:html';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/web_worker/web_worker_interface.dart';

class IndexedDbWebWorkerInterface {
  final HiveCipher? cipher;
  final WebWorkerInterface worker;

  IndexedDbWebWorkerInterface(this.cipher)
      : worker = WebWorkerInterface(cipher);

  Future deleteDatabase(String name, {void Function(Event e)? onBlocked}) {
    return worker.query(['deleteDatabase', name]);
  }

  Future<DatabaseImplementation> open(
    String name,
  ) async {
    final response = await worker.query<String>(['open', name]);
    return DatabaseImplementation.fromWorkerResponse(worker, response);
  }
}

class DatabaseImplementation {
  final WebWorkerInterface worker;
  final String name;

  factory DatabaseImplementation.fromWorkerResponse(
          WebWorkerInterface worker, String name) =>
      DatabaseImplementation._(worker, name);

  DatabaseImplementation._(this.worker, this.name);

  void close() {
    worker.query(['close', name]);
  }

  Future<ObjectStoreImplementation> createObjectStore(
    String name,
  ) async {
    final response = await worker.query<String>([
      'createObjectStore',
      this.name,
      name,
    ]);
    return ObjectStoreImplementation.fromDatabase(this, response);
  }

  Future<ObjectStoreImplementation> transaction(
      String name, String mode) async {
    final response =
        await worker.query<String>(['transaction', this.name, name, mode]);
    return ObjectStoreImplementation.fromDatabase(this, response);
  }

  ObjectStoreImplementation makeObjectStore(String box) {
    return ObjectStoreImplementation.fromDatabase(this, box);
  }
}

class ObjectStoreImplementation {
  final WebWorkerInterface worker;
  final String database;
  final String name;

  factory ObjectStoreImplementation.fromDatabase(
          DatabaseImplementation database, String name) =>
      ObjectStoreImplementation._(database.worker, database.name, name);

  ObjectStoreImplementation._(this.worker, this.database, this.name);

  Future add(Object value, [Object? key]) {
    return worker.query(['add', database, name, value, if (key != null) key]);
  }

  Future clear() {
    return worker.query(['clear', database, name]);
  }

  Future delete(dynamic key) {
    return worker.query(['delete', database, name, key]);
  }

  Future<List<dynamic>?> getAll() {
    return worker.query(['getAll', database, name]);
  }

  Future<List<dynamic>?> getAllKeys() {
    return worker.query(['getAllKeys', database, name]);
  }

  Future getObject(key) {
    return worker.query(['get', database, name, key]);
  }

  Future put(value, [key]) {
    return worker.query(['put', database, name, value, key]);
  }
}
