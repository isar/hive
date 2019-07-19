# Register Adapter

When you want Hive to use a `TypeAdapter`, you have to register it. Two things are needed for that: An instance of the adapter and a `typeId`. Every type has a unique `typeId` which is used to find the correct adapter when a value is brought back from disk.
The `typeId`s 0-32 are reserved for primitive and built in types.

You can register `TypeAdapters` for a specific box or globally for all boxes:

```dart
Hive.registerAdapter(MyObjectAdapter(), 33); // Register MyObjectAdapter for all boxes

box.registerAdapter(MyOtherAdapter(), 34); // Register MyOtherAdapter for the box
```

Box adapters always have precedence over global adapters.

**SUPER IMPORTANT:** Make sure to use `typeId`s consistently. Your changes have to be compatible to previous versions of the box.