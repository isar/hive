# What are boxes?

All data stored in Hive is organized in boxes. A box can be compared to a table in SQL but it does not have a structure and can contain anything.

For a small app, a single box might be enough. For more advanced problems, boxes are a great way to organize your data.
Boxes can also be encrypted to store sensitive data.

## Open Box

Before a box can be used, you have to open it:

```dart
var box = await Hive.openBox('testBox');
```

| Parameter | Description |
|-----------|-------------|
| name | The name of the box specifies the storage location and is used to check if a box already exists. It is **case-insensitive**. |
| encryptionKey | The key has to be a byte array with length 32 and is used to encrypt and decrypt all values in the box. |
| keyComparator | By default, keys are sorted lexicographically. This parameters allows you to provide a custom sorting order. |
| compactionStrategy | Specify your own rules for automatic compaction. |
| crashRecovery | If your app is killed while a write operations is running, the last entry might be corrupted. This entry will be deleted automatically when the app starts again. If you don't want this behaviour, you can disable it. |
| lazy | By default, all keys and values are stored in memory and read operations are synchronous (no disk access). By setting this to true, values are not cached and loaded asynchronously. |

If the box is already open, it will be returned immediately. All supplied parameters will be ignored.

Once you obtained a box instance, you can read, write and delete entries.

## Get open box

Hive stores a reference to all open boxes. If you want to get an already opened box, you can use 

```dart
var box = Hive.box('myBox');
```

This is especially useful for Flutter apps because you don't need to pass the box between widgets.

## Close box

If you don't need a box again, you should close it. All cached keys and values of the box will be dropped from memory and the box file will be closed after all active read and write operations finished.

?> It is perfectly fine to leave a box open for the runtime of the app. If you need a box again in the future, just leave it open.

```dart
var box = await Hive.openBox('myBox');
await box.put('hello', 'world');
await box.close();
```

Before your application exits, you should call `Hive.close()` to close all open boxes. Don't worry if the app is killed before you close Hive, it doesn't matter.
