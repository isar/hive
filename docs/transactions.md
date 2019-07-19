# Transactions

Hive supports transactions for boxes. You can read and write data atomically. If a transaction fails, nothing is changed.

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