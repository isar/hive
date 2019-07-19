# TypeAdapters

Hive supports all primitive types, `List`, `Map`, `DateTime` and `Uint8List`. If you want to store other objects, you have to register a `TypeAdapter` which converts the object from and to binary form.


## Generate Adapter

Hive can automatically generate `TypeAdapter`s.


## Register Adapter

When you want Hive to use a `TypeAdapter`, you have to register it. Two things are needed for that: An instance of the adapter and a `typeId`. Every type has a unique `typeId` which is used to find the correct adapter when a value is brought back from disk.
The `typeId`s 0-32 are reserved for primitive and built in types.

You can register `TypeAdapters` for a specific box or globally for all boxes:

```dart
Hive.registerAdapter(MyObjectAdapter(), 33); // Register MyObjectAdapter for all boxes

box.registerAdapter(MyOtherAdapter(), 34); // Register MyOtherAdapter for the box
```

Box adapters always have precedence over global adapters.

**SUPER IMPORTANT:** Make sure to use `typeId`s consistently. Your changes have to be compatible to previous versions of the box.


## Create Adapter manually

Sometimes it might be necessary to create a custom `TypeAdapter`. You can do that by extending the `TypeAdapter` class. Make sure to specify the generic argument.

**Important:** Test your custom `TypeAdapter` thoroughly. If it does not work correctly, it may corrupt your box.

It is very easy to implement a `TypeAdapter`. Here is the `DataTimeAdapter` used by Hive internally:

```dart
class DataTimeAdapter extends TypeAdapter<DateTime> {
  @override
  DateTime read(BinaryReader reader) {
    var millis = reader.readInt();
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}
```

The `read()` method is called when your object has to be read from the disk. Use the `BinaryReader` to read all properties of your object. In the above sample it is only an `int` containing `millisecondsSinceEpoch`.<br>
The `write()` method is the same just for writing the object to the disk.

**Important:** Make sure, you read properties in the same order you have written them before.