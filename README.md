<p align="center">
  <img src="https://raw.githubusercontent.com/hivedb/hive/master/.github/logo_transparent.svg?sanitize=true" width="350px">
</p>
<h2 align="center">Fast, Enjoyable & Safe NoSQL Database</h2>

[![Dart CI](https://github.com/hivedb/hive/workflows/Dart%20CI/badge.svg)](https://github.com/hivedb/hive/actions) [![Codecov](https://img.shields.io/codecov/c/github/hivedb/hive.svg)](https://codecov.io/gh/hivedb/hive) [![Core version](https://img.shields.io/pub/v/hive?label=hive)](https://pub.dev/packages/hive)

Hive is an embedded key-value database written in pure Dart. It provides an easy-to-use API to persist and retrieve Dart objects. Inspired by [Bitcask](https://en.wikipedia.org/wiki/Bitcask).

### [Documentation](https://docs.hivedb.dev/) 📖

### Flutter Web Demos 🕸️
- [Counter](https://hivedb.github.io/hive/demos/counter)
- [Sketchpad](https://hivedb.github.io/hive/demos/sketchpad)
- [Todo App](https://hivedb.github.io/hive/demos/todo)

## Features

- 🚀 Mobile, Desktop, & Browser Support
- ⚡ Great Performance (see [benchmark](#benchmark))
- ❤️ Simple, Powerful, & Intuitive API
- 🔒 Strong Encryption built in
- 🎈 **NO** Native Dependencies
- 🔋 Batteries Included


## Getting Started
Check out the [Quick Start](https://docs.hivedb.dev) documentation to get started.

## Usage

You can use Hive just like a map. It is not necessary to await `Futures`.

```dart
var box = Hive.box('myBox');

box.put('name', 'David');

var name = box.get('name');

print('Name: $name');
```

## Store objects

Hive not only supports primitives, lists and maps but also any Dart object you like. You need to generate a type adapter before you can store objects.

```dart
@HiveType(typeId: 0)
class Person extends HiveObject {

  @HiveField(0)
  String name;

  @HiveField(1)
  int age;
}
```

Extending `HiveObject` is optional but it provides handy methods like `save()` and `delete()`.

```dart
var box = await Hive.openBox('myBox');

var person = Person()
  ..name = 'Dave'
  ..age = 22;
box.add(person);

print(box.getAt(0)); // Dave - 22

person.age = 30;
person.save();

print(box.getAt(0)) // Dave - 30
```

## Hive ❤️ Flutter
Hive was written with Flutter in mind. It is a perfect fit if you need a lightweight datastore for your app. After adding the required dependencies and initializing Hive, you can use Hive in your project:

```dart
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, widget) {
        return Switch(
          value: box.get('darkMode'),
          onChanged: (val) {
            box.put('darkMode', val);
          }
        );
      },
    );
  }
}
```

Boxes are cached and therefore fast enough to be used directly in the `build()` method of Flutter widgets.


## Benchmark

|Read	1000 entries |Write 1000 entries|
|:------------:|:------------:|
|	![](https://raw.githubusercontent.com/hivedb/hive/master/.github/benchmark_read.png) |	![](https://raw.githubusercontent.com/hivedb/hive/master/.github/benchmark_write.png) |
| SharedPreferences is on par with Hive when it comes to read performance. SQLite performs much worse. | Hive greatly outperforms SQLite and SharedPreferences when it comes to writing or deleting. |

This benchmark was performed on a Oneplus 6T with Android Q. All entries are read and written one after another. You can [run the benchmark yourself](https://github.com/hivedb/hive_benchmark).

*Take this benchmark with a grain of salt it is very hard to compare databases objectively since they werde made for different putposes.*


## Todo

The work on Hive has just started. If you want to contribute, it would be amazing if you helped me with one of these:

- [x] Good test coverage
- [x] Many examples, especially for Flutter
- [x] Benchmarks and comparison
- [x] Finalize API
- [x] Even more tests
- [ ] Queries
- [ ] Improve documentation
- [ ] Write binary format spec
- [ ] You can never have enough tests

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
