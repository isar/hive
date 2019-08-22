# Read from box

Reading from a box is very straightforward:

```dart
String name = box.get('name');

DateTime birthday = box.get('birthday');
```

If the key does not exist, `null` is returned. Optionally you can specify a `defaultValue` which will be returned in case the key does not exist.

```dart
double height = box.get('randomKey', defaultValue: 17.5);
```