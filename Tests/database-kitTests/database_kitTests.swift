import XCTest
@testable import DatabaseKit

final class database_kitTests: XCTestCase {
    
    struct Card : Codable {
        let word : String
        let priority : Int
    }

    class CardCollection: BaseCollection<Card> {
        init(store: SimpleStore) {
            let name = "cards"
            super.init(name, store: store)
        }
        override func getKey(forModel model: Card) -> String {
            return model.word
        }
    }

    struct Word : Codable {
        let word : String
        let updated : Date
    }

    class WordCollection: BaseCollection<Word> {
        init(store: SimpleStore) {
            let name = "words"
            super.init(name, store: store)
        }
        override func getKey(forModel model: Word) -> String {
            return model.word
        }
    }
    
    class AppDatabase {
        private var store: SimpleStore
        var cards: CardCollection
        var words: WordCollection
        init(store: SimpleStore) {
            self.store = store
            self.cards = CardCollection(store: store)
            self.words = WordCollection(store: store)
        }
    }
    
    func testBaseCollectionGetAndSet() {
        
        let store = MemoryStore()
        let db = AppDatabase(store: store);

        let worldCard = Card(word: "world", priority: 1)
        db.cards.set(key: worldCard.word, value: worldCard)
        let loadedWorldCard = db.cards.get(worldCard.word)
        XCTAssertEqual(loadedWorldCard?.word, worldCard.word)
        XCTAssertEqual(loadedWorldCard?.priority, worldCard.priority)

        let charWord = Word(word: "char", updated: Date())
        db.words.set(key: charWord.word, value: charWord)
        let loadedCharWord = db.words.get(charWord.word)
        XCTAssertEqual(loadedCharWord?.word, charWord.word)
        XCTAssertEqual(loadedCharWord?.updated, charWord.updated)

        let loadedBadWord = db.words.get(worldCard.word)
        XCTAssertNil(loadedBadWord)
    }
    
    func testCrudMethods() {
        let store = MemoryStore()
        let db = AppDatabase(store: store);

        let findByIdCard = Card(word: "findById", priority: 1)
        try! db.cards.create(findByIdCard)
        let loadedFindByIdCard = try! db.cards.find(byKey: findByIdCard.word)
        XCTAssertEqual(loadedFindByIdCard.word, findByIdCard.word)
        XCTAssertEqual(loadedFindByIdCard.priority, findByIdCard.priority)

        XCTAssertThrowsError(try db.words.find(byKey: findByIdCard.word), "some message") { (error) in
            XCTAssertTrue(error is DatabaseKitError, "Unexpected error type: \(type(of: error))")
            XCTAssertEqual(error as? DatabaseKitError, .keyNotFound(collection: "words", key: findByIdCard.word))
        }

        for i in 0..<100 {
            try! db.cards.create(Card(word: String(i), priority: Int(i/10)))
        }

        let priority7cards = db.cards.find { $1.priority == 7 }
        for i in 0..<10 {
            let card = priority7cards.first(where: { (card) in
                card.word == "7\(i)"
            } )
            XCTAssertEqual(card?.priority, 7)
        }
        
        // fixme: add test cases for update and createOrUpdateOne
    }

    static var allTests = [
        ("testBaseCollectionGetAndSet", testBaseCollectionGetAndSet),
    ]
}
