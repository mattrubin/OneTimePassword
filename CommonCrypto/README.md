Trying to include the system CommonCrypto headers directly in the framework results in an "include of non-modular header inside framework module" error. The solution is to use these custom CommonCrypto `modulemap` files and reference them from the framework target via the `SWIFT_INCLUDE_PATHS` build settings.

References:
- https://github.com/soffes/Crypto
- https://ind.ie/labs/blog/using-system-headers-in-swift/
