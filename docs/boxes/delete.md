# Delete

If you want to change an existing value, you can either override it using for example `put()` or delete it:

```dart
var box = Hive.box('testBox');

box.delete('key');
```

If the key does not exist, no disk access is needed and the returned `Future` finishes immediately.

