# Encrypted box

Sometimes it is necessary to store data securely on the disk. Hive supports AES-256 encryption out of the box (literally). Bear in mind that encrypted boxes are a little bit slower than regular boxes...

The only thing you need is a 32-bit (8 bytes) encryption key. Hive provides a helper function to generate a secure encryption key using the [Fortuna](https://www.wikiwand.com/en/Fortuna_\(PRNG\)) random number generator:

```dart
var key = Hive.generateSecureKey();
```

Just pass the key when you open a box:

```dart
var encryptedBox = await Hive.box('vaultBox', encryptionKey: key);
```

!> Make sure you store the key securely when your application is closed. With Flutter you can use the [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) or a similar package.

?> It is currently not possible to encrypt a previously unencrypted box or vice versa.