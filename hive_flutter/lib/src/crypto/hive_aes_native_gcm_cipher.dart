import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
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
/// on Android, iOS, macOS as well as on web using [AesGcm].
///
/// This may highly decrease the delay in the event loop of the Flutter
/// application. A disadvantage is the fact that each computation takes a bit
/// longer than its main-thread equivalent because spawning a new thread
/// takes its time.
class HiveAesNativeGcmCipher extends HiveAesCipher {
  late final List<int> _key;
  final Completer<SecretKey> secretKey = Completer();

  HiveAesNativeGcmCipher(List<int> key)
      : assert(key.length == 32 && key.every((it) => it > 0 || it <= 255),
            'The encryption key has to be a 32 byte (256 bit) array.'),
        _key = key,
        super(key) {
    _algorithm.newSecretKeyFromBytes(_key).then(secretKey.complete);
  }

  /// AES-GCM with 256 bit keys
  AesGcm get _algorithm => AesGcm.with256bits(nonceLength: 16);

  @override
  Future<int> decrypt(Uint8List inp, int inpOff, int inpLength, Uint8List out,
      int outOff) async {
    final bytes = inp.view(inpOff, inpLength);

    /// preparing the [SecretBox] with the range from the [inpOff] in the [inp]
    final secretBox =
        SecretBox.fromConcatenation(bytes, nonceLength: 16, macLength: 16);

    /// decrypting
    final result =
        await _algorithm.decrypt(secretBox, secretKey: await secretKey.future);

    /// save the clear text in the [out]
    out.setRange(outOff, outOff + result.length, result);

    /// return the clear text length as new offset
    return result.length;
  }

  @override
  Future<int> encrypt(Uint8List inp, int inpOff, int inpLength, Uint8List out,
      int outOff) async {
    /// generating new nonce / iv
    final nonce = _algorithm.newNonce();

    /// encrypt the next 16 bytes of the [inp] starting from [inpOff]
    final secretBox = await _algorithm.encrypt(
      inp.view(inpOff, inpLength),
      secretKey: await secretKey.future,
      nonce: nonce,
    );

    assert(secretBox.mac.bytes.length == 16 && secretBox.nonce.length == 16,
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

    return concentration.length;
  }
}
