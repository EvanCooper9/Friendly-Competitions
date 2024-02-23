import ECNetworking
import Foundation

struct CollectionRequest<R: Decodable>: AuthenticatedRequest {

    typealias Response = [R]

    let path: String
    let filters: [CollectionFilter]

    private var documentPath: String? {
        guard let collectionIdentifier else { return nil }
        return path.before(suffix: "/" + collectionIdentifier)
    }

    private var collectionIdentifier: String? {
        guard let lastPart = path.split(separator: "/").last else { return nil }
        return String(lastPart)
    }

    struct StructuredQuery: Encodable {
        let `where`: Filter?
        let from: [CollectionSelector]

        struct Filter: Encodable {
            let fieldFilter: FieldFilter?
            let compositeFilter: CompositeFilter?

            struct FieldFilter: Encodable {
                let field: FieldReference
                let value: Value?
                let op: Operator

                struct FieldReference: Encodable {
                    let fieldPath: String
                }

                indirect enum Value: Encodable {
                    case string(String)
                    case int(Int)
                    case bool(Bool)
                    case array([Value])

                    func encode(to encoder: Encoder) throws {
                        var container = encoder.singleValueContainer()
                        switch self {
                        case .string(let string):
                            try container.encode(["stringValue": string])
                        case .int(let int):
                            try container.encode(["integerValue": int])
                        case .bool(let bool):
                            try container.encode(["booleanValue": bool])
                        case .array(let values):
                            try container.encode(["arrayValue": values])
                        }
                    }
                }

                enum Operator: String, Encodable {
                    case arrayContains = "ARRAY_CONTAINS"
                    case isEqualTo = "EQUAL"
                    case notIn = "NOT_IN"
                    case greaterThan = "GREATER_THAN"
                    case greaterThanOrEqualTo = "GREATER_THAN_OR_EQUAL"
                    case lessThan = "LESS_THAN"
                    case lessThanOrEqualTo = "LESS_THAN_OR_EQUAL"
                }
            }
        }

        struct CompositeFilter: Encodable {
            let op: Operation
            let filters: [Filter]

            enum Operation: String, Encodable {
                case and = "AND"
                case or = "OR"
            }
        }

        struct CollectionSelector: Encodable {
            let collectionId: String?
            let allDescendants: Bool
        }
    }

    enum CollectionFilter {
        case arrayContains(value: Any, property: String)
        case isEqualTo(value: Any, property: String)
        case notIn(values: [Any], property: String)
        case greaterThan(value: Any, property: String)
        case greaterThanOrEqualTo(value: Any, property: String)
        case lessThan(value: Any, property: String)
        case lessThanOrEqualTo(value: Any, property: String)

        var field: StructuredQuery.Filter.FieldFilter.FieldReference {
            switch self {
            case .arrayContains(_, let property): return .init(fieldPath: property)
            case .isEqualTo(_, let property): return .init(fieldPath: property)
            case .notIn(_, let property): return .init(fieldPath: property)
            case .greaterThan(_, let property): return .init(fieldPath: property)
            case .greaterThanOrEqualTo(_, let property): return .init(fieldPath: property)
            case .lessThan(_, let property): return .init(fieldPath: property)
            case .lessThanOrEqualTo(_, let property): return .init(fieldPath: property)
            }
        }

        var value: StructuredQuery.Filter.FieldFilter.Value? {
            func convert(value: Any) -> StructuredQuery.Filter.FieldFilter.Value? {
                if let string = value as? String {
                    return .string(string)
                } else if let int = value as? Int {
                    return .int(int)
                } else if let bool = value as? Bool {
                    return .bool(bool)
                } else if let array = value as? [Any] {
                    return .array(array.compactMap { convert(value: $0) })
                }
                return nil
            }
            switch self {
            case .arrayContains(let value, _):
                return convert(value: value)
            case .isEqualTo(let value, _):
                return convert(value: value)
            case .notIn(let values, _):
                return convert(value: values)
            case .greaterThan(let value, _):
                return convert(value: value)
            case .greaterThanOrEqualTo(let value, _):
                return convert(value: value)
            case .lessThan(let value, _):
                return convert(value: value)
            case .lessThanOrEqualTo(let value, _):
                return convert(value: value)
            }
        }

        var `operator`: StructuredQuery.Filter.FieldFilter.Operator {
            switch self {
            case .arrayContains: return .arrayContains
            case .isEqualTo: return .isEqualTo
            case .notIn: return .notIn
            case .greaterThan: return .greaterThan
            case .greaterThanOrEqualTo: return .greaterThanOrEqualTo
            case .lessThan: return .lessThan
            case .lessThanOrEqualTo: return .lessThanOrEqualTo
            }
        }
    }

    struct Body: Encodable {
        let structuredQuery: StructuredQuery
    }

    func response(from data: Data, with decoder: JSONDecoder) throws -> [R] {
        try decoder.decode([FirestoreDocumentContainer].self, from: data)
            .map(\.document)
            .compactMap { document -> R? in
                let pairs = document.fields.compactMap { key, value -> (String, Any)? in
                    (key, value.convertValueForJson)
                }
                let dictionary = Dictionary<String, Any>(uniqueKeysWithValues: pairs)
                let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
                return try R.decoded(from: jsonData, using: decoder)
            }
    }

    func buildRequest(with baseURL: URL) -> NetworkRequest {
        var topFilter: StructuredQuery.Filter?
        if let filter = filters.first, filters.count == 1 {
            topFilter = .init(
                fieldFilter: .init(
                    field: filter.field,
                    value: filter.value,
                    op: filter.operator
                ),
                compositeFilter: nil
            )
        } else if filters.isNotEmpty {
            topFilter = .init(
                fieldFilter: nil,
                compositeFilter: .init(
                    op: .and,
                    filters: filters.map { filter in
                            .init(
                                fieldFilter: .init(
                                    field: filter.field,
                                    value: filter.value,
                                    op: filter.operator
                                ),
                                compositeFilter: nil
                            )
                    }
                )
            )
        }

        let body = Body(
            structuredQuery: StructuredQuery(
                where: topFilter,
                from: [
                    .init(
                        collectionId: collectionIdentifier,
                        allDescendants: false
                    )
                ]
            )
        )

        var url = baseURL
        if let documentPath {
            url.append(path: documentPath)
        }

        return .init(
            headers: ["Content-Type": "application/json"],
            method: .post,
            url: URL(string: url.absoluteString + ":runQuery")!,
            body: body
        )
    }
}
