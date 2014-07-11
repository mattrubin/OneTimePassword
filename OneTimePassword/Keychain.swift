//
//  Keychain.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

func updateKeychainItemForPersistentRefWithAttributes(persistentRef: NSData, attributesToUpdate: NSDictionary) -> Bool {
    let queryDict = NSMutableDictionary()
    queryDict.setObject(_kSecClassGenericPassword(), forKey: _kSecClass() as NSCopying)
    queryDict.setObject(persistentRef, forKey: _kSecValuePersistentRef() as NSCopying)

    let resultCode = SecItemUpdate(queryDict as CFDictionary, attributesToUpdate as CFDictionary)
    return (resultCode == OSStatus(errSecSuccess))
}

func deleteKeychainItemForPersistentRef(persistentRef: NSData) -> Bool {
    let queryDict = NSMutableDictionary()
    queryDict.setObject(_kSecClassGenericPassword(), forKey: _kSecClass() as NSCopying)
    queryDict.setObject(persistentRef, forKey: _kSecValuePersistentRef() as NSCopying)

    let resultCode = SecItemDelete(queryDict as CFDictionary)
    return (resultCode == OSStatus(errSecSuccess))
}
