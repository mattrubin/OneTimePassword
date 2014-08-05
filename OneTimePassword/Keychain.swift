//
//  Keychain.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

func updateKeychainItemForPersistentRefWithAttributes(persistentRef: NSData, attributesToUpdate: NSDictionary) -> Bool {
    let queryDict = [
        kSecClass.takeUnretainedValue() as NSCopying: kSecClassGenericPassword.takeUnretainedValue() as NSCopying,
        kSecValuePersistentRef.takeUnretainedValue() as NSCopying: persistentRef,
    ]

    let resultCode = SecItemUpdate(queryDict, attributesToUpdate)
    return (resultCode == OSStatus(errSecSuccess))
}

func deleteKeychainItemForPersistentRef(persistentRef: NSData) -> Bool {
    let queryDict = [
        kSecClass.takeUnretainedValue() as NSCopying: kSecClassGenericPassword.takeUnretainedValue() as NSCopying,
        kSecValuePersistentRef.takeUnretainedValue() as NSCopying: persistentRef,
    ]

    let resultCode = SecItemDelete(queryDict)
    return (resultCode == OSStatus(errSecSuccess))
}
