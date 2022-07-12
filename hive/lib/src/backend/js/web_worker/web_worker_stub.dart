import 'dart:async';

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

Future<void> startWebWorker() => Future.value();
