import 'dart:typed_data';

import 'package:hive/src/util/extensions.dart';
import 'package:meta/meta.dart';

const _mask32 = 0xffffffff;

const List<int> _noise = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

// Helper functions as defined in http://tools.ietf.org/html/rfc6234
int _add32(int x, int y) => (x + y) & _mask32;
int _rotr32(int n, int x) => (x >> n) | ((x << (32 - n)) & _mask32);
int _ch(int x, int y, int z) => (x & y) ^ ((~x & _mask32) & z);
int _maj(int x, int y, int z) => (x & y) ^ (x & z) ^ (y & z);
int _bsig0(int x) => _rotr32(2, x) ^ _rotr32(13, x) ^ _rotr32(22, x);
int _bsig1(int x) => _rotr32(6, x) ^ _rotr32(11, x) ^ _rotr32(25, x);
int _ssig0(int x) => _rotr32(7, x) ^ _rotr32(18, x) ^ (x >> 3);
int _ssig1(int x) => _rotr32(17, x) ^ _rotr32(19, x) ^ (x >> 10);

/**
 * SHA256 hash function implementation.
 * 
 * Taken from crypto/src/sha256.dart with changes to support
 * bitcoin mining.
 */
class Sha256 {
  //final Uint32List _digest;

  /// The sixteen words from the original chunk, extended to 64 words.
  ///
  /// This is an instance variable to avoid re-allocating, but its data isn't
  /// used across invocations of [updateHash].
  static final _extended = Uint32List(64);

  static final _chunk = Uint32List(16);

  // Initial value of the hash parts. First 32 bits of the fractional parts
  // of the square roots of the first 8 prime numbers.
  static const _I = [
    //
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ];

  static Uint8List compute(Uint8List bytes) {
    var bytesLen = 1;
    var paddingLen = (512 + 448 - (bytesLen % 512 + 1)) % 512;

    var digest = Uint32List.fromList(_I);

    var chunk = _chunk;
    var offset = 0;

    bytes.buffer.asUint32List();

    while (offset + 64 < bytesLen) {
      updateHash(digest, _fillChunk(bytes, offset));
      offset += 64;
    }
  }

  static Uint32List _fillChunk(Uint8List inp, int inpOffset) {
    var chunk = _chunk;
    for (var i = 0; i < 16; i++) {
      chunk[i] = inp.readUint32(inpOffset + i * 4);
    }
    return chunk;
  }

  @visibleForTesting
  static void updateHash(Uint32List digest, Uint32List chunk) {
    assert(chunk.length == 16);

    var extended = _extended;

    // Prepare message schedule.
    for (var i = 0; i < 16; i++) {
      extended[i] = chunk[i];
    }
    for (var i = 16; i < 64; i++) {
      extended[i] = _add32(
        _add32(_ssig1(extended[i - 2]), extended[i - 7]),
        _add32(_ssig0(extended[i - 15]), extended[i - 16]),
      );
    }

    // Shuffle around the bits.
    var a = digest[0];
    var b = digest[1];
    var c = digest[2];
    var d = digest[3];
    var e = digest[4];
    var f = digest[5];
    var g = digest[6];
    var h = digest[7];

    for (var i = 0; i < 64; i++) {
      var temp1 = _add32(
        _add32(h, _bsig1(e)),
        _add32(_ch(e, f, g), _add32(_noise[i], extended[i])),
      );
      var temp2 = _add32(_bsig0(a), _maj(a, b, c));
      h = g;
      g = f;
      f = e;
      e = _add32(d, temp1);
      d = c;
      c = b;
      b = a;
      a = _add32(temp1, temp2);
    }

    // Update hash values after iteration.
    digest[0] = _add32(a, digest[0]);
    digest[1] = _add32(b, digest[1]);
    digest[2] = _add32(c, digest[2]);
    digest[3] = _add32(d, digest[3]);
    digest[4] = _add32(e, digest[4]);
    digest[5] = _add32(f, digest[5]);
    digest[6] = _add32(g, digest[6]);
    digest[7] = _add32(h, digest[7]);
  }
}
