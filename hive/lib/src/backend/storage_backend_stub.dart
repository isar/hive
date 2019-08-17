import 'package:hive/hive.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/hive_impl.dart';

Future<Box> openBoxInternal(
        HiveImpl hive, String name, bool lazy, BoxOptions options) =>
    throw UnsupportedError('Cannot create a box without dart:html or dart:io.');
