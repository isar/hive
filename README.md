<p align="center">
  <img src="https://raw.githubusercontent.com/hivedb/hive/master/.github/logo_transparent.svg?sanitize=true" width="350px">
</p>
<h2 align="center">Fast, Enjoyable & Secure NoSQL Database</h2>

<p align="center">
  <a href="https://pub.dev/packages/hive">
    <img src="https://img.shields.io/pub/v/hive?label=pub.dev&labelColor=333940&logo=dart">
  </a>
  <a href="https://github.com/isar/hive/actions/workflows/test.yaml">
    <img src="https://img.shields.io/github/actions/workflow/status/isar/hive/test.yaml?branch=main&label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://app.codecov.io/gh/isar/hive">
    <img src="https://img.shields.io/codecov/c/github/isar/hive?logo=codecov&logoColor=fff&labelColor=333940">
  </a>
  <a href="https://t.me/isardb">
    <img src="https://img.shields.io/static/v1?label=join&message=Isar%20%26%20Hive&labelColor=333940&logo=telegram&logoColor=white&color=229ED9">
  </a>
  <a href="https://twitter.com/simcdev">
    <img src="https://img.shields.io/twitter/follow/simcdev?style=social">
  </a>
</p>

Hive is a lightweight and blazing-fast key-value database made for Flutter and Dart.

## Features 🌟

- 🌍 Cross-platform: mobile, desktop, browser
- 🚀 Need for Speed? Hive's got it in spades.
- 💡 Simple, powerful, & intuitive API
- 🔐 Tighter than Fort Knox: We've got encryption built right in.
- 🧠 Think multi-tasking: Hive supports multiple isolates.
- 🔋 No need to pack extras: We come with batteries included.

> 🐝 A single bee can visit 5,000 flowers in a day!

## Buzz into Action with Hive 🐝

Feeling the excitement? Great! Let's help you take your first flight with Hive.

#### 1️⃣ Add dependencies

To kickstart the journey add `hive` and `path_provider` to your `pubspec.yaml`.

```yaml
dependencies:
  hive: ^4.0.0
  path_provider: ^2.1.0
```

Pssst! 🤫 `path_provider` will help you to find the optimal directory for each platform.

#### 📂 Designate a Home

Hive needs a place to call home. Using `path_provider` we can find a valid directory.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Hive.defaultDirectory = dir.path;

  // ...
}
```

#### 🏁 And... Action!

🎉 Woohoo! You're all set. Dive right in and let's get buzzing with Hive.

```dart
import 'package:hive/hive.dart';

final box = Hive.box();
box.put('name', 'David');

final name = box.get('name');
print('Name: $name');
```

> 🐝 Honeybees can fly at a speed of up to 30 kilometers per hour!

## 📚 Hive Handbook

In Hive, data is neatly organized into containers known as boxes. Think of boxes as tables you'd find in SQL, but far more flexible — they don't stick to a set structure and can contain a variety of data.

For a small app, a single box might be enough. For more advanced problems, boxes are a great way to organize your data. Boxes can also be encrypted to store sensitive data.

> 🐝 Bees have five eyes – three simple eyes on top of the head, and two compound eyes, with numerous hexagonal facets.

### 📦 Opening Boxes

Initiating your journey with Hive begins with opening your first box. Trust me, it's unbee-lievably easy:

```dart
final box = Hive.box(name: 'myBox');
```

When you call `Hive.box(name: 'myBox')` for the first time with a given name, Hive will create a new box. If you call it again with the same name, Hive will return the already existing box. You can also use `Hive.box()` without a name. In this case, Hive will return the default box.

There are optional parameters you can pass to `Hive.box()`:

| Parameter       | Description                                                                        |
| --------------- | ---------------------------------------------------------------------------------- |
| `name`          | Label your box with a distinct name                                                |
| `directory`     | Select a home for your box. If omitted, Hive defaults to the defaultDirectory.     |
| `encryptionKey` | Hand over this key, and Hive will encrypt your box. Remember to keep the key safe! |
| `maxSizeMiB`    | The maximum size of the box in MiB. Go for a modest number.                        |

> 🐝 Beeswax, which is secreted from the abdomen of worker bees, is used to construct the honeycomb.

### 🌂 Bidding Adieu: Closing Boxes

It's not advised to close boxes that might be accessed again shortly. This prevents unnecessary overhead of reopening the box and ensures smooth data retrieval.

To close a single box just call `box.close()`. To close all boxes use `Hive.closeAllBoxes()`. Sometimes you may want to close a box and delete all of its data. You can do this by calling `box.deleteFromDisk()` or `Hive.deleteAllBoxesFromDisk()`.

> 🐝 When a bee finds a good source of nectar, it flies back to the hive and shows its friends where the nectar source is by doing a dance.

### ✍️ Filling the Honeycomb: Inserting Data

We have a box, now let's fill it with sweet data! At its core, a box is just a key-value store. String keys are mapped to arbitrary primitive values. You can think of a box as a persisted `Map<String, dynamic>`.

```dart
final box = Hive.box();
box.put('danceMoves', 'Waggle Dance');
box.put('wingSpeed', 200);
```

Updating values? If a particular key already exists, Hive simply updates its corresponding value. And yes, complex types like lists and maps? They're in too!

```dart
box.put('friends', ['Buzzy', 'Stinger', 'Honey']);
box.put('memories', {'firstFlight': 'Sunny Day', 'bestNectar': 'Rose'});
```

Instead of `.put()` you prefer the syntax of maps? Hive gets you:

```dart
box['danceMoves'] = 'Round Dance';
box['wingSpeed'] = 220;
```

Got a bucket of honey facts? Drop them all at once with `box.putAll()`:

```dart
box.putAll({'favoriteFlower': 'Lavender', 'wingSpeed': 210});
```

> 🐝 A single bee colony can produce anywhere from 30 to 100 pounds of honey in a year, depending on the availability of nectar sources.

### 👀 Extracting Honey... I mean, Data!

Need a snippet of info from your Hive? No need to don the beekeeper suit; just scoop it out using `box.get()` or `box.getAll()`. If a key doesn't exist, `box.get()` simply return a `null`. But fret not; you can tell it to have a backup plan:

```dart
final box = Hive.box(name: 'beeees');
final fav = box.get('favoriteFlower');
final moves = box.get('beeDanceMoves', defaultValue: 'waggle');
```

Oh, and if you're feeling fancy, use the `[]` operator for a more stylish approach:

```dart
final fav = box['favoriteFlower'];
final moves = box['beeDanceMoves'] ?? 'waggle';
```

> 🐝 Worker bees are the only bees most people ever see flying around outside the hive. They're female, and their roles are to forage for food (pollen and nectar from flowers), build and protect the hive, and clean and circulate air by beating their wings.

### 🧹 Deleting Data

Time for some spring cleaning in the hive! To remove a single entry from your box, use `box.delete()`:

```dart
box.delete('lavenderHoney');
```

Perhaps it's time for a complete reset, making space for a fresh batch of honey. If you're looking to remove all key-value pairs from a box, use `box.clear()`:

```dart
box.clear();
```

> 🐝 Bees have been around for more than 30 million years! Their long history predates the existence of humans and even dinosaurs.

### 🍯 Hive Compartments: Using Boxes like Lists

In the bee world, honeycombs aren't just random compartments; they're methodically organized. Similarly, while we've been viewing Hive boxes as maps so far, they can be used just like lists:

```dart
final box = Hive.box();

box.add('Rose');
box.add('Tulip');

print(box.getAt(0)); // Rose
print(box.getAt(1)); // Tulip
```

But remember, bees can't retrieve honey from a comb that's empty or doesn't exist. Likewise, index-based operations will throw an error if you try an index out of bounds:

```dart
final box = Hive.box();
box.add('Daisy');
print(box.getAt(1)); // This will make the bees buzz in confusion
```

Even if we insert a key-value pair we can still access the values by index.

```dart
final box = Hive.box();

box.add('Lily');
box.put('key', 'Orchid');

print(box.getAt(0)); // Lily
print(box.getAt(1)); // Orchid
```

Of course, we can also use the `[]` operator in combination with indexes :

```dart
final box = Hive.box();

box.add('Marigold');
print(box[0]); // Marigold

box[0] = 'Daffodil';
box[1] = 'Bluebell'; // This will get the bees in a whirl
```

> 🐝 To produce one pound of honey, a hive's bees must visit 2 million flowers and fly over 55,000 miles.

### 🛡️ Type safety

Safety is the bee's priority! To keep your data sweet and pure boxes have an optional generic type parameter. It allows you to store only values of a specific type in a box:

```dart
final box = Hive.box<String>(name: 'BeeTreasures');
box.put('DaisyDance', 'SweetNectarShake');
box.put('RoseRumba', 'GoldenPollenParty');
box.put('TulipTango', 777); // Error - You can't fool the bees!
```

> 🐝 Bees have two stomachs. One is for eating, and the other is for storing nectar collected from flowers or water so they can carry it back to their hive. Talk about a sweet backpack!

### 🧩 Bee-yond the Basics: Non-primitive Objects

Hive goes beyond storing just basic data types! Along with primitives, lists, and maps, Hive can store any Dart object of your liking. The only buzz you need to know? Your object should come equipped with a `.fromJson()` and `.toJson()` method:

```dart
class Bee {
  Bee({required this.name, required this.role});

  factory Bee.fromJson(Map<String, dynamic> json) => Bee(
    name: json['name'] as String,
    role: json['role'] as String,
  );

  final String name;
  final String role;

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
  };
}
```

Before our bee-friends can buzz around in Hive, you need to do the beekeeper's job and register the `Bee` class:

```dart
Hive.registerAdapter('Bee', Bee.fromJson);
```

Now, you're all set to let your bees fly:

```dart
final box = Hive.box();

var bumble = Bee()
  ..name = 'Bumble'
  ..role = 'Worker';
box.put('BumbleID', bumble);

print(box.get('BumbleID')); // Bumble - Worker
```

> 🐝 Bees are responsible for pollinating about one-third of the world's food crops.

### 🪢 Transactions

Transactions are an efficient way to update multiple values at once. They are also useful if you want to make sure that a Box is not changed by other code while you are working with it.

```dart
final box = Hive.box();

box.write(() {
  box.store('nectar1', 'GoldenNectar');
  box.store('nectar2', 'WildflowerBrew');
  box.store('nectar3', 'CloverDew');
});

box.read(() {
  box.get('nectar1');
});
```

Changes made in a transaction are always atomic. Either all changes are applied or none of them. So if an error occurs during a transaction, the box will not be changed.

```dart
final box = Hive.box();
box.put('honeyLevel', 5);

box.write(() {
  box.put('honeyLevel', 6);
  throw Exception('Oh no!!!');
});

print(box.get('honeyLevel')); // 5
```

> 🐝 Bees can recognize human faces, and they can even be trained to associate a picture of a face with sweet treats!

### 📜 License

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
