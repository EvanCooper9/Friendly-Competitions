import FirebaseFirestore
import XCTest

@testable import Friendly_Competitions

final class FirestoreDecoderTests: FCTestCase {

    func testThatItDecodesDatesProperly() throws {
        let encoder = Firestore.Encoder.custom
        let decoder = Firestore.Decoder.custom

        struct Model: Codable {
            let date: Date
            let optionalDate: Date?
            @PostDecoded<DateToStartOfDay, Date> var dateStart: Date
            @PostDecoded<DateToEndOfDay, Date> var dateEnd: Date
        }

        let date = Date.now

        let model = Model(date: date, optionalDate: date, dateStart: date, dateEnd: date)
        let data = try encoder.encode(model)
        let decodedModel = try decoder.decode(Model.self, from: data)

        XCTAssertEqual(decodedModel.date, date.toStartOfDay)
        XCTAssertEqual(decodedModel.optionalDate, date.toStartOfDay)
        XCTAssertEqual(decodedModel.dateStart, date.toStartOfDay)
        XCTAssertEqual(decodedModel.dateEnd, date.toEndOfDay)
    }
}

private extension Date {
    var toStartOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var toEndOfDay: Date {
        toStartOfDay.advanced(by: 23.hours + 59.minutes + 59.seconds)
    }
}
