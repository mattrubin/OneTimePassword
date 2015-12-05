Base32 Additions for Objective-C on Mac OS X and iOS
====


Usage
----
Open the XCode project file, and drag MF_Base32Additions.m/.h into your project.

In files where you want to use Base32 encoding/decoding, simply include the header file and use one of the provided NSData or NSString additions.
    
Example use:

    #import "MF_Base32Additions.h"
    
    NSString *helloWorld = @"Hello World";
    NSString *helloInBase32 = [helloWorld base32String];
    NSString *helloDecoded = [NSString stringFromBase32String:helloInBase32];




Performance
----
* Encoding: Approximately 4 to 5 times faster than using the equivalent SecTransform.
* Decoding: Slightly faster but almost identical decoding time as equivalent SecTransform.



Requirements
-----
* Compile with Automatic Reference Counting
* Compatible with Mac OSX 10.6+ and iOS 4.0+



Implementation
----
* Implemented as per RFC 4648, see http://www.ietf.org/rfc/rfc4648.txt for more details.



Licensing
----
* Public Domain
