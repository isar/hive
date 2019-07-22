# Transactions

Hive supports transactions for boxes. You can read and write data atomically. If a transaction fails, nothing will be changed.

```dart
await box.put('key', 'hello');

try {
  await box.transaction((trx) async {
    await trx.put('key', 123);
    print(await trx.get('key')); // 123

    throw "Some error";
  });
} catch (e) {}

print(await box.get('key')); // hello
```

If you change multiple entries, using transactions or `putAll()` / `deleteAll()` can improve performance significantly since these methods only need a single disk access.

?> If the code inside a transaction throws an exception, the transaction will pass it on.