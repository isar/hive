<p align="center">
  <img src="https://raw.githubusercontent.com/hivedb/hive/master/.github/logo_transparent.svg?sanitize=true" width="350px">
</p>
<h2 align="center">Fast, Enjoyable & Secure NoSQL Database</h2>

[![GitHub Workflow Status (branch)](https://img.shields.io/github/actions/workflow/status/hivedb/hive/test.yml?label=tests&labelColor=333940&logo=github)](https://github.com/hivedb/hive/actions)
[![Codecov branch](https://img.shields.io/codecov/c/github/hivedb/hive/nndb?labelColor=333940&logo=codecov&logoColor=white)](https://codecov.io/gh/hivedb/hive)
[![Pub Version](https://img.shields.io/pub/v/hive?label=pub.dev&labelColor=333940&logo=dart)](https://pub.dev/packages/hive)
[![GitHub](https://img.shields.io/github/license/hivedb/hive?color=%23007A88&labelColor=333940&logo=apache)](https://github.com/hivedb/hive/blob/master/LICENSE)

Hive is a lightweight and blazing-fast key-value database made for Flutter and Dart.

## Features

- 🚀 Cross platform: mobile, desktop, browser
- ⚡ Great performance
- ❤️ Simple, powerful, & intuitive API
- 🔒 Strong encryption built in
- 🎈 Resource friendly
- 🍿 Multi-isolate support
- 🔋 Batteries included

## Quick Start

#### 1️⃣ Add dependencies

Add `hive` and `path_provider` to your `pubspec.yaml` file.

```yaml
dependencies:
  hive: ^4.0.0
  path_provider: ^2.1.0
```

`path_provider` is used to find a valid location to store the database.

#### 2️⃣ Set the default directory

This is where Hive should store its data.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Hive.defaultDirectory = dir.path;

  // ...
}
```

#### 3️⃣ Start using Hive

You're ready to go! Have fun using Hive 🐝

```dart
import 'package:hive/hive.dart';

final myBox = Hive.box();
myBox.put('name', 'David');

final name = myBox.get('name');
print('Name: $name');
```

## 📒 Documentation

All data stored in Hive is organized in boxes. A box can be compared to a table in SQL, but it does not have a structure and can contain anything.

For a small app, a single box might be enough. For more advanced problems, boxes are a great way to organize your data. Boxes can also be encrypted to store sensitive data.

### 🗃️ Opening Boxes

Opening a box is simple:

```dart
final box = Hive.box(name: 'myBox');
```

When you call `Hive.box(name: 'myBox')` for the first time with a given name, Hive will create a new box. If you call it again with the same name, Hive will return the already existing box. You can also use `Hive.box()` without a name. In this case, Hive will return the default box.

There are optional parameters you can pass to `Hive.box()`:

| Parameter       | Description                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------ |
| `name`          | The name of the box                                                                              |
| `directory`     | The path where the box should be stored. If not specified, Hive will use the `defaultDirectory`. |
| `encryptionKey` | If provided, the box will be encrypted and can only be opened if the same key is provided again. |
| `maxSizeMiB`    | The maximum size of the box in MiB. Try to use a small value.                                    |

### 🌂 Closing Boxes

It is not recommended to close boxes if they are still used at a later time. However if the user logs out of your app, you might want to close your boxes:

To close a single box just call `box.close()`. To close all boxes use `Hive.closeAllBoxes()`. Sometimes you may want to close a box and delete all of its data. You can do this by calling `box.deleteFromDisk()` or `Hive.deleteAllBoxesFromDisk()`.

### ✏️ Inserting data

At its core, a box is just a key-value store. String keys are mapped to arbitrary primitive values. You can think of a box as a persisted `Map<String, dynamic>`.

```dart
final box = Hive.box();
box.put('theme', 'dark');
box.put('isLoggedIn', true);
box.put('brightness', 22.7);
```

If a specific key already exists, the value will be overwritten. You can also store lists and maps of primitives:

```dart
box.put('list', [1, 2, 3]);
box.put('map', {'name': 'Dave', 'age': 22});
```

There is an alternative syntax for storing values that is more similar to a `Map`:

```dart
box['theme'] = 'dark';
box['isLoggedIn'] = true;
box['brightness'] = 22.7;
```

To store multiple values at once, you can use `box.putAll()`:

```dart
box.putAll({'theme': 'dark', 'brightness': 22.7});
```

### 🤓 Reading data

To read data from a box, you can use `box.get()` and `box.getAll()`. If a key does not exist, `box.get()` will return `null`. You can also specify a default value:

```dart
final themeBox = Hive.box(name: 'theme');
final brightness = themeBox.get('brightness');
final fontSize = themeBox.get('fontSize', defaultValue: 14.0);
```

Similar to `box.put()`, you can also use the `[]` operator to read values:

```dart
final brightness = themeBox['brightness'];
final fontSize = themeBox['fontSize'] ?? 14.0;
```

### 🧹 Deleting data

To delete a single value, you can use `box.delete()`:

```dart
box.delete('theme');
```

### 🪄 Using Boxes like Lists

Previously we treated boxes like maps. However, you can also use them like lists:

```dart
final box = Hive.box();

box.add('value1');
box.add('value2');

print(box.getAt(0)); // value1
print(box.getAt(1)); // value2
```

Just like in lists, index-based operations will throw an error if the index is out of bounds:

```dart
final box = Hive.box();
box.add('value1');
print(box.getAt(1)); // This will throw an error
```

Even if we insert a key-value pair we can still access the values by index.

```dart
final box = Hive.box();

box.add('value1');
box.put('key', 'value2');
box.add('value3');

print(box.getAt(0)); // value1
print(box.getAt(1)); // value2
print(box.getAt(2)); // value3
```

Of course, we can also use the `[]` operator in combination with indexes :

```dart
final box = Hive.box();

box.add('value1');
print(box[0]); // value1

box[0] = 'value2';
box[1] = 'value3'; // This will throw an error
```

### 💃 Type safety

Boxes have an optional generic type parameter. This allows you to store only values of a specific type in a box:

```dart
final box = Hive.box<String>(name: 'myStringBox');
box.put('key1', 'value1');
box.put('key2', 'value2');
box.put('key3', 777); // This will throw an error
```

### 👾 Non-primitive Objects

Hive not only supports primitives, lists and maps but also any Dart object you like. Your object just needs a `.fromJson()` and `.toJson()` method:

```dart
class Person {
  Person({required this.name, required this.age});

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    name: json['name'] as String,
    age: json['age'] as int,
  );

  final String name;

  final int age;

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
  };
}
```

When initializing Hive you need to register your class:

```dart
Hive.registerAdapter('Person', Person.fromJson);
```

Now you can store `Person` objects in your boxes:

```dart
final box = Hive.box();

var person = Person()
  ..name = 'Dave'
  ..age = 22;
box.put('dave', person);

print(box.get('dave')); // Dave - 22
```

### 🪢 Transactions

Transactions are an efficient way to update multiple values at once. They are also useful if you want to make sure that a Box is not changed by other code while you are working with it.

```dart
final box = Hive.box();

box.write(() {
  box.put('key1', 'value1');
  box.put('key2', 'value2');
  box.put('key3', 'value3');
});

box.read(() {
  box.get('key1');
});
```

Changes made in a transaction are always atomic. Either all changes are applied or none of them. So if an error occurs during a transaction, the box will not be changed.

```dart
final box = Hive.box();
box.put('counter', 5);

box.write(() {
  box.put('counter', 6);
  throw Exception('Oh no!!!');
});

print(box.get('counter')); // 5
```

### 🧑‍⚖️ License

```
Copyright 2023 Simon Choi

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
