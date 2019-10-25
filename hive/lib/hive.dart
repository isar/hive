/// Hive is a lightweight and blazing fast key-value store written in pure Dart.
/// It is strongly encrypted using AES-256.
library hive;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:meta/meta.dart';

export 'src/object/hive_object.dart' show HiveObject;

part 'src/annotations/hive_field.dart';
part 'src/annotations/hive_type.dart';
part 'src/binary/binary_reader.dart';
part 'src/binary/binary_writer.dart';
part 'src/box/box.dart';
part 'src/box/lazy_box.dart';
part 'src/object/hive_collection.dart';
part 'src/object/hive_list.dart';
part 'src/query/hive_query.dart';
part 'src/query/hive_results.dart';
part 'src/registry/type_registry.dart';
part 'src/registry/type_adapter.dart';
part 'src/hive_error.dart';
part 'src/hive.dart';

/// Global constant to access Hive.
// ignore: non_constant_identifier_names
final HiveInterface Hive = HiveImpl();
