import XCTest
import CryptoKit
@testable import DatabaseKit

public protocol DBBaseModel: StringIdentifiable, Codable {}

public func fileToHashString(url: URL) throws -> String {
    let data = try Data(contentsOf: url)
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02hhx", $0) }.joined()
}

public class DBBaseCollection<T: DBBaseModel>:
    BaseCollection<T, LmdbStore>,
    StringIdentifiableCollection,
    JSONCodedCollection,
    RecordCollectionDefaultCRUD
{}

final class database_kitTests: XCTestCase {

    let encryptionPassword = "super secret"

     struct Card : DBBaseModel {
        var id: String { get { return word } }
         let word : String
         let priority : Int
         let imageName: String?
     }

    class CardCollection: DBBaseCollection<Card> {
        init(store: LmdbStore) throws {
            let name = "cards"
            try super.init(name, store: store)
        }
    }

    struct Word : DBBaseModel {
        var id: String { get { return word } }
        let word : String
        let updated : Date
    }

    class WordCollection: DBBaseCollection<Word> {
        init(store: LmdbStore) throws {
            let name = "words"
            try super.init(name, store: store)
        }

        // override func getKey(forModel model: Word) -> String {
        //     return model.word
        // }
    }

    class AppDatabase {
        private var store: LmdbStore
        private var loStore: LOFileStore
        var cards: CardCollection
        var words: WordCollection
        var files: LOFileCollection
        init(store: LmdbStore, loStore: LOFileStore) throws {
            self.store = store
            self.loStore = loStore
            self.cards = try CardCollection(store: store)
            self.words = try WordCollection(store: store)
            self.files = try loStore.newCollection(name: "files")
            
            self.cards.addAfterSetTrigger { (key: String, value: Card, oldValue: Card?, transaction: LmdbTransaction?) in
                try self.words.createOrUpdateOne(Word(word: value.word, updated: Date()), withTransaction: transaction)
            }
        }
        
        func uploadFile(url: URL) throws -> String {
            let filename = try fileToHashString(url: url)
            if !(try files.exists(key: filename)) {
                try files.upload(key: filename, fromSource: url, withTransaction: nil)
            }
            return filename
        }
    }

    func testBaseCollectionGetAndSet() throws {
        let dirs = try setupDirectories()
        let db = try getDb(storeDir: dirs.storeDir, loStoreDir: dirs.loStoreDir)

        let worldCard = Card(word: "world", priority: 1, imageName: nil)
        try db.cards.set(key: worldCard.word, value: worldCard, withTransaction: nil)
        let loadedWorldCard = try db.cards.get(worldCard.word, withTransaction: nil)
        XCTAssertEqual(loadedWorldCard?.word, worldCard.word)
        XCTAssertEqual(loadedWorldCard?.priority, worldCard.priority)

        let charWord = Word(word: "char", updated: Date())
        try db.words.set(key: charWord.word, value: charWord, withTransaction: nil)
        let loadedCharWord = try db.words.get(charWord.word, withTransaction: nil)
        XCTAssertEqual(loadedCharWord?.word, charWord.word)
        XCTAssertEqual(loadedCharWord?.updated, charWord.updated)

        let loadedBadWord = try db.words.get(worldCard.word, withTransaction: nil)
        XCTAssertNil(loadedBadWord)
    }

    func testCrudMethods() throws {
        let dirs = try setupDirectories()
        let db = try getDb(storeDir: dirs.storeDir, loStoreDir: dirs.loStoreDir)
        
        let testPhotoURL = Bundle.module.url(forResource: "test", withExtension: "jpg")!
        let imageName = try db.uploadFile(url: testPhotoURL)

        let findByIdCard = Card(word: "findById", priority: 1, imageName: imageName)
        debugPrint(findByIdCard)
        try db.cards.create(findByIdCard, withTransaction: nil)
        let loadedFindByIdCard = try db.cards.find(byKey: findByIdCard.word, withTransaction: nil)
        XCTAssertEqual(loadedFindByIdCard.word, findByIdCard.word)
        XCTAssertEqual(loadedFindByIdCard.priority, findByIdCard.priority)

        let saveDir = dirs.baseDir
        let loadedImageName = loadedFindByIdCard.imageName!
        let loadedImageDest = saveDir.appendingPathComponent("test.jpg")
        print("loadedImageDest = \(loadedImageDest)")
        try db.files.download(key: loadedImageName, toDestination: loadedImageDest, withTransaction: nil)
        let downloadedFileHash = try fileToHashString(url: loadedImageDest)
        print("downloadedFileHash = \(downloadedFileHash)")
        XCTAssertEqual(downloadedFileHash, imageName)

        let badId = "bad-id"
        XCTAssertThrowsError(try db.words.find(byKey: badId, withTransaction: nil), "find:byKey not throwing error for unknown key") { (error) in
            XCTAssertTrue(error is DatabaseKitError, "Unexpected error type: \(type(of: error))")
            XCTAssertEqual(error as? DatabaseKitError, .keyNotFound(collection: "words", key: badId))
        }

        for i in 0..<100 {
            try! db.cards.create(Card(word: String(i), priority: Int(i/10), imageName: nil), withTransaction: nil)
        }

        let priority7cards = try db.cards.find({ $1.priority == 7 }, withTransaction: nil)
        for i in 0..<10 {
            let card = priority7cards.first(where: { (card) in
                card.word == "7\(i)"
            } )
            XCTAssertEqual(card?.priority, 7)
        }

        // fixme: add test cases for update and createOrUpdateOne
    }

    func testCollectionSequences() throws {
        let dirs = try setupDirectories()
        let db = try getDb(storeDir: dirs.storeDir, loStoreDir: dirs.loStoreDir)

        for i in 1 ... 10 {
            // print(i)
            try db.cards.set(key: String(i), value: Card(word: String(i), priority: 1, imageName: nil), withTransaction: nil)
        }

        let cardSequence = try db.cards.each(withTransaction: nil)
        let mostCards = cardSequence.filter { (key: String, value: Card) in
            return key != "7"
        }
        XCTAssertEqual(mostCards.count, 9)
    }


    func getDb(storeDir: URL, loStoreDir: URL) throws -> AppDatabase {
        let store = try LmdbStore(path: storeDir.path)
        let loStore = try LOFileStore(path: loStoreDir.path, password: encryptionPassword)
        let db = try AppDatabase(store: store, loStore: loStore);
        return db
    }

    func setupDirectories() throws -> (baseDir: URL, storeDir: URL, loStoreDir: URL) {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let envURL = tempURL.appendingPathComponent(randomString(length: 10))
        let storeURL = envURL.appendingPathComponent("store")
        let loStoreURL = envURL.appendingPathComponent("loStore")
        if FileManager.default.fileExists(atPath: storeURL.path) {
            try FileManager.default.removeItem(at: storeURL)
        }
        //try FileManager.default.createDirectory(atPath: storeURL.absoluteString, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(at: loStoreURL, withIntermediateDirectories: true, attributes: nil)

        let dirs = (baseDir: envURL, storeDir: storeURL, loStoreDir: loStoreURL)
        print(dirs)
        return dirs
    }

    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }

    static var allTests = [
        ("testBaseCollectionGetAndSet", testBaseCollectionGetAndSet),
    ]
}
