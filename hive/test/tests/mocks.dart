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

@GenerateMocks([], customMocks: [
  MockSpec<Box>(returnNullOnMissingStub: true),
  MockSpec<ChangeNotifier>(returnNullOnMissingStub: true),
  MockSpec<StorageBackend>(returnNullOnMissingStub: true),
  MockSpec<Keystore>(returnNullOnMissingStub: true),
  MockSpec<HiveImpl>(returnNullOnMissingStub: true),
  MockSpec<HiveList>(returnNullOnMissingStub: true),
  MockSpec<HiveListImpl>(returnNullOnMissingStub: true),
  MockSpec<RandomAccessFile>(returnNullOnMissingStub: true),
  MockSpec<BinaryReader>(returnNullOnMissingStub: true),
  MockSpec<BinaryWriter>(returnNullOnMissingStub: true),
  MockSpec<File>(returnNullOnMissingStub: true),
  MockSpec<FrameIoHelper>(returnNullOnMissingStub: true),
])
// ignore: prefer_typing_uninitialized_variables, unused_element
var _mocks;

class TestHiveObject extends HiveObject {}
