import Foundation
import SwiftLMDB

public protocol SimpleStore {
    associatedtype Collection: SimpleCollection
    func createCollection(_ name: String) throws
    func getCollection(_ name: String) throws -> Collection?
    func read<R>(_ transactionBlock: (Collection.Transaction) throws -> R) throws -> R
    func write<R>(_ transactionBlock: (Collection.Transaction) throws -> R) throws -> R
}
