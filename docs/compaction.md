# Compaction

Hive is an append-only data store. When you change or delete a value, the change is written to the end of the box file. This leads sooner or later to a growing box file. Hive may automatically "compact" your box at any time.

It may benefit the start time of your app if you induce compaction manually before you close a box.

```dart
await box.compact();
await box.close();
```

You can specify your own rules for automatic compaction. Just pass the `compactionStrategy` parameter when you open a box:

```dart
var box = await Hive.box('myBox', compactionStrategy: (entries, deletedEntries) {
  return deletedEntries > 50;
});
```

This will compact your box when 50 keys have been overridden or deleted.

!> The compaction strategy **must never** access a box.