# Create Adapter manually

Sometimes it might be necessary to create a custom `TypeAdapter`. You can do that by extending the `TypeAdapter` class. Make sure to specify the generic argument.

**Important:** Test your custom `TypeAdapter` thoroughly. If one does not work correctly, it may corrupt your box.

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