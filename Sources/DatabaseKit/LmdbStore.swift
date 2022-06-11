import Foundation
import SwiftLMDB

public class LmdbStore: SimpleStoreBase<LmdbCollection> {
    let environment: Environment
    public init(path: String, readOnly: Bool = false) throws {
        let oneK: size_t = 1024
        let oneM = 1024*oneK
        let oneG = 1024*oneM
        let flags: Environment.Flags = readOnly ? [.readOnly, .noLock] : []

        environment = try Environment(path: path, flags: flags, maxDBs: 64, maxReaders: 126, mapSize: oneG)
    }
    override public func newCollection(name: String) throws -> LmdbCollection {
        return try LmdbCollection(name: name, environment: environment)
    }

    override public func read<R>(_ transactionBlock: (LmdbTransaction) throws -> R) throws -> R {
        var result: R? = nil
        try environment.read(transactionBlock: { (swiftLMDBTransaction) throws -> Transaction.Action in
            let lmdbTransaction = try LmdbTransaction(swiftLMDBTransaction)
            do {
                result = try transactionBlock(lmdbTransaction)
                return .commit
            } catch {
                return .abort
            }
        })

        guard let result = result else {
            throw DatabaseKitError.shouldNeverHappen
        }

        return result
    }

    override public func write<R>(_ transactionBlock: (LmdbTransaction) throws -> R) throws -> R {
        var result: R? = nil
        try environment.write(transactionBlock: { (swiftLMDBTransaction) throws -> Transaction.Action in
            let lmdbTransaction = try LmdbTransaction(swiftLMDBTransaction)
            do {
                result = try transactionBlock(lmdbTransaction)
                return .commit
            } catch {
                return .abort
            }
        })

        guard let result = result else {
            throw DatabaseKitError.shouldNeverHappen
        }

        return result
    }

    @available(*, deprecated, message: "Use the other one")
    public func write(transactionBlock: (LmdbTransaction) -> LmdbTransaction.Action) throws {
        try environment.write(transactionBlock: { (swiftLMDBTransaction) throws -> Transaction.Action in
            let lmdbTransaction = try LmdbTransaction(swiftLMDBTransaction)
            let result = transactionBlock(lmdbTransaction)
            return result.mapped
        })
    }
}
