# Hive

[![Travis](https://img.shields.io/travis/com/leisim/hive/master.svg)](https://travis-ci.com/leisim/hive) [![Codecov](https://img.shields.io/codecov/c/github/leisim/hive.svg)](https://codecov.io/gh/leisim/hive) [![Version](https://img.shields.io/pub/v/hive.svg)](https://pub.dartlang.org/packages/hive) ![Runtime](https://img.shields.io/badge/dart-%3E%3D2.2-brightgreen.svg) ![GitHub license](https://img.shields.io/badge/license-Apache%202-blue.svg)

Hive is a lightweight and blazing fast key/value store written in pure Dart.

It is fun to use and stronly encrypted using AES-256.
Read, write and delete operations only need a single disk access.

**Hive is not ready for production yet**

## Getting Started

### Initialize

Hive needs a directory where it can store its data. Call `Hive.init()` the first time you use Hive.

```dart
Hive.init('path/to/hive');
```

### Open a Box

All of your data is stored in boxes.

```dart
var box = await Hive.box('testBox');
```

You can encrypt a box with one extra line:

```dart
var key = Hive.generateSecureKey();
var box = await Hive.box('encryptedBox', encryptionKey: key);
```

### Read & Write

Hive supports all primitive types, `List`, `Map`, `DateTime`, `Uint8List` and `null`. Any object can be can stored using [TypeAdapters](#typeadapters)

```dart
var dog = Dog(name: 'Nero', age: 4);

await box.put('myDog', dog);

Dog myDog = await box.get('myDog');
```

# Documentation

### Contens
- [Init](#init)
- [Boxes](#boxes)
  - [Open box](#open-box)
  - [Read from box](#read-from-box)
  - [Write to box](#write-to-box)
  - [Has key](#has-key)
  - [Delete key](#delete-key)
  - [Watch changes](#watch-changes)
  - [Close box](#close-box)
- [TypeAdapters](#typeadapters)
  - [Create Adapter](#create-adapter)
  - [Register Adapter](#register-adapter)
- [Encryption](#encryption)
  - [Generate key](#generate-key)
  - [Open encrypted box](#open-encrypted-box)
- [Compactation](#compactation)
- [Migration](#migration)
- [Benchmark](#benchmark)
- [Limitations](#limitations)


## Init

Before you use Hive for the first time, you have to initialize it. Give it a directory where it should store its files. It is recommended to use an empty directory and not to store any other data there. Each box will have it's own `.hive` file in the Hive-home directory.

```dart
Hive.init('path/to/hive');
```

If you use a directory outside your app files, make sure to request runtime permission on iOS and Android.

## Boxes

All data is stored in boxes. A box can be compared to a table in SQL but it does not have a structure and can contain anything.

For a small app, a single box might be enough. For more advanced problems, boxes are a great way to categorize your data.

Boxes can also be encrypted to store sensitive data.

### Open Box

Before you use a box, you have to open it:

```dart
var box = await Hive.box('testBox');
```

If the box is already open, it will be returned immediately. This is a very fast and cheap operation so you don't have to store the box instance.
Otherwise the box will be opened.

Once you obtained a box instance, you can read, write and delete entries.

### Read from box

Reading from a box is almost like reading from a Map:

```dart
String name = await box.get('name');
int age = await box.get('ageInYears');
```

You can even use `[]` to access data:

```dart
DateTime birthday = await box['birthday'];
```

If the key does not exist, `null` is returned. Optionally you can specify a `defaultValue` which will be returned in case the key does not exist.

```dart
double height = await box.get('randomKey', defaultValue: 17.5);
```

### Write to box

Writing is just as easy as reading. All keys have to be ASCII Strings with a max lenght of 255 chars.

```dart
await box.put('name', 'Paul');
await box.put('friends', ['Dave', 'Simon', 'Lisa']);
```

**Important:** Writing `null` is not the same as deleting a value.

### Has key

You can check if the box contains a specific key:

```dart
var exists = await box.has('something');
```

*This operation is really fast. No disk access is needed.*

### Delete key

If you want to change an existing value, you can either override it using `put()` or delete it:

```dart
var deleted = await box.delete('key');
```

If the key does not exist, no disk access is needed and the returned `Future` finishes immediately.

### Watch changes

You can watch a box for changes. This will emit a `BoxEvent` every time an entry in the box is being changed or deleted.

```dart
var subscription = box.watch().listen(
  onData: (BoxEvent event) {
    if (event.deleted) {
      print("Entry with key ${event.key} has been deleted.");
    } else {
      print("Key ${event.key} is now associated with ${event.value}.");
    }
  },
});
```

If you dont want to be notified any more, you can cancel the subscription:

```dart
await subscription.cancel();
```

### Close box

If you don't need a box again, you can close it. All cached keys of the box will be dropped from memory and the box file will be closed after all active read and write operations finished.

It is not recommended to open and close the same box frequently because this leads to unnecessary disk accesses. If you need a box again in the future, just leave it open.

```dart
var box = await Hive.open('myBox');
await box.put('hello', 'world');
await box.close();
```

Before your application exits, you should call `Hive.close()` to close all open boxes.


## TypeAdapters

Hive supports all primitive types, `List`, `Map`, `DateTime`, `Uint8List` and `null`. If you want to store other objects, you have to register a `TypeAdapter` which convert your object from and to binary form.

### Create Adapter

**Important:** Test your custom `TypeAdapter` thoroughly. If it does not work correctly, it may corrupt your box.

It is very easy to implement a `TypeAdapter`. Here is the `DataTimeAdapter` used by Hive internally:

```dart
class DataTimeAdapter extends TypeAdapter<DateTime> {
  @override
  DateTime read(BinaryReader reader) {
    var micros = reader.readInt();
    return DateTime.fromMicrosecondsSinceEpoch(micros);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.microsecondsSinceEpoch);
  }
}
```

The `read()` method is called when your object has to be read from the disk. Use the `BinaryReader` to read all properties of your object. In the above sample it is only an `int` containing `microsecondsSinceEpoch`.<br>
The `write()` method is the same just for writing the object to disk.

**Important:** Make sure, you read properties in the same order you have written them before.

### Register Adapter

When you want Hive to use your `TypeAdapter`, you have to register it. Two things are needed for that: An instance of your adapter and a `typeId`. Every type has a unique `typeId` which is used to find the correct adapter when a value is brought back from disk.
The `typeId`s 0-32 are reserved for primitive and built in types.

You can register `TypeAdapters` for a specific box or globally for all boxes:

```dart
Hive.registerAdapter(MyObjectAdapter(), 33); // Register MyObjectAdapter for all boxes

box.registerAdapter(MyOtherAdapter(), 34); // Register MyOtherAdapter for the box
```

Box adapters always have precedence over global adapters.

**SUPER IMPORTANT:** Make sure to use `typeId`s consistently. Your changes have to be compatible to previous versions of the box.

## Encryption

The box file can be securely encrypted on disk using AES-256 CBC.

### Generate key

You can either generate the encryption key yourself or call `Hive.generateSecureKey()` to generate a key.

Make sure you store the key securely when your application is closed. With Flutter you can use the [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) or a similar package.

### Open encrypted box

To open an encrypted box, pass a 256-bit (32 byte) `encryptionKey`. You have to supply the same encryption key every time you open that box.

```dart
var box = Hive.box('myBox', encryptionKey: key);
```


## Compactation

Hive is an append-only data store. When you change or delete a value, the change is written to the end of the box file. This leads sooner or later to a growing box file. Hive may automatically "compact" your box at any time.

It may benefit the start time of your app if you call `Hive.close(compact: true)` before your app exits to induce compactation  of all boxes manually.


## Migration

Sometimes it may be necessary to change the data in your box fundamentally. When you open a box, you can provide a `version` and `Migrator`.<br>
When the version is higher than the disk version, the migrator is called and you can make changes to the box before it is beign opened.

```dart
Hive.box("myBox", version: 5, migrator: (oldVersion, newVersion, box) async {
  await box.delete("unusedKey");
  await box.put("newKey", 7);
});
```

*Hint: Make sure the migrator can handle all possible version changes*


## Benchmark

Coming soon.


## Limitations

- **HIVE IS NOT READY FOR PRODUCTION YET**
- Keys have to be ASCII Strings with a max length of 255 chars.
- Strings can have a maximum of 65536 **bytes**. Mind that a Unicode chars may be longer than one byte.
- Lists and Maps cannot have more than 65536 elements.
- Only one process can access a box at any time. Bad things happen otherwise.


## Licence

```
Copyright 2019 Simon Leier

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
