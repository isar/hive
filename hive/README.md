<img src="https://raw.githubusercontent.com/leisim/hive/master/.github/logo_transparent.svg?sanitize=true" width="350px">

[![Travis](https://img.shields.io/travis/com/leisim/hive/master.svg)](https://travis-ci.com/leisim/hive) [![Codecov](https://img.shields.io/codecov/c/github/leisim/hive.svg)](https://codecov.io/gh/leisim/hive) [![Core version](https://img.shields.io/pub/v/hive?label=hive)](https://pub.dev/packages/hive) [![Flutter version](https://img.shields.io/pub/v/hive_flutter.svg?label=hive_flutter)](https://pub.dev/packages/hive_flutter) [![Generator version](https://img.shields.io/pub/v/hive_generator.svg?label=hive_generator)](https://pub.dev/packages/hive_generator)

Hive is a lightweight and blazing fast key-value store written in pure Dart. Inspired by [Bitcask](https://en.wikipedia.org/wiki/Bitcask).

- [Documentation](https://leisim.github.io/hive/) 📖
- [Frequently Asked Questions](https://leisim.github.io/hive/#/faq) 🙋
- [Flutter Web demo](https://leisim.github.io/hive/demo) 🕸️
- [Samples](https://github.com/leisim/hive/tree/master/examples) 🔥

*Hive is not ready for production yet. I'm working hard on a stable version.*

## Features

### Blazing Fast ⚡
- More than twice the speed of other datastores
- Binary data format

### Simple to use ❤️
- Supports all types
- Strong encryption built in
- Runs on desktop, mobile & in browser

### Lightweight 🎈
- Small runtime
- **NO** native dependencies


## Benchmark

|Read	1000 entries |Write 1000 entries|
|:------------:|:------------:|
|	![](https://raw.githubusercontent.com/leisim/hive/master/.github/benchmark_read.png) |	![](https://raw.githubusercontent.com/leisim/hive/master/.github/benchmark_write.png) |
| SharedPreferences is on par with Hive when it comes to read performance. SQLite performs much worse. | Hive greatly outperforms SQLite and SharedPreferences when it comes to writing or deleting. |

This benchmark was performed on a Oneplus 6T with Android Q. All entries are read and written one after another. You can [run the benchmark yourself](https://github.com/leisim/hive_benchmark).

## Getting Started

### Initialize

Hive needs a directory where it can store its data. Call `Hive.init()` the first time you use Hive.

```dart
Hive.init('path/to/hive');
```

In the browser you don't have to call `init()`.

### Open a Box

All of your data is stored in boxes.

```dart
var box = await Hive.openBox('testBox');
```

Just provide an `encryptionKey` to encrypt a box:

```dart
var key = Hive.generateSecureKey();
var box = await Hive.openBox('secureBox', encryptionKey: key);
```

### Read & Write

Hive supports all primitive types, `List`, `Map`, `DateTime` and `Uint8List`. Any object can be can stored using [TypeAdapters](https://leisim.github.io/hive/#/generate_adapter)

```dart
var dog = Dog(name: 'Nero', age: 4);

box.put('myDog', dog);

Dog myDog = box.get('myDog');
```

## Hive ❤️ Flutter

Hive was written with Flutter in mind. It is a perfect fit if you need a lightweight datastore for your app. Here is a sample how that may look like:

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HiveBuilder.openBox(
      openBox: () {
        return Hive.openBox('settings');
      },
      builder: (context, box) {
        return Switch(
          value: box.get('darkMode'),
          onChanged: (val) {
            box.put('darkMode', val);
          }
        )
      },
      child: Center(
        // Shown when app starts until Hive is ready
        child: Text('Please wait...'), 
      ),
    );
  }
}
```

Boxes are cached and therefore fast enough to be used directly in the `build()` method of Flutter widgets.

## Todo

The work on Hive has just started. If you want to contribute, it would be amazing if you helped me with one of these:

- [x] Good test coverage
- [ ] Many examples, especially for Flutter
- [ ] Finalize API
- [ ] Improve documentation
- [ ] Write binary format spec
- [ ] Even more tests
- [x] Benchmarks and comparison

### Licence

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
