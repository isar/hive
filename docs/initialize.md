# Initialize Hive

*This section only applies if you use hive in the VM. In the browser, you can skip this step.*

When your program starts, Hive has to be initialized. Give it a directory where it can store its files. It is recommended to use an empty directory and not to store any other data there. Each box will have it's own `.hive` file in the Hive-home directory.

```dart
Hive.init('path/to/hive');
```

If you use a directory outside your app files, make sure to request runtime permission on Android.