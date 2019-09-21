# Hive Documentation

## Add Hive to project
Add the following to your `pubspec.yaml`. Use the latest version instead of `[version]`.

[![Core version](https://img.shields.io/pub/v/hive?label=hive)](https://pub.dev/packages/hive) [![Generator version](https://img.shields.io/pub/v/hive_generator.svg?label=hive_generator)](https://pub.dev/packages/hive_generator) [![Build runner version](https://img.shields.io/pub/v/build_runner.svg?label=build_runner)](https://pub.dev/packages/build_runner)

```yaml
dependencies:
  hive: [version]

dev_dependencies:
  hive_generator: [version]
  build_runner: [version]
```

## Initialize

When your program starts, Hive needs to be initialized. Give it a directory where it can store its files. It is recommended to use an empty directory and not to store any other data there. Each box will have it's own `.hive` file in the Hive-home directory.

```dart
Hive.init('path/to/hive');
```

If you use a directory outside your app files, make sure to request runtime permission on Android.

*In the browser you don't have to call `Hive.init()`.*

## Open a Box

All of your data is stored in boxes.

```dart
var box = await Hive.openBox('testBox');
```

## Read & Write

Hive supports all primitive types, `List`, `Map`, `DateTime` and `Uint8List`. Any object can be can stored using [TypeAdapters](generate_adapter.md)

```dart
box.put('name', 'David');

var name = box.get('name');

print('Name: $name');
```