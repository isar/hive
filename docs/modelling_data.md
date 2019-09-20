Hive does not have a query language and only has limited support for sorting. This is not necessarily a disadvantage as you can see in the benchmark. Sorting and filtering is much faster if you do it yourself in Dart.

Since Key-value stores are really simple, data can be modeled in a less complicated manner than for example in SQLite. There is no schema and you can store different objects in the same box. But there are a few things you should keep in mind.

## Key order

All keys are sorted lexicographically by default. You can use that to get "free" ordering. E.g. if you want to store users, you could use the last names and a unique number as key to sort them by last name.

You can also provide your own key sorting function. You could for example reverse the sorting order.

## Lists vs Auto Increment

If you want to store a list of items, you have two options. Either store the list directly as a value (using `put('myKey', [1, 2, 3])`) or you can store each item individually (using `add(1)`, `add(2)` etc.).

If you want to store a big list which is updated frequently (for example a list of messages), you should store the items individually. Otherwise the whole list has to be written each time you change an item.

## Filtering items

It is really easy to filter the items in your box:

```dart
var filteredUsers = userBox.values.where((user) => user.name.startsWith('s'));
```

It might be a good idea to cache the result.