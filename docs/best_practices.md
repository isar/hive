# Best Practices

## When to use Hive
Hive is very performant because it has little overhead compared to relational databases. The API is very close to how the data is actually stored on the disk.

Key-value databases can be applied to many scenarios. For example, key-value stores can be useful for storing things such as the following:

- User profiles
- Session information
- Article/blog comments
- Emails
- Status messages
- Shopping cart contents
- Product categories
- etc.

Hive is also one of the best options when it comes to cross platform support. You don't have to include binaries and it works in the browser using IndexedDB.

## When not to use Hive
Every kind of data can be stored in Hive when modeled correctly. That being said, it might sometimes be more convenient to use a relational database like SQLite.<br>
Especially if your data has complex relations, you should consider using SQLite.<br>
Since Hive is so lightweight and will hardly increase your binary size at all, you can use Hive and other solutions together.

## Modelling data
Coming soon.