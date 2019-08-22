# Limitations

- **HIVE IS NOT READY FOR PRODUCTION YET**
- Keys have to be 32 bit unsigned integers or ASCII Strings with a max length of 255 chars.
- The supported integer values include all integers between -2^53 and 2^53, and some integers with larger magnitude
- Strings can have a maximum of 65535 **bytes**. Mind that Unicode chars may be longer than one byte.
- Lists and Maps cannot have more than 65535 elements.
- Objects are not allowed to contain cycles. Hive will not detect them and storing will result in an infinite loop.
- Only one process can access a box at any time. Bad things happen otherwise.