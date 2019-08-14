# Lazy box

By default, the whole content of a box is stored in memory as soon as it is opened. This is great for small and medium sized boxes because you can access their contents without async calls.

For larger boxes or very memory critical applications, it may be useful to load values lazily. When a lazy box is being opened, all of its keys are read and stored in memory. Once you access a value, Hive knows its exact position on the disk and gets the value.

```dart
var lazyBox = await Hive.box('myLazyBox', lazy: true);

var value = await lazyBox.get('lazyVal');
```

You can use lazy boxes like any other box, but you can't access keys using the list access operator `[]`.

```dart
var value = lazyBox['lazyVal']; // ERROR
```
