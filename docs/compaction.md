# Compaction

Hive is an append-only data store. When you change or delete a value, the change is written to the end of the box file. This leads sooner or later to a growing box file. Hive may automatically "compact" your box at any time.

It may benefit the start time of your app if you induce compaction manually before you close a box.

```dart
await box.compact();
await box.close();
```