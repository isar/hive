# Encrypted box

Sometimes it is necessary to store data securely on the disk. Hive supports AES-256 encryption out of the box (literally).

The only thing you need is a 256-bit (32 bytes) encryption key. Hive provides a helper function to generate a secure encryption key using the [Fortuna](https://en.wikipedia.org/wiki/Fortuna_\(PRNG\)) random number generator:

```dart
var key = Hive.generateSecureKey();
```

Just pass the key when you open a box:

```dart
var encryptedBox = await Hive.openBox('vaultBox', encryptionKey: key);
```

There is no difference in using an encrypted box.

## Important:

- Only values are encrypted while keys are stored in plaintext.
- Make sure to store the encryption key securely when your application is closed. With Flutter you can use the [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) or a similar package.
- There is no check if the encryption key is correct. If it isn't, there may be unexpected behaviour.