# Read

Reading from a box is very straightforward:

```dart
String name = box.get('name');

DateTime birthday = box.get('birthday');
```

If the key does not exist, `null` is returned. Optionally you can specify a `defaultValue` which will be returned in case the key does not exist.

```dart
double height = box.get('randomKey', defaultValue: 17.5);
```

Lists returned by `get()` are always of type `List<dynamic>` \(Maps of type `Map<dynamic, dynamic>`\). Use `list.cast<SomeType>()` to cast them to a specific type.

