import 'dart:async';
import 'dart:developer';
import 'dart:html';
import 'dart:indexed_db';

import 'dart:js';
import 'package:js/js.dart';
import 'package:js/js_util.dart';


///
///
/// CAUTION: THIS FILE NEEDS TO BE MANUALLY COMPILED
///
/// As Dart does not directly support web workers, this file needs to be
/// re-compiled after you change it in order to enable local testing.
///
/// For pub.dev releases, the file is already pre-compiled and uploaded to
/// simplify usage.
///
/// ```shell
/// hive/lib/src/backend/js/web_worker
/// dart compile js web_worker.dart -o web_worker.dart.js -m
/// ```
///

@JS('self')
external DedicatedWorkerGlobalScope get globalScopeSelf;

Stream<T> callbackToStream<J, T>(
    String name, T Function(J jsValue) unwrapValue) {
  final controller = StreamController<T>.broadcast(sync: true);
  setProperty(context['self'] as Object, name, allowInterop((J event) {
    controller.add(unwrapValue(event));
  }));
  return controller.stream;
}

IdbFactory? get indexedDB => globalScopeSelf.indexedDB;

Map<String, Database> _databases = {};

ObjectStore getObjectStore(String database, String box, bool write) {
  return _databases[database]!
      .transaction(box, write ? 'readwrite' : 'readonly')
      .objectStore(box);
}

main() async {
  callbackToStream('onmessage', (MessageEvent e) {
    return getProperty(e, 'data');
  }).listen((data) async {
    try {
      if (data! is JsArray) {
        log('Unexpected data type ${data.runtimeType}');
        throw TypeError();
      }

      final label = data[0];
      final command = data[1] as String;

      void respond(dynamic response) {
        sendResponse(context, label, response);
      }

      switch (command) {
        case 'open':
          final name = data[2] as String;
          final dbCompleter = Completer<Database?>();
          indexedDB!.open(name, version: 1, onUpgradeNeeded: (e) {
            final db = e.target.result as Database;
            if (!db.objectStoreNames!.contains('box')) {
              db.createObjectStore('box');
            }
            // dbCompleter.complete(db);
          }, onBlocked: (event) {
            log('Error opening indexed DB');
            dbCompleter.complete(null);
          }).then(dbCompleter.complete);
          final db = await dbCompleter.future;
          if (db != null) {
            _databases[name] = db;
          }
          respond(db?.name);
          break;

        case 'close':
          final name = data[2];
          _databases[name]!.close();
          respond(null);
          break;

        case 'createObjectStore':
          final database = data[2] as String;
          final name = data[3] as String;
          final result = _databases[database]!.createObjectStore(name);
          respond(result);
          break;

        case 'add':
          final database = data[2] as String;
          final name = data[3] as String;
          final value = data[4];
          final key = data[5];
          await getObjectStore(database, name, true).add(value, key);
          respond(null);
          break;

        case 'clear':
          final database = data[2] as String;
          final name = data[3] as String;
          await getObjectStore(database, name, true).clear();
          respond(null);
          break;

        case 'delete':
          final database = data[2] as String;
          final name = data[3] as String;
          final key = data[4];
          await getObjectStore(database, name, true).delete(key);
          respond(null);
          break;

        case 'getAll':
          final database = data[2] as String;
          final name = data[3] as String;
          var completer = Completer<List<dynamic>>();
          var request = getObjectStore(database, name, false).getAll(null);
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
          final database = data[2] as String;
          final name = data[3] as String;
          var completer = Completer<List<dynamic>>();
          var request = getObjectStore(database, name, false).getAllKeys(null);
          request.onSuccess.listen((_) {
            completer.complete(request.result as List<dynamic>?);
          });
          request.onError.listen((_) {
            completer.completeError(request.error!);
          });
          final result = await completer.future;
          respond(result);
          break;

        case 'put':
          final database = data[2] as String;
          final name = data[3] as String;
          final value = data[4];
          final key = data[5];
          await getObjectStore(database, name, true).put(value, key);
          respond(null);
          break;

        case 'get':
          final database = data[2] as String;
          final name = data[3] as String;
          final key = data[4];
          final response =
              await getObjectStore(database, name, false).getObject(key);
          respond(response);
          break;
        default:
          window.console.warn('[web worker] Unknown command $command');
          break;
      }
    }  catch (e,s) {
      log('[Hive web socket]: Runtime error:', error: e,stackTrace: s);
    }
  });
}

void sendResponse(JsObject context, dynamic label, dynamic response) {
  try {
    globalScopeSelf.postMessage(jsify({
      'label': label,
      'response': response,
    }));
  } catch (e,s) {
    log('Error responding:', error: e, stackTrace: s);
  }
}
