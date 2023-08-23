/// Hive is a lightweight and blazing fast key-value store made for Flutter and
/// Dart. It is strongly encrypted using AES-256.
library hive;

import 'dart:async';
import 'dart:isolate'
    if (dart.library.html) 'package:hive/src/impl/isolate_stub.dart';

import 'package:hive/src/impl/frame.dart';
import 'package:isar/isar.dart';

part 'src/impl/box_impl.dart';
part 'src/impl/type_registry.dart';
part 'src/box.dart';
part 'src/hive.dart';
