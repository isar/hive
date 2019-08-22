# Frequently Asked Questions

### Is Hive ready for production
Nope. Working hard to get there...

### Which platforms does Hive support?
Hive supports all platforms where the dart vm runs plus browsers. On browsers the IndexedDB is used as backend.

### When should I use Hive
[When to use Hive](best_practices?id=when-to-use-hive)

### When should I not use Hive
[When not to use Hive](best_practices?id=when-not-to-use-hive)

### Where does Hive store my data?
Each box has its own file in the home directory (the one you set using `Hive.init()`).

### Does Hive persist data immediately?
Yes.

### What happens if my app is killed?
The worst thing that can happen is that you lose the last written entry if it hasn't completed yet. Hive has built in integrity checking and crash recovery and will take care of everything.

### Why is `box.get()` synchronous? Isn't that slow?
Hive caches all entries by default so no. If you don't want that, use [lazy boxes](lazy_box.md) instead.

### Can I use Hive to store binary data like images?
Yes but don't store too big images (a few MB should be fine).

### Can Hive sync data with a server?
Not out of the box but you can do that yourself quite easily using the `box.toMap()` method and / or the [change notifier](watch_changes.md).

### What type of encryption does Hive use?
AES 256 CBC with PKCS7 padding.

### Do I have to call `Hive.close()`
No you don't. It might speed up the next start of your app but nothing to worry about.

### Is it ready for production now?
STILL NO!