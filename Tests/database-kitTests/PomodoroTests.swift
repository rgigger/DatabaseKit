import XCTest
@testable import DatabaseKit

final class PomodoroTests: XCTestCase {

    struct Tomato: Codable {
        let start: Date
        let end: Date
        var canceled: Bool
    }

    func GetTomatoKey(_ model: Tomato) -> String {
        return String(model.start.timeIntervalSince1970)
    }

    class TomatoCollection: BaseCollection<Tomato> {
        init(store: SimpleStore) throws {
            try super.init("tomatoes", store: store)
        }
        override func getKey(forModel model: Tomato) -> String {
            return String(model.start.timeIntervalSince1970)
        }
    }

    enum TomatoError: Error {
        case activeTomatoAlreadyExists
        case multipleActiveTomatoes
        case noActiveTomatoes
    }

    class PomodoroDB {
        private var store: SimpleStore
        var tomatoes: TomatoCollection
        init(store: SimpleStore) throws {
            self.store = store
            try self.tomatoes = TomatoCollection(store: store)
        }
        func getActiveTomato() throws -> Tomato? {
            let active = try self.tomatoes.find { (key, val) -> Bool in
                return val.canceled == false && val.end > Date()
            }
            guard active.count <= 1 else {
                throw TomatoError.multipleActiveTomatoes
            }
            if active.count == 0 {
                return nil
            }
            // active.count == 1
            return active[0]
        }
        func start() throws -> Tomato {
            let maybeActiveTomato = try getActiveTomato()
            guard let activeTomato = maybeActiveTomato else {
                let twentyFiveMinutes: TimeInterval = 60 * 25
                let tomato = Tomato(
                    start: Date(timeIntervalSinceNow: 0),
                    end: Date(timeIntervalSinceNow: twentyFiveMinutes),
                    canceled: false
                )
                try self.tomatoes.create(tomato)
                return tomato
            }
            return activeTomato
        }
        func cancel() throws {
            let maybeActiveTomato = try getActiveTomato()
            guard var activeTomato = maybeActiveTomato else {
                throw TomatoError.noActiveTomatoes
            }
            activeTomato.canceled = true
            try tomatoes.updateOne(activeTomato)
        }
        func today() {

        }
    }

    func testMethods() {
        do {
            let (_, db) = try setupDatabase()

            // one completed tomato
            _ = try addTomato(tomatoes: db.tomatoes, start: -1*60*500) // 500 minutes ago
            // one canceled tomato that would otherwise be active
            _ = try addTomato(tomatoes: db.tomatoes, start: -1*60*10, canceled: true) // 10 minutes ago
            // one active tomato
            let correctTomato = try addTomato(tomatoes: db.tomatoes, start: -1*60*5) // 5 minutes ago

            // make sure that we can correctly detect the active tomato
            let retrievedTomato = try db.getActiveTomato()
            guard let activeTomato = retrievedTomato else {
                XCTAssertNotNil(retrievedTomato)
                return
            }
            XCTAssertEqual(GetTomatoKey(activeTomato), GetTomatoKey(correctTomato))

            // cancel the active tomato
            try db.cancel()
            let noTomato = try db.getActiveTomato()
            XCTAssertNil(noTomato)


        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }


    func setupDatabase() throws -> (SimpleStore, PomodoroDB) {
        let store = try LmdbStore(path: "/Users/rick/personal/dbs/PomodoroDB")
        let db = try PomodoroDB(store: store);
        try db.tomatoes.empty()

        return (store, db)
    }

    func addTomato(tomatoes: TomatoCollection, start: TimeInterval, canceled: Bool = false) throws -> Tomato {
        let twentyFiveMinutes: TimeInterval = 60 * 25
        let tomato = Tomato(
            start: Date(timeIntervalSinceNow: start),
            end: Date(timeIntervalSinceNow: start + twentyFiveMinutes),
            canceled: canceled
        )
        try tomatoes.create(tomato)
        return tomato
    }


    func testTests() {
        XCTAssertTrue(true)
    }

    static var allTests = [
        ("testTests", testTests),
    ]
}

            let tm: Tomato = model
            let str: String = GetTomatoKey(model)

dump(retrievedTomato.start.timeIntervalSinceNow/60)
dump(retrievedTomato.end.timeIntervalSinceNow/60)
dump(correctTomato.start.timeIntervalSinceNow/60)

        do {
            let tomato = Tomato(
                start: Date(timeIntervalSinceNow: 0),
                end: Date(timeIntervalSinceNow: 60 * 25), // 25 minutes
                canceled: false
            )
            try db.tomatoes.create(tomato)
            debugPrint("begin finding tomatoes")
            let tomatoes = try db.tomatoes.find({ (key, val) -> Bool in
                // debugPrint("key:", key, "val:", val)
                return true
            })
            dump(tomatoes)
            debugPrint("done finding tomatoes")


        } catch {
            XCTFail(error.localizedDescription)
        }
        
