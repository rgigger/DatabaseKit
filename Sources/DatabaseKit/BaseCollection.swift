//
//  File.swift
//  
//
//  Created by Rick Gigger on 8/25/19.
//

import Foundation

// MARK: - the foundational types

/// Some shared types that need to be correlated across many of the below protocols
public protocol RecordCollectionBaseTypes {
    associatedtype ModelType
    associatedtype CollectionType: SimpleCollection
    typealias afterSetTrigger = (String, ModelType, ModelType?, CollectionType.Transaction?) throws -> Void
}

/// The basic API for how collections are to be accessed
public protocol RecordCollection: RecordCollectionBaseTypes {
    func getKey(forModel model: ModelType) -> String
    func decode(data: Data) throws -> ModelType
    func encode(model: ModelType) throws -> Data
    func get(_ key: String, withTransaction transaction: CollectionType.Transaction?) throws -> ModelType?
    func set(key: CustomStringConvertible, value: ModelType, withTransaction transaction: CollectionType.Transaction?) throws
    mutating func addAfterSetTrigger(_ trigger: @escaping afterSetTrigger)
    func _set(key: String, value: ModelType, oldValue: ModelType?, withTransaction transaction: CollectionType.Transaction?) throws
    func create(_ model: ModelType, withTransaction transaction: CollectionType.Transaction?) throws
    func updateOne(_ model: ModelType, withTransaction transaction: CollectionType.Transaction?) throws
    func createOrUpdateOne(_ model: ModelType, withTransaction transaction: CollectionType.Transaction?) throws
    func find(byKey key: CustomStringConvertible, withTransaction transaction: CollectionType.Transaction?) throws -> ModelType
    func find(_ filter: (String, ModelType) -> Bool, withTransaction transaction: CollectionType.Transaction?) throws -> [ModelType]
    func each(withTransaction transaction: CollectionType.Transaction?) throws -> AnySequence<(key: String, value: ModelType)>
    func eachDocument(withTransaction transaction: CollectionType.Transaction?) throws -> AnySequence<ModelType>
}


// MARK: - helpers for supplying `getKey:forModel`

public protocol StringIdentifiable {
    associatedtype ID : CustomStringConvertible
    var id: Self.ID { get }
}


/// If this collection's model conforms to `Identifiable` and the type of the ID can be converted to a string you can supply `getKey:forModel`
/// by simply adding extending IdentifiableCollection
public protocol StringIdentifiableCollection: RecordCollectionBaseTypes {
    func getKey(forModel model: ModelType) -> String
}
public extension StringIdentifiableCollection where ModelType: StringIdentifiable {
    func getKey(forModel model: ModelType) -> String {
        return model.id.description
    }
}


// MARK: - helpers for supplying `decode:data` and `encode:model`

public protocol DataEncoder {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}
extension JSONEncoder: DataEncoder {}

public protocol DataDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}
extension JSONDecoder: DataDecoder {}

/// This simplies the process of supplying a serializer to the collections
public protocol CodedCollection: RecordCollectionBaseTypes where ModelType: Codable {
    var encoder: DataEncoder { get }
    var decoder: DataDecoder { get }
}

/// By conforming to `CodedCollection` you automatically supply these two methods from `RecordCollection`
extension CodedCollection {
    public func decode(data: Data) throws -> ModelType {
        try decoder.decode(ModelType.self, from: data)
    }
    public func encode(model: ModelType) throws -> Data {
        try encoder.encode(model)
    }
}

/// Create a singleton that allows us to access these on a global basis without having to recreate
/// them for each object that needs to use them
class JSONDataCoder {
    private init() {}
    public let encoder: DataEncoder = JSONEncoder()
    public let decoder: DataDecoder = JSONDecoder()
    static let shared = JSONDataCoder()
}

/// By conforming to `JSONCodedCollection` you automatically supply the `encoder` and `decoder` properties
/// that are necessary for `CodedCollection` and get conformance to `CodedCollection` which supplies the
/// `decode` and `encode` methods that are required by `RecordCollection`
public protocol JSONCodedCollection: CodedCollection {}
public extension JSONCodedCollection {
    var encoder: DataEncoder {
        return JSONDataCoder.shared.encoder
    }
    var decoder: DataDecoder {
        return JSONDataCoder.shared.decoder
    }
}


// MARK: - helpers for supplying all of the CRUD methods

/// Some basic properties that, if implemented make it possible to add implementations for many of methods required by `RecordCollection`
public protocol RecordCollectionDefaultStorage: RecordCollectionBaseTypes {
    var name: String { get set }
    var collection: CollectionType { get }
    var afterSetTriggers: [afterSetTrigger] { get set }
}

/// If you supply the properties required by `RecordCollectionDefaultStorage` you can supply implementations for all of the CRUD methods
/// required by `RecordCollection`
public protocol RecordCollectionDefaultCRUD: RecordCollection, RecordCollectionDefaultStorage {}
extension RecordCollectionDefaultCRUD {
    public func get(_ key: String, withTransaction transaction: CollectionType.Transaction?) throws -> ModelType? {
        guard let loaded = try self.collection.get(key: key, withTransaction: transaction) else { return nil }
        return try decode(data: loaded)
    }
    
    public func set(key: CustomStringConvertible, value: ModelType, withTransaction transaction: CollectionType.Transaction?) throws {
        let json = try encode(model: value)
        try self.collection.set(key: key.description, data: json, withTransaction: transaction)
    }
    
    public mutating func addAfterSetTrigger(_ trigger: @escaping afterSetTrigger) {
        self.afterSetTriggers.append(trigger)
    }
    
    public func _set(key: String, value: ModelType, oldValue: ModelType?, withTransaction transaction: CollectionType.Transaction?) throws {
        try self.set(key: key, value: value, withTransaction: transaction)
        for trigger in self.afterSetTriggers {
            try trigger(key, value, oldValue, transaction)
        }
    }
    
    public func create(_ model: ModelType, withTransaction transaction: CollectionType.Transaction?) throws {
        let key = self.getKey(forModel: model)
        let old = try self.get(key, withTransaction: transaction)
        guard old == nil else { throw DatabaseKitError.keyAlreadyExists(collection: self.name, key: key) }
        try self._set(key: key, value: model, oldValue: nil, withTransaction: transaction)
    }
    
    public func updateOne(_ model: ModelType, withTransaction transaction: CollectionType.Transaction?) throws {
        let key = self.getKey(forModel: model)
        guard let old = try self.get(key, withTransaction: transaction) else {
            throw DatabaseKitError.keyNotFound(collection: self.name, key: key)
        }
        try self._set(key: key, value: model, oldValue: old, withTransaction: transaction)
    }
    
    public func createOrUpdateOne(_ model: ModelType, withTransaction transaction: CollectionType.Transaction?) throws {
        let key = self.getKey(forModel: model)
        let old = try self.get(key, withTransaction: transaction)
        try self._set(key: key, value: model, oldValue: old, withTransaction: transaction)
    }
    
    public func find(byKey key: CustomStringConvertible, withTransaction transaction: CollectionType.Transaction?) throws -> ModelType {
        let stringKey: String = key.description
        guard let model = try self.get(stringKey, withTransaction: transaction) else {
            throw DatabaseKitError.keyNotFound(collection: self.name, key: stringKey)
        }
        return model;
    }
    
    public func find(_ filter: (String, ModelType) -> Bool) throws -> [ModelType] {
        return try self.find(filter, withTransaction: nil)
    }
    
    public func find(_ filter: (String, ModelType) -> Bool, withTransaction transaction: CollectionType.Transaction?) throws -> [ModelType] {
        var results: [ModelType] = []
        try self.collection.each(withTransaction: transaction) { (key, data) in
            do {
                let record = try decode(data: data)
                if filter(key, record) {
                    results.append(record)
                }
            } catch {
                debugPrint(error)
            }
            return true
        }
        return results
    }

    public func each(withTransaction transaction: CollectionType.Transaction?) throws -> AnySequence<(key: String, value: ModelType)> {
        typealias InElement = (key: Data, value: Data)
        typealias OutElement = (key: String, value: ModelType)

        let dataIterator = try self.collection.each(withTransaction: transaction).makeIterator()
        let collectionIterator = TransformIterator(dataIterator: dataIterator) { (element: InElement) -> OutElement in
            return (key: String(data: element.key)!, value: try! decode(data: element.value))
        }
        return AnySequence(collectionIterator)
    }

    public func eachDocument(withTransaction transaction: CollectionType.Transaction?) throws -> AnySequence<ModelType> {
        typealias InElement = (key: Data, value: Data)
        typealias OutElement = ModelType

        let dataIterator = try self.collection.each(withTransaction: transaction).makeIterator()
        let collectionIterator = TransformIterator(dataIterator: dataIterator) { (element: InElement) -> OutElement in
            return try! decode(data: element.value)
        }
        return AnySequence(collectionIterator)
    }

    public func empty() throws {
        try collection.empty()
    }
}

public class TransformIterator<InElement, OutElement>: Sequence, IteratorProtocol {
    public typealias Element = OutElement

    let dataIterator: AnyIterator<InElement>
    let transform: (InElement) -> OutElement

    init(dataIterator: AnyIterator<InElement>, _ decode: @escaping (InElement) -> OutElement) {
        self.dataIterator = dataIterator
        self.transform = decode
    }

    public func next() -> Element? {
        guard let element = dataIterator.next() else {
            return nil
        }

        return transform(element)
    }
}



// MARK: - Base class for pulling together a solid default configuration for a collection

/// BaseCollection sets up all of the types, provides the storage properties necessary for conformance with `RecordCollectionDefaultStorage`
/// and initializes them.
open class BaseCollection<T, SS: SimpleStore>: RecordCollectionDefaultStorage {
    public typealias ModelType = T
    public typealias CollectionType = SS.Collection
    public var name: String
    let store: SS
    public var collection: SS.Collection
    public var afterSetTriggers: [afterSetTrigger] = []
    
    public init(_ name: String, store: SS) throws {
        self.name = name
        self.store = store
        try self.store.createCollection(name)
        self.collection = try self.store.getCollection(name)!
    }

    // TODO: ideally this would be on RecordCollectionDefaultCRUD
    //       in order to do that though we need to get the store onto the protocols and
    //       I just don't have it any me to do that right now
    public func read<R>(_ transactionBlock: (CollectionType.Transaction) throws -> R) throws -> R {
        return try store.read(transactionBlock)
    }

    public func write<R>(_ transactionBlock: (CollectionType.Transaction) throws -> R) throws -> R {
        return try store.write(transactionBlock)
    }
}

open class BaseDatabase<SS: SimpleStore> {
    public let store: SS

    public init(store: SS) {
        self.store = store
    }

    public func read<R>(_ transactionBlock: (SS.Collection.Transaction) throws -> R) throws -> R {
        return try store.read(transactionBlock)
    }

    public func write<R>(_ transactionBlock: (SS.Collection.Transaction) throws -> R) throws -> R {
        return try store.write(transactionBlock)
    }
}
