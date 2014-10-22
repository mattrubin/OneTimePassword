//
//  Keychain.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

func addKeychainItemWithAttributes(attributes: NSDictionary) -> NSData? {
    let mutableAttributes = attributes.mutableCopy() as NSMutableDictionary
    mutableAttributes[kSecClass as NSCopying] = kSecClassGenericPassword
    mutableAttributes[kSecReturnPersistentRef as NSCopying] = kCFBooleanTrue
    // Set a random string for the account name.
    // We never query by or display this value, but the keychain requires it to be unique.
    if (mutableAttributes[kSecAttrAccount as NSCopying] == nil) {
        mutableAttributes[kSecAttrAccount as NSCopying] = NSUUID().UUIDString
    }

    var result: Unmanaged<AnyObject>?
    let resultCode: OSStatus = SecItemAdd(mutableAttributes, &result)

    if resultCode == OSStatus(errSecSuccess) {
        if let opaquePointer = result?.toOpaque() {
            return Unmanaged<NSData>.fromOpaque(opaquePointer).takeUnretainedValue()
        }
    }
    return nil
}

func updateKeychainItemForPersistentRefWithAttributes(persistentRef: NSData, attributesToUpdate: NSDictionary) -> Bool {
    let queryDict = [
        kSecClass as NSCopying: kSecClassGenericPassword,
        kSecValuePersistentRef as NSCopying: persistentRef,
    ]

    let resultCode = SecItemUpdate(queryDict, attributesToUpdate)
    return (resultCode == OSStatus(errSecSuccess))
}

func deleteKeychainItemForPersistentRef(persistentRef: NSData) -> Bool {
    let queryDict = [
        kSecClass as NSCopying: kSecClassGenericPassword,
        kSecValuePersistentRef as NSCopying: persistentRef,
    ]

    let resultCode = SecItemDelete(queryDict)
    return (resultCode == OSStatus(errSecSuccess))
}
