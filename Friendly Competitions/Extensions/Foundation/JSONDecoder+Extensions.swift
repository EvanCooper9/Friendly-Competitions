import Foundation

extension JSONDecoder {

    private static let supportedDateFormatters: [DateFormatter] = [
        .dateDashed,
        .full
    ]

    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            for formatter in supportedDateFormatters {
                if let date = formatter.date(from: string) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to convert '\(string)' to a Date, does not match any expected formats"
            )
        }
        return decoder
    }()
}
