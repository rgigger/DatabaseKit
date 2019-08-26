import XCTest
@testable import database_kit

final class marksTests: XCTestCase {
    
    struct BookMark: Codable {
        let href: String
        let description: String
        let created: Date = Date()
        let updated: Date = Date()
        let tags: [String]
    }

    class BookMarkCollection: BaseCollection<BookMark> {
        let updatedIndex: BaseIndex
        init(store: SimpleStore) {
            let formatter = ISO8601DateFormatter()
            self.updatedIndex = BaseIndex("bookmarks_updated", store: store)
            super.init("bookmarks", store: store)
            // This is how we maintain the index. We need to try to abstract as much
            // of this as possible into BaseCollection
            self.addAfterSetTrigger { (key, new, old) in
                debugPrint(key, new, old as Any)
                
                //
                // This entire section will create race conditions in a multi-threaded environment. There will be a
                // brief period where the record has changed but the indexes aren't updated yet. There are any number
                // of ways to fix this:
                //
                // 1. Use an underlying data store that has transactions built into it.
                // 2. Build an underlying transaction layer yourself that can be layered onto a more basic
                //    key value store.
                // 3. Serialize all of the operations so there can be no race conditions. The easiest way to
                //    do this would be to run always run them all on the same thread.
                // 4. To make the below work the transaction should actually be started from the top level operation
                //    (create, UpdateOne, createOrUpdateOne) and then the transaction should be passed down through each level
                //    from there to here.
                //
                
                //
                // This is also really the logic for a unique index. Most indexes, and specifically
                // one on this field will need to be able to store multiple values for the same key.
                //
                // 0.0 import the btree stuff and write some tests for it that will serve as examples of
                //     what we need to do later. See playgrounds/spm-test for some examples
                //
                // 1. Create SimpleIndex and SimpleUniqueIndex
                // 2. Import the btree package with spm
                // 3. Use b-trees in both SimpleIndex and SimpleUniqueIndex
                // 4. Both should be capable of returning multiple results. Unique indexes might still
                //    want you to return the values for a range of keys. Regular indexes might also return
                //    multiple results for a single key.
                //    a. Unique should have
                //       - set(indexKey, primaryKey)
                //       - delete(indexKey) -> oldPrimaryKey
                //       - get(indexKey) -> primaryKey
                //       - getAll(start, end) -> [primaryKey]
                //    b. Regular should have
                //       - add(indexKey, primaryKey): this may create multiple results per indexKey
                //       - delete(indexKey, primaryKey): this will delete a single result for a specific indexKey, not all of them
                //       - getAll(for: indexKey) -> [primaryKey]
                //       - getAll(start, end) -> [primaryKey]
                // 5. BaseIndex and BaseUniqueIndex should wrap these and also:
                //    a. Hold a reference to the BaseCollection that owns the index.
                //    b. Have a pseudo-virtual method getIndexKey(forRecord: T) -> String
                //    c. Have a method updateIndex(newRecord: T, oldRecord: T?)
                //       - call getIndexKey(forRecord: T) to get the indexKey
                //       - call self.collection.getKey(forRecord: T) to get the primary key
                //       - do the same for the old record if it exists
                //       - as below, just stop if the value to be indexed hasn't changed otherwise remove the old ones if it exists and add the new ones
                // 6. BaseCollection needs an addIndex method that:
                //      - is called in the BaseCollection subclass initialize as self.addIndex(...)
                //      - accepts index: Subclass of BaseIndex, this will be created in the intializer before being passed in
                //      - adds the index to an array of indexes
                //      - adds an afterSet trigger that will call updateIndex
                // 7. Create subclasses of BaseIndex and BaseUniqueIndex that take a keyPath for the model
                //    in the initilazer and use that to implement getIndexKey
                
                // if the indexed value hasn't changed, do nothing
                if new.updated == old?.updated { return }
                
                // if there was an old value (which we now know has changed in the new record)
                // then we need to delete the old references to it
                if let oldUpdated = old?.updated {
                    self.updatedIndex.delete(key: formatter.string(from: oldUpdated))
                }
                
                // map the updated date to the primary key
                // fixme: this will need to be updated for non-unique indexes
                //        we should probably have BaseIndex (uses a b-tree) and BaseUniquIndex (uses a Map)
                self.updatedIndex.set(key: formatter.string(from: new.updated), value: key)
            }
        }
        override func getKey(forModel model: BookMark) -> String {
            return model.href
        }
    }

    class AppDatabase {
        private var store: SimpleStore
        var bookmarks: BookMarkCollection
        init(store: SimpleStore) {
            self.store = store
            self.bookmarks = BookMarkCollection(store: store)
        }
    }

    func testCreate() {
        let store = SimpleStore()
        let db = AppDatabase(store: store);
        let bookmark = BookMark(
            href: "https://newrepublic.com/article/144739/liberals-get-wrong-identity-politics",
            description: "What Liberals Get Wrong About Identity Politics | The New Republic",
            tags: []
        )
        try! db.bookmarks.create(bookmark)
    }

//    func testCrudMethods() {
//        let store = SimpleStore()
//        let db = AppDatabase(store: store);
//
//        let findByIdCard = Card(word: "findById", priority: 1)
//        try! db.cards.create(findByIdCard)
//        let loadedFindByIdCard = try! db.cards.find(byKey: findByIdCard.word)
//        XCTAssertEqual(loadedFindByIdCard.word, findByIdCard.word)
//        XCTAssertEqual(loadedFindByIdCard.priority, findByIdCard.priority)
//
//        XCTAssertThrowsError(try db.words.find(byKey: findByIdCard.word), "some message") { (error) in
//            XCTAssertTrue(error is DatabaseKitError, "Unexpected error type: \(type(of: error))")
//            XCTAssertEqual(error as? DatabaseKitError, .keyNotFound(collection: "words", key: findByIdCard.word))
//        }
//
//        for i in 0..<100 {
//            try! db.cards.create(Card(word: String(i), priority: Int(i/10)))
//        }
//
//        let priority7cards = db.cards.find { $1.priority == 7 }
//        for i in 0..<10 {
//            let card = priority7cards.first(where: { (card) in
//                card.word == "7\(i)"
//            } )
//            XCTAssertEqual(card?.priority, 7)
//        }
//
//        // fixme: add test cases for update and createOrUpdateOne
//    }
    
    func testTests() {
        XCTAssertTrue(true)
    }

    static var allTests = [
        ("testTests", testTests),
    ]
}
