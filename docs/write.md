# Write to box

Writing is just as easy as reading. All keys have to be ASCII Strings with a max lenght of 255 chars.

```dart
await box.put('name', 'Paul');

await box.put('friends', ['Dave', 'Simon', 'Lisa']);
```

?> Writing `null` is the same as [deleting](delete.md) a value.
