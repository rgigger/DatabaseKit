//
//  File.swift
//  
//
//  Created by Rick Gigger on 7/11/21.
//

import Foundation
import CryptoKit

public class LOFileStore: LargeObjectStoreBase<LOFileCollection> {
    let directory: URL
    let encryptionKey: SymmetricKey?
    public init(path: String, password: String?) throws {
        directory = URL(fileURLWithPath: path)
        if let password = password {
            self.encryptionKey = symmetricKeyFromPassword(password)
        } else {
            self.encryptionKey = nil
        }
    }
    override public func newCollection(name: String) throws -> LOFileCollection {
        return try LOFileCollection(name: name, directory: directory.appendingPathComponent(name), encryptionKey: encryptionKey)
    }
}

/// Create an ecnryption key from a given password
/// - Parameter password: The password that is used to generate the key
func symmetricKeyFromPassword(_ password: String) -> SymmetricKey {
    // Create a SHA256 hash from the provided password
    let hash = SHA256.hash(data: password.data(using: .utf8)!)
    // Convert the SHA256 to a string. This will be a 64 byte string
    let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
    // Convert to 32 bytes
    let subString = String(hashString.prefix(32))
    // Convert the substring to data
    let keyData = subString.data(using: .utf8)!
    // Create the key use keyData as the seed
    return SymmetricKey(data: keyData)
}
