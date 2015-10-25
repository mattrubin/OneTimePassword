//
//  Keychain.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

func addKeychainItemWithAttributes(attributes: NSDictionary) -> NSData? {
    let mutableAttributes = attributes.mutableCopy() as! NSMutableDictionary
    mutableAttributes[kSecClass as! NSCopying] = kSecClassGenericPassword
    mutableAttributes[kSecReturnPersistentRef as! NSCopying] = kCFBooleanTrue
    // Set a random string for the account name.
    // We never query by or display this value, but the keychain requires it to be unique.
    if (mutableAttributes[kSecAttrAccount as! NSCopying] == nil) {
        mutableAttributes[kSecAttrAccount as! NSCopying] = NSUUID().UUIDString
    }

    var result: AnyObject?
    let resultCode: OSStatus = withUnsafeMutablePointer(&result) {
        SecItemAdd(mutableAttributes, $0)
    }

    guard resultCode == OSStatus(errSecSuccess)
        else { return nil }

    return result as? NSData
}

func updateKeychainItemForPersistentRef(persistentRef: NSData, withAttributes attributesToUpdate: NSDictionary) -> Bool {
    let queryDict = [
        kSecClass as! NSCopying: kSecClassGenericPassword,
        kSecValuePersistentRef as! NSCopying: persistentRef,
    ]

    let resultCode = SecItemUpdate(queryDict, attributesToUpdate)
    return (resultCode == OSStatus(errSecSuccess))
}

func deleteKeychainItemForPersistentRef(persistentRef: NSData) -> Bool {
    let queryDict = [
        kSecClass as! NSCopying: kSecClassGenericPassword,
        kSecValuePersistentRef as! NSCopying: persistentRef,
    ]

    let resultCode = SecItemDelete(queryDict)
    return (resultCode == OSStatus(errSecSuccess))
}
