import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:indexed_db';

import 'dart:js';
import 'package:hive/src/backend/js/web_worker/web_worker_operation.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

///
///
/// CAUTION: THIS FILE NEEDS TO BE MANUALLY COMPILED
///
/// 1. in your project, create a file `web/web_worker.dart`
/// 2. add the following contents:
/// ```dart
/// import 'package:hive/hive.dart';
///
/// Future<void> main() => startWebWorker();
/// ```
/// 3. compile the file using:
/// ```shell
/// dart compile js -o web/web_worker.dart.js -m web/web_worker.dart
/// ```
///
/// You should not check in that file into your VCS. Instead, you should compile
/// the web worker in your CI pipeline.
///

@pragma('dart2js:tryInline')
Future<void> startWebWorker() async {
  print('[web worker]: Starting...');
  setProperty(
    context['self'] as Object,
    'onmessage',
    allowInterop(
      (MessageEvent event) async {
        final data = event.data;
        try {
          final operation = WebWorkerOperation.fromJson(Map.from(data as Map));

          void respond([Object? response]) {
            allowInterop(sendResponse).call(operation.label, response);
          }

          switch (operation.command) {
            case 'open':
              try {
                Set<String> storeNames = {};

                if (operation.objectStore != null) {
                  storeNames.add(operation.objectStore!);
                } else if (operation.value is Iterable) {
                  storeNames.addAll(
                      (operation.value as Iterable).whereType<String>());
                } else {
                  storeNames.add('box');
                }

                var version = await getDatabaseVersion(operation.database);

                var db = await indexedDB!.open(operation.database,
                    version: version, onUpgradeNeeded: (e) {
                  var db = e.target.result as Database;
                  for (var objectStoreName in storeNames) {
                    if (!(db.objectStoreNames ?? [])
                        .contains(objectStoreName)) {
                      db.createObjectStore(objectStoreName);
                    }
                  }
                }, onBlocked: (e) {
                  print('[web worker] Error opening indexed DB: ${event.data}');
                });

                // in case the objectStore is not contained, re-open the db and
                // update version
                if (!(storeNames.every((objectStoreName) =>
                    (db.objectStoreNames ?? []).contains(objectStoreName)))) {
                  db.close();
                  version++;
                  setDatabaseVersion(operation.database, version);
                  db = await indexedDB!.open(operation.database,
                      version: version, onUpgradeNeeded: (e) {
                    var db = e.target.result as Database;
                    for (var objectStoreName in storeNames) {
                      if (!(db.objectStoreNames ?? [])
                          .contains(objectStoreName)) {
                        db.createObjectStore(objectStoreName);
                      }
                    }
                  }, onBlocked: (e) {
                    print(
                        '[web worker] Error opening indexed DB: ${event.data}');
                  });
                }
                _databases[operation.database] = db;
                respond(db.name);
              } on Event catch (e, s) {
                print('[web worker]: Runtime error:'
                    ' ${(e.target as Request).error}, $s');
              }
              break;

            case 'close':
              _databases[operation.database]!.close();
              respond();
              break;

            case 'createObjectStore':
              final result = _databases[operation.database]!
                  .createObjectStore(operation.objectStore!);
              respond(result);
              break;

            case 'add':
              await getObjectStore(
                      operation.database, operation.objectStore!, true)
                  .add(operation.value, operation.key);
              respond();
              break;

            case 'clear':
              await getObjectStore(
                      operation.database, operation.objectStore!, true)
                  .clear();
              respond();
              break;

            case 'delete':
              try {
                final _db = _databases[operation.database] ??
                    await indexedDB!.open(operation.database);

                // directly deleting the entire DB if a non-collection Box
                if (_db.objectStoreNames?.length == 1) {
                  await indexedDB!.deleteDatabase(_db.name!);
                } else {
                  final db = await indexedDB!.open(_db.name!, version: 1,
                      onUpgradeNeeded: (e) {
                    var db = e.target.result as Database;
                    if ((db.objectStoreNames ?? [])
                        .contains(operation.objectStore)) {
                      db.deleteObjectStore(operation.objectStore!);
                    }
                  });
                  if ((db.objectStoreNames ?? []).isEmpty) {
                    await indexedDB!.deleteDatabase(_db.name!);
                  }
                }
              } finally {}
              respond();
              break;

            case 'getAll':
              var completer = Completer<List<dynamic>>();
              var request = getObjectStore(
                      operation.database, operation.objectStore!, false)
                  .getAll(null);
              request.onSuccess.listen((_) {
                completer.complete(request.result as List<dynamic>?);
              });
              request.onError.listen((_) {
                completer.completeError(request.error!);
              });
              final result = await completer.future;
              respond(result);
              break;

            case 'getAllKeys':
              var completer = Completer<List<dynamic>>();
              try {
                var request = getObjectStore(
                        operation.database, operation.objectStore!, false)
                    .getAllKeys(null);
                request.onSuccess.listen((_) {
                  completer.complete(request.result as List<dynamic>?);
                });
                request.onError.listen((_) {
                  completer.completeError(request.error!);
                });
              } catch (e) {
                print('[web worker] $e');
              }
              final result = await completer.future;
              respond(result);
              break;

            case 'put':
              final objectStore = getObjectStore(
                  operation.database, operation.objectStore!, true);
              final keys = List.from(operation.key as Iterable);
              final values = List.from(operation.value as Iterable);
              final futures = <Future>[];
              for (var i = 0; i < keys.length; i++) {
                futures.add(objectStore.put(values[i], keys[i]));
              }
              await Future.wait(futures);

              respond();
              break;

            case 'deleteKey':
              final objectStore = getObjectStore(
                  operation.database, operation.objectStore!, true);
              final keys = List.from(operation.key as Iterable);
              final futures = <Future>[];
              for (var i = 0; i < keys.length; i++) {
                futures.add(objectStore.delete(keys[i]));
              }
              await Future.wait(futures);

              respond();
              break;

            case 'get':
              final store = getObjectStore(
                  operation.database, operation.objectStore!, false);
              final response = await store.getObject(operation.key);
              respond(response);

              break;

            case 'startTransaction':
              final db = _databases[operation.database]!;
              // value represents all affected objectStoreNames here, as
              // [operation.objectStore] is not a `List<String>`
              final txn = db.transaction(operation.value, 'read-write');
              _transactions[operation.transaction!] = txn;
              respond();
              break;

            case 'stopTransaction':
              _transactions.remove(operation.transaction!);
              respond();
              break;

            default:
              print('[web worker] Unknown command ${operation.command}');
              respond();
              break;
          }
        } on Event catch (e, s) {
          allowInterop(_replyError)
              .call((e.target as Request).error, s, data['label'] as double);
        } catch (e, s) {
          allowInterop(_replyError).call(e, s, data['label'] as double);
        }
      },
    ),
  );
}

final Map<String, int> _versionCache = {};

Future<int> getDatabaseVersion(String database) async {
  if (_versionCache.isEmpty) {
    final db = await indexedDB!.open('hive_web_worker_database_versions',
        version: 1, onUpgradeNeeded: (e) {
      final db = (e.target.result as Database);
      db.createObjectStore('versions');
    });
    _databases['hive_web_worker_database_versions'] = db;
    final txn = db.transaction('versions', 'readonly');

    final versions = await txn.objectStore('versions').getObject('versions');

    if (versions is LinkedHashMap) {
      _versionCache.addAll(versions.cast());
    }
  }
  if (!_versionCache.containsKey(database)) {
    setDatabaseVersion(database, 1);
  }
  return _versionCache[database]!;
}

// caches background put operation of database versions
Future? _putVersionsFuture;

void setDatabaseVersion(String database, int version) {
  _versionCache[database] = version;
  (_putVersionsFuture ?? Future.value(null)).then((value) {
    final db = _databases['hive_web_worker_database_versions']!;
    final txn = db.transaction('versions', 'readwrite');
    _putVersionsFuture =
        txn.objectStore('versions').put(jsify(_versionCache), 'versions');
    _putVersionsFuture?.then((value) => _putVersionsFuture = null);
  });
}

void sendResponse(double label, dynamic response) {
  try {
    self.postMessage({
      'label': label,
      'response': response,
    });
  } catch (e, s) {
    print('[web worker] Error responding: $e, $s');
  }
}

void _replyError(Object? error, StackTrace stackTrace, double origin) {
  if (error != null) {
    try {
      final jsError = jsify(error);
      if (jsError != null) {
        error = jsError;
      }
    } catch (e) {
      error = error.toString();
    }
  }
  try {
    self.postMessage({
      'label': 'stacktrace',
      'origin': origin,
      'error': error,
      'stacktrace': stackTrace.toString(),
    });
  } catch (e, s) {
    print('[web worker] Error responding: $e, $s');
  }
}

/// represents the [WorkerGlobalScope] the worker currently runs in.
@JS('self')
external WorkerGlobalScope get self;

/// adding all missing WebWorker-only properties to the [WorkerGlobalScope]
extension on WorkerGlobalScope {
  void postMessage(Object data) {
    callMethod(self, 'postMessage', [jsify(data)]);
  }
}

IdbFactory? get indexedDB => self.indexedDB;

Map<String, Database> _databases = {};

Map<String, Transaction> _transactions = {};

ObjectStore getObjectStore(
  String database,
  String box,
  bool write, [
  String? transaction,
]) {
  if (transaction != null) {
    if (_transactions.containsKey(transaction)) {
      return _transactions[transaction]!.objectStore(box);
    } else {
      final txn = _databases[database]!
          .transaction(box, write ? 'readwrite' : 'readonly');
      _transactions[transaction] = txn;
      return txn.objectStore(box);
    }
  } else {
    return _databases[database]!
        .transaction(box, write ? 'readwrite' : 'readonly')
        .objectStore(box);
  }
}
