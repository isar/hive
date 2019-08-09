# Generate Adapter

The [hive_generator](https://pub.dev/packages/hive_generator) automatically generates `TypeAdapter`s for almost any class.

1. Add `hive_generator` and `build_runner` to your `pubspec.yaml` (as `dev_dependency`)
2. To generate a `TypeAdapter` for a class, annotate it with `@HiveType`
3. Annotate all fileds which should be stored with `@HiveField`
4. Run build task `flutter packages pub run build_runner build`
5. [Register](register_adapter.md) adapter

### Example

Given a library `person.dart` with an `Person` class annotated with `@HiveType`:

```dart
import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType()
class Person {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  List<Person> friends;
}
```

As you can see, each field has a **unique** number. These field numbers are used to identify the fields in the hive binary format, and should not be changed once your class is in use.

*Field numbers can be in the range 0-255*.

The above code will generate an adapter class called `PersonAdapter`. You can change that name with the optional `adapterName` parameter of `@HiveType`.

## Updating a class
If an existing class needs to be changed – for example, you'd like the class to have an extra field – but you'd still like to read objects written with the old adapter, don't worry! It's very simple to update generated adapters without breaking any of your existing code. Just remember the following rules:

- Don't change the field numbers for any existing fields.
- If you add new fields, any objects written by the "old" adapter can still be read by the new adapter. These fields will just be ignored. Similarly, objects written by your new code can be read by your old code: the new field will be ignored when parsing.
- Fields can be renamed and even changed from public to private or vice versa as long as the field number stays the same.
- Fields can be removed, as long as the field number is not used again in your updated class.
- Changing the type of a field is not supported. You should create a new one instead.


## Enums

Generating an adapter for enums works almost like it does for classes:

```dart
@HiveType()
enum HairColor {
  @HiveField(0)
  brown,

  @HiveField(1)
  blond,

  @HiveField(2)
  black,
}
```

For updating the enum the same rules apply as above.