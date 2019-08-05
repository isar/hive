# Write to box

Writing is just as easy as reading. All keys have to be ASCII Strings with a max lenght of 255 chars.

```dart
box['name'] = 'Paul';

box['friends'] = ['Dave', 'Simon', 'Lisa'];
```

You may wonder why writing works without async code. This is one of the main strengths of Hive.<br>
The changes are written to the disk as soon as possible in the background but all listeners are notified immediately. If the async operation fails (which it should not), all listeners are notified again with the old values.

This does not work for [lazy](lazy_box.md) boxes. Just use the async version of the above code:

```dart
await box.put('name', 'Paul');

await box.put('friends', ['Dave', 'Simon', 'Lisa']);
```

?> Writing `null` is the same as [deleting](delete.md) a value.
