extension StringX on String {
  bool get isAscii {
    for (var cu in codeUnits) {
      if (cu > 127) return false;
    }
    return true;
  }
}
