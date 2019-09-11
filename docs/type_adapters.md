# TypeAdapters

Hive supports all primitive types, `List`, `Map`, `DateTime` and `Uint8List`. If you want to store other objects, you have to register a `TypeAdapter` which converts the object from and to binary form.

You can either write a `TypeAdapter` yourself or generate it. Most of the time the generated adapter will perform really good. Sometimes you there are small things you can improve with a manually written adapter.