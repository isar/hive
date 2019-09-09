## Getting Started

### Add Hive to project
Add the following to your `pubspec.yaml`. Use the latest version instead of `[version]`.

[![Core version](https://img.shields.io/pub/v/hive?label=hive)](https://pub.dev/packages/hive) [![Generator version](https://img.shields.io/pub/v/hive_generator.svg?label=hive_generator)](https://pub.dev/packages/hive_generator) [![Build runner version](https://img.shields.io/pub/v/build_runner.svg?label=build_runner)](https://pub.dev/packages/build_runner)

```yaml
dependencies:
  hive: [version]

dev_dependencies:
  hive_generator: [version]
  build_runner: [version]
```

### Initialize

Hive needs a directory where it can store its data. Call `Hive.init()` the first time you use Hive.

```dart
Hive.init('path/to/hive');
```

In the browser you don't have to call `Hive.init()`.

### Open a Box

All of your data is stored in boxes.

```dart
var box = await Hive.openBox('testBox');
```

### Read & Write

Hive supports all primitive types, `List`, `Map`, `DateTime` and `Uint8List`. Any object can be can stored using [TypeAdapters](https://leisim.github.io/hive/#/generate_adapter)

```dart
box.put('name', 'David');

var name = box.get('myDog');

print('Name: $name');
```