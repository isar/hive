# Hive & Flutter

## WatchBoxBuilder

The `WatchBoxBuilder` widget can be used to refresh parts of your app when the data in Hive changes.

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WatchBoxBuilder(
      box: Hive.box('myBox'),
      watchKeys: ['firstName', 'lastName'],
      builder: (context, box) {
        return Text(box.get('firstName') + ' ' + box.get('lastName'));
      }
    )
  }
}
```

Each time the value associated to `firstName` or `lastName` change, the `builder` is called and the `Text` widget refreshed.


## Async calls

Many of the Hive methods like `put()` or `delete()` are asynchronous. Handling async calls in Flutter is not fun because you have to use `FutureBuilder` or `StreamBuilder` and handle exceptions etc.

The good news is that you don't have to await all the `Future`s returned by Hive. Changes are applied instantly, even if the `Future` has not finished yet. If you want to make sure that a write operation is successful just await its `Future`.