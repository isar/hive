## 🌼 Welcome, Beekeeper! 🐝

Let's embark on a buzzworthy journey into the world of Flutter and Dart using Hive! Ready to see Hive in action? This example will walk you through setting up a Flutter project and implementing Hive to store data on a list of favorite flowers for bees.

## 🌺 Buzzy Beginnings

Create a new Flutter app:

```bash
flutter create bee_favorites
cd bee_favorites
```

Now we can add some sweet dependencies to our `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^4.0.0
  isar_flutter_libs: ^4.0.0-dev.13
  path_provider: ^2.0.0
```

## 🌻 Setting up Hive

Before we get into the code, let's set up Hive:

```dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationDocumentsDirectory();
  Hive.defaultDirectory = directory.path;

  runApp(BeeApp());
}
```

## 🌸 Bee Favorites App

Let's build a simple Flutter app where bees can vote for their favorite flowers!

```dart
class BeeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bee Favorites',
      theme: ThemeData(primarySwatch: Colors.yellow),
      home: FavoriteFlowers(),
    );
  }
}

class FavoriteFlowers extends StatefulWidget {
  @override
  _FavoriteFlowersState createState() => _FavoriteFlowersState();
}

class _FavoriteFlowersState extends State<FavoriteFlowers> {
  final Box<String> favoriteBox = Hive.box<String>('favorites');

  final List<String> flowers = ['Rose', 'Tulip', 'Daisy', 'Lily', 'Sunflower'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bee Favorites 🐝')),
      body: ListView.builder(
        itemCount: flowers.length,
        itemBuilder: (context, index) {
          final flower = flowers[index];
          return ListTile(
            title: Text(flower),
            trailing: IconButton(
              icon: Icon(Icons.star),
              onPressed: () {
                favoriteBox.add(flower);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$flower added to favorites! 🌼')),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.view_list),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => FavoritesDialog(favorites: favoriteBox.values.toList()),
          );
        },
      ),
    );
  }
}

class FavoritesDialog extends StatelessWidget {
  final List<String> favorites;

  FavoritesDialog({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bee Favorites 🌼'),
      content: Container(
        width: 300,
        height: 200,
        child: ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            return ListTile(title: Text(favorites[index]));
          },
        ),
      ),
      actions: [
        TextButton(
          child: Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
```

## 🐝 Bee-fore You Go...

Once you've completed this tutorial, run your app! Every time a bee (or user) selects a flower, it's added to the favorites list, and you can view the favorites with the FloatingActionButton!

> **Bee fact:** Bees communicate through a combination of chemical scents and movements. One known movement is the waggle dance, which indicates the location of a food source!

Check out the full documentation in Hive's readme and the other example apps.
