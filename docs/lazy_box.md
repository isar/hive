# Lazy box

By default, the whole content of a box is stored in memory as soon as it is opened. This is great for small and medium sized boxes because you can access their contents without async calls.

For larger boxes or very memory critical applications, it may be useful to load values lazily. When a lazy box is being opened, all of its keys are read and stored in memory. Once you access a value, Hive knows its exact position on the disk and gets the value.

```dart
var lazyBox = await Hive.openBox('myLazyBox', lazy: true) as LazyBox;

var value = await lazyBox.get('lazyVal');
```

To get an already opened lazy box call:

```dart
var lazyBox = Hive.box('myLazyBox') as LazyBox;
```
