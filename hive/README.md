![logo](https://raw.githubusercontent.com/leisim/hive/master/.github/logo.svg?sanitize=true)

[![Travis](https://img.shields.io/travis/com/leisim/hive/master.svg)](https://travis-ci.com/leisim/hive) [![Codecov](https://img.shields.io/codecov/c/github/leisim/hive.svg)](https://codecov.io/gh/leisim/hive) [![Version](https://img.shields.io/pub/v/hive.svg)](https://pub.dartlang.org/packages/hive) ![GitHub license](https://img.shields.io/badge/license-Apache%202-blue.svg)

Hive is a lightweight and blazing fast key-value store written in pure Dart.

[Go here for documentation](https://leisim.github.io/hive/) 📖<br>
*Not finished yet and may contain typos. Please open pull requests ;)*

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

Just provide an `encryptionKey` to encrypt a box:

```dart
var key = Hive.generateSecureKey();
var box = await Hive.box('secureBox', encryptionKey: key);
```

### Read & Write

Hive supports all primitive types, `List`, `Map`, `DateTime` and `Uint8List`. Any object can be can stored using [TypeAdapters](https://leisim.github.io/hive/#/generate_adapter)

```dart
var dog = Dog(name: 'Nero', age: 4);

await box.put('myDog', dog);

Dog myDog = await box.get('myDog');
```

## Hive ❤️ Flutter

Hive was written with Flutter in mind. It is a perfect fit if you need a lightweight datastore for your app. Here is a sample how that may look like:

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var box = Hive['settings'];

    return Column(
      children: <Widget>[
        SwitchListTile(
          value: box['darkMode'],
          title: Text("Dark Mode"),
          onChanged: (value) async {
            await box.put('darkMode', !box['darkMode']);
            setState({});
          },
        ),
        SwitchListTile(
          value: box['pushMessages'],
          title: Text('Send push messages'),
          onChanged: (value) {
            await box.put('darkMode', !box['darkMode']);
            setState({});
          },
        ),
      ],
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
- [ ] Benchmarks and comparison

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
