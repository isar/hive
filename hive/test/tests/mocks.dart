library hive.test.mocks;

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/object/hive_list_impl.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateMocks([
  HiveObject,
  Box,
  ChangeNotifier,
  StorageBackend,
  Keystore,
  HiveImpl,
  HiveList,
  HiveListImpl,
  RandomAccessFile,
  BinaryReader,
  BinaryWriter,
  File,
  FrameIoHelper,
])
var _mocks;
