/// Hive is a lightweight and blazing fast key/value store written in pure Dart.
library hive;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/hive_instance_impl.dart';
import 'package:meta/meta.dart';

part 'src/binary/binary_reader.dart';
part 'src/binary/binary_writer.dart';
part 'src/registry/type_registry.dart';
part 'src/registry/type_adapter.dart';
part 'src/box.dart';
part 'src/hive_error.dart';
part 'src/hive_instance.dart';

final HiveInstance Hive = HiveInstanceImpl();
