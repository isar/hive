# When to use Hive

## When to use Hive

Hive is very performant because it has little overhead compared to relational databases. The API is very close to how the data is actually stored on the disk.

Key-value databases can be used to store almost any kind of data. For example:

* User profiles
* Session information
* Article/blog comments
* Messages
* Shopping cart contents
* Product categories
* Binary data
* etc.

Hive is also one of the best options when it comes to cross platform support. You don't have to include binaries and it works in the browser using IndexedDB.

## When not to use Hive

Every kind of data can be stored in Hive when modeled correctly. That being said, it might sometimes be more convenient to use a relational database like SQLite. \(More convenient, not faster!\)

Especially if your data has complex relations and you rely heavily on indices and complex queries, you should consider using SQLite.

Since Hive is so lightweight and will hardly increase your app size at all, you can also use Hive and other solutions together.

