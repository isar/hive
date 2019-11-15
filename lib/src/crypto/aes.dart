import 'dart:typed_data';

import 'package:hive/src/crypto/aes_tables.dart';

class AESFastEngine {
  static const rounds = 14;

  List<List<int>> workingKey;

  int subWord(int x) {
    return (sBox[x & 255] & 255 |
        ((sBox[(x >> 8) & 255] & 255) << 8) |
        ((sBox[(x >> 16) & 255] & 255) << 16) |
        sBox[(x >> 24) & 255] << 24);
  }

  int littleEndianToInt(List<int> buffer, int offset) {
    return buffer[offset] |
        buffer[offset + 1] << 8 |
        buffer[offset + 2] << 16 |
        buffer[offset + 3] << 24;
  }

  int intTolittleEndian(int x, List<int> buffer, int offset) {
    return buffer[offset] |
        buffer[offset + 1] << 8 |
        buffer[offset + 2] << 16 |
        buffer[offset + 3] << 24;
  }

  List<List<int>> generateWorkingKey(Uint8List key, bool forEncryption) {
    var w = List.generate(rounds + 1, (_) => List<int>(4));
    var t0 = littleEndianToInt(key, 0);
    var t1 = littleEndianToInt(key, 4);
    var t2 = littleEndianToInt(key, 8);
    var t3 = littleEndianToInt(key, 12);
    var t4 = littleEndianToInt(key, 16);
    var t5 = littleEndianToInt(key, 20);
    var t6 = littleEndianToInt(key, 24);
    var t7 = littleEndianToInt(key, 28);
    w[0] = [t0, t1, t2, t3];
    w[1] = [t4, t5, t6, t7];

    int u, rcon = 1;

    for (var i = 2; i < 14; i += 2) {
      u = subWord(shift(t7, 8)) ^ rcon;
      rcon <<= 1;
      t0 ^= u;
      w[i][0] = t0;
      t1 ^= t0;
      w[i][1] = t1;
      t2 ^= t1;
      w[i][2] = t2;
      t3 ^= t2;
      w[i][3] = t3;
      u = subWord(t3);
      t4 ^= u;
      w[i + 1][0] = t4;
      t5 ^= t4;
      w[i + 1][1] = t5;
      t6 ^= t5;
      w[i + 1][2] = t6;
      t7 ^= t6;
      w[i + 1][3] = t7;
    }

    u = subWord(shift(t7, 8)) ^ rcon;
    t0 ^= u;
    w[14][0] = t0;
    t1 ^= t0;
    w[14][1] = t1;
    t2 ^= t1;
    w[14][2] = t2;
    t3 ^= t2;
    w[14][3] = t3;

    if (!forEncryption) {
      for (var j = 1; j < rounds; j++) {
        for (var i = 0; i < 4; i++) {
          w[j][i] = inv_mcol(w[j][i]);
        }
      }
    }

    return w;
  }

  void encryptBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    var c0 = littleEndianToInt(inp, inpOff) ^ workingKey[0][0];
    var c1 = littleEndianToInt(inp, inpOff + 4) ^ workingKey[0][1];
    var c2 = littleEndianToInt(inp, inpOff + 8) ^ workingKey[0][2];
    var c3 = littleEndianToInt(inp, inpOff + 12) ^ workingKey[0][3];

    int r0, r1, r2, r3;
    var r = 1;
    while (r < rounds - 1) {
      r0 = table0[c0 & 255] ^
          table1[(c1 >> 8) & 255] ^
          table2[(c2 >> 16) & 255] ^
          table3[(c3 >> 24) & 255] ^
          workingKey[r][0];
      r1 = table0[c1 & 255] ^
          table1[(c2 >> 8) & 255] ^
          table2[(c3 >> 16) & 255] ^
          table3[(c0 >> 24) & 255] ^
          workingKey[r][1];
      r2 = table0[c2 & 255] ^
          table1[(c3 >> 8) & 255] ^
          table2[(c0 >> 16) & 255] ^
          table3[(c1 >> 24) & 255] ^
          workingKey[r][2];
      r3 = table0[c3 & 255] ^
          table1[(c0 >> 8) & 255] ^
          table2[(c1 >> 16) & 255] ^
          table3[(c2 >> 24) & 255] ^
          workingKey[r][3];
      r++;
      c0 = table0[r0 & 255] ^
          table1[(r1 >> 8) & 255] ^
          table2[(r2 >> 16) & 255] ^
          table3[(r3 >> 24) & 255] ^
          workingKey[r][0];
      c1 = table0[r1 & 255] ^
          table1[(r2 >> 8) & 255] ^
          table2[(r3 >> 16) & 255] ^
          table3[(r0 >> 24) & 255] ^
          workingKey[r][1];
      c2 = table0[r2 & 255] ^
          table1[(r3 >> 8) & 255] ^
          table2[(r0 >> 16) & 255] ^
          table3[(r1 >> 24) & 255] ^
          workingKey[r][2];
      c3 = table0[r3 & 255] ^
          table1[(r0 >> 8) & 255] ^
          table2[(r1 >> 16) & 255] ^
          table3[(r2 >> 24) & 255] ^
          workingKey[r][3];
      r++;
    }

    r0 = table0[c0 & 255] ^
        table1[(c1 >> 8) & 255] ^
        table2[(c2 >> 16) & 255] ^
        table3[(c3 >> 24) & 255] ^
        workingKey[r][0];
    r1 = table0[c1 & 255] ^
        table1[(c2 >> 8) & 255] ^
        table2[(c3 >> 16) & 255] ^
        table3[(c0 >> 24) & 255] ^
        workingKey[r][1];
    r2 = table0[c2 & 255] ^
        table1[(c3 >> 8) & 255] ^
        table2[(c0 >> 16) & 255] ^
        table3[(c1 >> 24) & 255] ^
        workingKey[r][2];
    r3 = table0[c3 & 255] ^
        table1[(c0 >> 8) & 255] ^
        table2[(c1 >> 16) & 255] ^
        table3[(c2 >> 24) & 255] ^
        workingKey[r][3];
    r++;

    // the final round's table is a simple function of S so we don't use a whole other four tables for it
    c0 = (sBox[r0 & 255] & 255) ^
        ((sBox[(r1 >> 8) & 255] & 255) << 8) ^
        ((sBox[(r2 >> 16) & 255] & 255) << 16) ^
        (sBox[(r3 >> 24) & 255] << 24) ^
        workingKey[r][0];
    c1 = (sBox[r1 & 255] & 255) ^
        ((sBox[(r2 >> 8) & 255] & 255) << 8) ^
        ((sBox[(r3 >> 16) & 255] & 255) << 16) ^
        (sBox[(r0 >> 24) & 255] << 24) ^
        workingKey[r][1];
    c2 = (sBox[r2 & 255] & 255) ^
        ((sBox[(r3 >> 8) & 255] & 255) << 8) ^
        ((sBox[(r0 >> 16) & 255] & 255) << 16) ^
        (sBox[(r1 >> 24) & 255] << 24) ^
        workingKey[r][2];
    c3 = (sBox[r3 & 255] & 255) ^
        ((sBox[(r0 >> 8) & 255] & 255) << 8) ^
        ((sBox[(r1 >> 16) & 255] & 255) << 16) ^
        (sBox[(r2 >> 24) & 255] << 24) ^
        workingKey[r][3];

    intTolittleEndian(c0, out, outOff);
    intTolittleEndian(c1, out, outOff + 4);
    intTolittleEndian(c2, out, outOff + 8);
    intTolittleEndian(c3, out, outOff + 16);
  }

  void decryptBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    var c0 = littleEndianToInt(inp, inpOff) ^ workingKey[rounds][0];
    var c1 = littleEndianToInt(inp, inpOff + 4) ^ workingKey[rounds][1];
    var c2 = littleEndianToInt(inp, inpOff + 8) ^ workingKey[rounds][2];
    var c3 = littleEndianToInt(inp, inpOff + 12) ^ workingKey[rounds][3];

    int r0, r1, r2, r3;
    var r = rounds - 1;
    while (r > 1) {
      r0 = table0Inv[c0 & 255] ^
          table1Inv[(c3 >> 8) & 255] ^
          table2Inv[(c2 >> 16) & 255] ^
          table3Inv[(c1 >> 24) & 255] ^
          workingKey[r][0];
      r1 = table0Inv[c1 & 255] ^
          table1Inv[(c0 >> 8) & 255] ^
          table2Inv[(c3 >> 16) & 255] ^
          table3Inv[(c2 >> 24) & 255] ^
          workingKey[r][1];
      r2 = table0Inv[c2 & 255] ^
          table1Inv[(c1 >> 8) & 255] ^
          table2Inv[(c0 >> 16) & 255] ^
          table3Inv[(c3 >> 24) & 255] ^
          workingKey[r][2];
      r3 = table0Inv[c3 & 255] ^
          table1Inv[(c2 >> 8) & 255] ^
          table2Inv[(c1 >> 16) & 255] ^
          table3Inv[(c0 >> 24) & 255] ^
          workingKey[r][3];
      r--;
      c0 = table0Inv[r0 & 255] ^
          table1Inv[(r3 >> 8) & 255] ^
          table2Inv[(r2 >> 16) & 255] ^
          table3Inv[(r1 >> 24) & 255] ^
          workingKey[r][0];
      c1 = table0Inv[r1 & 255] ^
          table1Inv[(r0 >> 8) & 255] ^
          table2Inv[(r3 >> 16) & 255] ^
          table3Inv[(r2 >> 24) & 255] ^
          workingKey[r][1];
      c2 = table0Inv[r2 & 255] ^
          table1Inv[(r1 >> 8) & 255] ^
          table2Inv[(r0 >> 16) & 255] ^
          table3Inv[(r3 >> 24) & 255] ^
          workingKey[r][2];
      c3 = table0Inv[r3 & 255] ^
          table1Inv[(r2 >> 8) & 255] ^
          table2Inv[(r1 >> 16) & 255] ^
          table3Inv[(r0 >> 24) & 255] ^
          workingKey[r][3];
      r--;
    }

    r0 = table0Inv[c0 & 255] ^
        table1Inv[(c3 >> 8) & 255] ^
        table2Inv[(c2 >> 16) & 255] ^
        table3Inv[(c1 >> 24) & 255] ^
        workingKey[r][0];
    r1 = table0Inv[c1 & 255] ^
        table1Inv[(c0 >> 8) & 255] ^
        table2Inv[(c3 >> 16) & 255] ^
        table3Inv[(c2 >> 24) & 255] ^
        workingKey[r][1];
    r2 = table0Inv[c2 & 255] ^
        table1Inv[(c1 >> 8) & 255] ^
        table2Inv[(c0 >> 16) & 255] ^
        table3Inv[(c3 >> 24) & 255] ^
        workingKey[r][2];
    r3 = table0Inv[c3 & 255] ^
        table1Inv[(c2 >> 8) & 255] ^
        table2Inv[(c1 >> 16) & 255] ^
        table3Inv[(c0 >> 24) & 255] ^
        workingKey[r][3];

    // the final round's table is a simple function of Si so we don't use a whole other four tables for it
    c0 = (sBoxInv[r0 & 255] & 255) ^
        ((sBoxInv[(r3 >> 8) & 255] & 255) << 8) ^
        ((sBoxInv[(r2 >> 16) & 255] & 255) << 16) ^
        (sBoxInv[(r1 >> 24) & 255] << 24) ^
        workingKey[0][0];
    c1 = (sBoxInv[r1 & 255] & 255) ^
        ((sBoxInv[(r0 >> 8) & 255] & 255) << 8) ^
        ((sBoxInv[(r3 >> 16) & 255] & 255) << 16) ^
        (sBoxInv[(r2 >> 24) & 255] << 24) ^
        workingKey[0][1];
    c2 = (sBoxInv[r2 & 255] & 255) ^
        ((sBoxInv[(r1 >> 8) & 255] & 255) << 8) ^
        ((sBoxInv[(r0 >> 16) & 255] & 255) << 16) ^
        (sBoxInv[(r3 >> 24) & 255] << 24) ^
        workingKey[0][2];
    c3 = (sBoxInv[r3 & 255] & 255) ^
        ((sBoxInv[(r2 >> 8) & 255] & 255) << 8) ^
        ((sBoxInv[(r1 >> 16) & 255] & 255) << 16) ^
        (sBoxInv[(r0 >> 24) & 255] << 24) ^
        workingKey[0][3];

    intTolittleEndian(c0, out, outOff);
    intTolittleEndian(c1, out, outOff + 4);
    intTolittleEndian(c2, out, outOff + 8);
    intTolittleEndian(c3, out, outOff + 16);
  }
}
