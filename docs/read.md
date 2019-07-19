# Read from box

Reading from a box is almost like accessing a Map:

```dart
String name = box['name'];

DateTime birthday = box['birthday'];
```

If your box is [lazy](lazy_box.md) the above code will not work. You have to access the box using `get()`:

```dart
String name = await box.get('name');

DateTime birthday = await box.get('birthday');
```

If the key does not exist, `null` is returned. Optionally you can specify a `defaultValue` which will be returned in case the key does not exist.

```dart
double height = await box.get('randomKey', defaultValue: 17.5);
```