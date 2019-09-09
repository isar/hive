# Auto increment & indices

We already know that Hive supports unsigned integer keys. You can use auto increment keys if you like. This is very useful for storing and accessing multiple objects. You can use a Box like a list.

```dart
var friends = Hive.box('friends');

friends.add('Lisa');            // index 0, key 0

friends.add('Dave');            // index 1, key 1

friends.put(123, 'Marco');      // index 2, key 123

print(friends.values);          // Lisa, Dave, Marco
```

There are also `getAt()`, `putAt()` and `deleteAt()` methods to access or change values by their index.

It is important to understand the difference of integer keys and indices.

```dart
friends.putAt(2, 'Ben');
```

```dart
frinds.put(123, 'Ben');
```

Both of these operations do the same thing. They replace the `Marco` with `Ben`. `putAt()` uses the index (in this case `2`), `put()` uses the key (in this case `123`).

This also works with String keys.

?> Even if you only use auto increment keys, you should not rely on keys and indices being the same.