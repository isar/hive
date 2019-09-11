# Register Adapter

When you want Hive to use a `TypeAdapter`, you have to register it. Two things are needed for that: An instance of the adapter and a `typeId`. Every type has a unique `typeId` which is used to find the correct adapter when a value is brought back from disk.
All `typeId`s between 0 and 223 are allowed.

You can register `TypeAdapters` for a specific box or globally for all boxes:

```dart
Hive.registerAdapter(MyObjectAdapter(), 0); // Register MyObjectAdapter for all boxes

box.registerAdapter(MyOtherAdapter(), 0); // Register MyOtherAdapter just for the box
```

Box adapters always have precedence over global adapters.

!> Make sure to use `typeId`s consistently. Your changes have to be compatible to previous versions of the box.