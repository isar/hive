# Write to box

Writing to a box is almost like writing to a map. All keys have to be ASCII Strings with a max lenght of 255 chars or integers.

```dart
var box = Hive.box('myBox');

box.put('name', 'Paul');

box.put('friends', ['Dave', 'Simon', 'Lisa']);

box.put(123, 'test');

box.putAll({'key1': 'value1', 42: 'life'})
```

You may wonder why writing works without async code. This is one of the main strengths of Hive.<br>
The changes are written to the disk as soon as possible in the background but all listeners are notified immediately. If the async operation fails (which it should not), all listeners are notified again with the old values.

This does not work for [lazy](lazy_box.md) boxes. As long as the `put()` Future did not finish, `get()` will return the old values.

?> Writing `null` is **NOT** the same as [deleting](delete.md) a value.
