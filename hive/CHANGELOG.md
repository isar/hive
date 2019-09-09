## 1.0.0
- First stable release

## 0.5.1+1
- Change `keys` parameter of `deleteAll` from `List` to `Iterable`
- Fixed bug in `BinaryWriter`

## 0.5.1
- Fixed `Hive.init()` bug in browser
- Fixed a bug with large lists or strings
- Improved box opening time in browser
- Improved general write performance
- Improved docs
- Added integration tests

## 0.5.0
- Added `keyComparator` parameter for custom key order
- Added `isEmpty` and `isNotEmpty` getters to box
- Added support for reading and writing subclasses
- Removed length limitation for Lists, Maps and Strings
- Greatly improved performance of storing Uint8Lists in browser
- Removed CRC check in browser (not needed)
- Improved documentation
- TypeIds are now allowed in the range of 0-223
- Fixed compaction
- Fixed writing longer Strings
- **Breaking:** Binary format changed

## 0.4.1+1
- Document all public APIs
- Fixed flutter_web error

## 0.4.1
- Allow different versions of the `path` package

## 0.4.0
- Added `BigInt` support
- Added `compactionStrategy` parameter
- Added automatic crash recovery
- Added `add()` and `addAll()` for auto increment keys
- Added `getAt()`, `putAt()` and `deleteAt()` for working with indices
- Support for int (32 bit unsigned) keys
- Non-lazy boxes now notify their listeners immediately about changes
- Bugfixes
- More tests
- **Breaking:** Open boxes with `openBox()`
- **Breaking:** Writing `null` is no longer equivalent to deleting a key
- **Breaking:** Temporarily removed support for transactions. New API design needed. Will be coming back in a future version.
- **Breaking:** Binary format changed
- **Breaking:** API changes

## 0.3.0+1
- Bugfix: `Hive['yourBox']` didn't work with uppercase box names

## 0.3.0
- Big step towards stable API
- Support for transactions
- Annotations for hive_generator
- Bugfixes
- Improved web support
- **Breaking:** `inMemory` -> `lazy`
- **Breaking:** Binary format changed

## 0.2.0
- Support for dart2js
- Improved performance
- Added `inMemory` option
- **Breaking:** Minor API changes
- **Breaking:** Changed Endianness to little
- **Breaking:** Removed Migrator

## 0.1.1
- Downgrade to `meta: ^1.1.6` to support flutter

## 0.1.0
- First release
