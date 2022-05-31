import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_flutter/src/crypto/extensions.dart';

/// Multi-threaded cipher. Uses AES256 GCM
///
/// **IMPORTANT**: Setup required:
/// https://pub.dev/packages/cryptography_flutter#getting-started
///
/// 1. add dependency to pubspec.yaml
///
/// ```yaml
/// dependencies:
///   cryptography_flutter: ^2.0.2
/// ```
///
/// 2. enable native implementations
///
/// ```dart
/// import 'package:cryptography_flutter/cryptography_flutter.dart';
///
/// void main() {
///   // Enable Flutter cryptography
///   FlutterCryptography.enable();
///
///   // ....
/// }
/// ```
///
/// This implementation extends the [HiveCipher] with native AES implementations
/// on Android, iOS, macOS as well as on web using either [AesCbc] or [AesGcm].
///
/// This may highly decrease the delay in the event loop of the Flutter
/// application. A disadvantage is the fact that each computation takes a bit
/// longer than its main-thread equivalent because spawning a new thread
/// takes its time.
class HiveAesNativeCipher extends HiveAesCipher {
  late final List<int> _key;

  /// specify the preferred AES modes per platform
  final AesPlatformConfiguration platformConfiguration;

  final Completer<SecretKey> secretKey = Completer();

  HiveAesNativeCipher(
    List<int> key, {
    this.platformConfiguration = AesPlatformConfiguration.auto,
  })  : assert(key.length == 32 && key.every((it) => it > 0 || it <= 255),
            'The encryption key has to be a 32 byte (256 bit) array.'),
        _key = key,
        super(key) {
    _algorithm.newSecretKeyFromBytes(_key).then(secretKey.complete);
  }

  /// AES-GCM with 256 bit keys
  Cipher get _algorithm => platformConfiguration.algorithm;

  @override
  Future<int> decrypt(Uint8List inp, int inpOff, int inpLength, Uint8List out,
      int outOff) async {
    final algorithm = _algorithm;

    print(algorithm.runtimeType);

    /// preparing the [SecretBox] with the range from the [inpOff] in the [inp]
    final secretBox = SecretBox.fromConcatenation(
      inp.view(inpOff, inpLength),
      nonceLength: 16,
      macLength: algorithm is AesCbc ? 0 : 16,
    );

    /// decrypting
    final result =
        await algorithm.decrypt(secretBox, secretKey: await secretKey.future);

    /// save the clear text in the [out]
    out.setRange(outOff, outOff + result.length, result);

    /// return the clear text length as new offset
    return result.length;
  }

  @override
  Future<int> encrypt(
    Uint8List inp,
    int inpOff,
    int inpLength,
    Uint8List out,
    int outOff,
  ) async {
    final algorithm = _algorithm;

    /// generating new nonce / iv
    final nonce = algorithm.newNonce();

    /// encrypt the next [inpLength] bytes of the [inp] starting from [inpOff]
    final secretBox = await algorithm.encrypt(
      inp.view(inpOff, inpLength),
      secretKey: await secretKey.future,
      nonce: nonce,
    );

    assert(
        secretBox.mac.bytes.length == (algorithm is AesCbc ? 0 : 16) &&
            secretBox.nonce.length == 16,
        'The AesGcm nonce / iv and mac should be 16 bytes long.');

    /// concentrating the encrypted text, nonce / iv and mac
    final concentration = secretBox.concatenation();

    /// save the encrypted bytes in the [out]
    final outOffset = outOff + concentration.length;
    if (outOffset > out.length) {
      final previousOut = Uint8List.fromList(out);
      out = Uint8List(outOffset)..setRange(0, previousOut.length, previousOut);
    }
    out.setRange(outOff, outOffset, concentration);

    print('Nonce: ${nonce.length}, Mac: ${secretBox.mac.bytes.length}');
    print('Diff: ${concentration.length - inpLength}');
    return concentration.length;
  }
}

/// configures which AES mode to use
///
/// The [package:cryptography] supports different modes with hardware
/// acceleration. Depending on the platform running on, support differs.
class AesPlatformConfiguration {
  /// the mode to use on Android
  final SupportedModes? android;

  /// the mode to use on iOS and macOS
  final SupportedModes? apple;

  /// the mode to use on web
  final SupportedModes? web;

  /// the mode to use on any non-native platform
  final SupportedModes? native;

  const AesPlatformConfiguration(
      {this.android, this.apple, this.web, this.native});

  /// automatically select best AES mode
  ///
  /// Will result in
  ///   - AES CBC on Android, Dart native and web
  ///   - AES GCM on iOS and macOS
  static const auto = AesPlatformConfiguration();

  /// uses AES CBC on all platforms
  ///
  /// Results in slower operations on Apple platforms
  static const cbc = AesPlatformConfiguration(
    android: SupportedModes.cbc,
    apple: SupportedModes.cbc,
    web: SupportedModes.cbc,
    native: SupportedModes.cbc,
  );

  /// uses AES CBC on all platforms
  ///
  /// Runs accelerated on all platforms
  static const gcm = AesPlatformConfiguration(
    android: SupportedModes.gcm,
    apple: SupportedModes.gcm,
    web: SupportedModes.gcm,
    native: SupportedModes.gcm,
  );

  Cipher get algorithm {
    if (kIsWeb) {
      return _algorithmByMode(web ?? SupportedModes.cbc);
    } else if (Platform.isAndroid) {
      return _algorithmByMode(android ?? SupportedModes.cbc);
    } else if (Platform.isIOS && Platform.isMacOS) {
      return _algorithmByMode(android ?? SupportedModes.gcm);
    } else {
      return _algorithmByMode(native ?? SupportedModes.cbc);
    }
  }

  Cipher _algorithmByMode(SupportedModes mode) {
    switch (mode) {
      case SupportedModes.cbc:
        return AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);

      case SupportedModes.gcm:
        return AesGcm.with256bits(nonceLength: 16);
    }
  }
}

/// helper for the supported AES modes
enum SupportedModes {
  cbc,
  gcm,
}
