import 'dart:async';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

class ChangeNotifier {
  final StreamController<BoxEvent> _streamController;

  ChangeNotifier() : _streamController = StreamController<BoxEvent>.broadcast();

  @visibleForTesting
  ChangeNotifier.debug(this._streamController);

  void notify(String key, dynamic value) {
    _streamController.add(BoxEvent(key, value));
  }

  Stream<BoxEvent> watch({String key}) {
    if (key != null) {
      return _streamController.stream.where((it) => it.key == key);
    } else {
      return _streamController.stream;
    }
  }

  Future close() {
    return _streamController.close();
  }
}
