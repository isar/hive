import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:meta/meta.dart';

class ChangeNotifier {
  final StreamController<BoxEvent> _streamController;

  ChangeNotifier() : _streamController = StreamController<BoxEvent>.broadcast();

  @visibleForTesting
  ChangeNotifier.debug(this._streamController);

  void notify(Frame frame) {
    _streamController.add(BoxEvent(frame.key, frame.value, frame.deleted));
  }

  Stream<BoxEvent> watch({dynamic key}) {
    if (key != null) {
      return _streamController.stream.where((it) => it.key == key);
    } else {
      return _streamController.stream;
    }
  }

  Future<void> close() {
    return _streamController.close();
  }
}
