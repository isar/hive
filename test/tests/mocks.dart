import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:pointycastle/api.dart';

class HiveMock extends Mock implements HiveImpl {}

class RAFMock extends Mock implements RandomAccessFile {}

class BinaryReaderMock extends Mock implements BinaryReader {}

class BinaryWriterMock extends Mock implements BinaryWriter {}

class BackendMock extends Mock implements StorageBackend {}

class ChangeNotifierMock extends Mock implements ChangeNotifier {}

class SecureRandomMock extends Mock implements SecureRandom {}

class BoxMock extends Mock implements Box {}

class KeystoreMock extends Mock implements Keystore {}

class FileMock extends Mock implements File {}

class HiveObjectMock extends Mock implements HiveObject {}

class HiveListMock extends Mock implements HiveListImpl {}
