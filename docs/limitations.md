# Limitations

- **HIVE IS NOT READY FOR PRODUCTION YET**
- Keys have to be ASCII Strings with a max length of 255 chars.
- The supported integer values include all integers between -2^53 and 2^53, and some integers with larger magnitude
- Strings can have a maximum of 65536 **bytes**. Mind that a Unicode chars may be longer than one byte.
- Lists and Maps cannot have more than 65536 elements.
- Only one process can access a box at any time. Bad things happen otherwise.