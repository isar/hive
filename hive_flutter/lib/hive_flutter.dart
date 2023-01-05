library hive_flutter;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' if (dart.library.html) 'src/stub/path.dart'
    as path_helper;
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) 'src/stub/path_provider.dart';

export 'package:hive/hive.dart';
export 'src/crypto/hive_aes_native_cbc_cipher.dart';
export 'src/crypto/hive_aes_native_gcm_cipher.dart';

part 'src/box_extensions.dart';
part 'src/hive_extensions.dart';
part 'src/watch_box_builder.dart';
