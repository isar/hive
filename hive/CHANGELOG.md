## 0.4.0
- Added []= operator to lazy boxes
- Added `BigInt` support
- Added `compactionStrategy` parameter
- Added automatic crash recovery
- Added `add()` and `addAll()` for auto increment keys
- Support for int (32 bit unsigned) keys
- Cached boxes now notify their listeners immediately about changes
- Bugfixes
- More tests
- **Breaking:** Binary format changed
- **Breaking:** Minor API changes

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
