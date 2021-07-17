//
//  File.swift
//  
//
//  Created by Rick Gigger on 7/11/21.
//

import Foundation
import System
import CryptoKit
import AppleArchive

/// Encrypt the given object that must be Codable and
/// return the encrypted object as a base64 string
/// - Parameters:
///   - object: The object to encrypt
///   - key: The key to use for the encryption
func encrypt(data: Data, withKey key: SymmetricKey) throws -> Data {
    // Encrypt the userData
    let encryptedData = try ChaChaPoly.seal(data, using: key)
    // Convert the encryptedData to a base64 string which is the
    // format that it can be transported in
    return encryptedData.combined
}

/// Decrypt a given string into a Codable object
/// - Parameters:
///   - type: The type of the resulting object
///   - string: The string to decrypt
///   - key: The key to use for the decryption
func decrypt(data: Data, withKey key: SymmetricKey) throws -> Data {
    // Put the data in a sealed box
    let box = try ChaChaPoly.SealedBox(combined: data)
    // Extract the data from the sealedbox using the decryption key
    let decryptedData = try ChaChaPoly.open(box, using: key)
    return decryptedData
}

public class LOFileCollection: LargeObjectCollection {
    public typealias Transaction = LOFileTransaction
    let name: String
    let directory: URL
    let encryptionKey: SymmetricKey?
    
    public enum Error: Swift.Error {
        case unableToCreateFileStream
        case unableToCreateEncryptionStream
        case unableToCreateDecryptionContext
    }
    
    init(name: String, directory: URL, encryptionKey: SymmetricKey?) throws {
        self.name = name
        self.directory = directory
        self.encryptionKey = encryptionKey
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    public func exists(key: String) throws -> Bool {
        let newFileLocation = directory.appendingPathComponent(key)
        return FileManager.default.fileExists(atPath: newFileLocation.path)
    }
    
    private func copyEncrypted(source: URL, destination: URL) throws {
        guard let encryptionKey = encryptionKey else {
            return
        }

        let sourceFileData = try Data(contentsOf: source)
        let encryptedData = try encrypt(data: sourceFileData, withKey: encryptionKey)
        try encryptedData.write(to: destination)
    }
    
    private func copyDecrypted(source: URL, destination: URL) throws {
        guard let encryptionKey = encryptionKey else {
            return
        }

        let sourceFileData = try Data(contentsOf: source)
        let decryptedData = try decrypt(data: sourceFileData, withKey: encryptionKey)
        try decryptedData.write(to: destination)
    }
    
    public func upload(key: String, fromSource source: URL, withTransaction transaction: Transaction?) throws {
        let newFileLocation = directory.appendingPathComponent(key)
        // this stuff really should be abstracted out and made to be modular in the same way that BaseCollection abstracts the encoding
        // stuff out for SimpleCollections
        if encryptionKey != nil {
            
            try copyEncrypted(source: source, destination: newFileLocation)
        } else {
            print("source = \(source), newFileLocation = \(newFileLocation)");
            try FileManager.default.copyItem(at: source, to: newFileLocation)
        }
    }
    public func download(key: String, toDestination destination: URL, withTransaction transaction: Transaction?) throws {
        let existingFileLocation = directory.appendingPathComponent(key)
        if encryptionKey != nil {
            
            try copyDecrypted(source: existingFileLocation, destination: destination)
            
        } else {
            try FileManager.default.copyItem(at: existingFileLocation, to: destination)
        }
    }
    public func delete(key: String, withTransaction transaction: Transaction?) throws {
        let existingFileLocation = directory.appendingPathComponent(key)
        try FileManager.default.removeItem(at: existingFileLocation)
    }
}
