import FirebaseFirestore
import XCTest

@testable import Friendly_Competitions

final class FirestoreEncoderTests: FCTestCase {

    func testThatItEncodesDatesProperly() throws {
        let encoder = Firestore.Encoder.custom

        struct Model: Codable {
            let date: Date
            let optionalDate: Date?
            @PostDecoded<DateToStartOfDay, Date> var dateStart: Date
            @PostDecoded<DateToEndOfDay, Date> var dateEnd: Date
        }

        let date = Date.now
        let dateString = DateFormatter.dateDashed.string(from: date)

        let model = Model(date: date, optionalDate: date, dateStart: date, dateEnd: date)

        let data = try encoder.encode(model)
        XCTAssertEqual(data["date"] as? String, dateString)
        XCTAssertEqual(data["optionalDate"] as? String, dateString)
        XCTAssertEqual(data["dateStart"] as? String, dateString)
        XCTAssertEqual(data["dateEnd"] as? String, dateString)
    }
}
