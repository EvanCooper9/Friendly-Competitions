import SwiftUI

enum ImmutableListItem: Identifiable {

    var id: String {
        switch self {
        case .name(let name):
            return "name-\(name)"
        case .email(let email):
            return "email-\(email)"
        case let .date(description, date):
            return "date-\(description)-\(date.encodedToString())"
        case let .other(image, description, value):
            return [image ?? "", description, value].joined(separator: "-")
        }
    }

    case name(String)
    case email(String)
    case date(description: String, Date)
    case other(image: String?, description: String, value: String)

    var view: some View {
        HStack {
            image
            Text(description)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }

    private var image: Image? {
        switch self {
        case .name:
            return Image(systemName: "person.fill")
        case .email:
            return Image(systemName: "envelope.fill")
        case .date:
            return Image(systemName: "calendar")
        case let .other(image, _, _):
            guard let image = image else { return nil }
            return Image(systemName: image)
        }
    }

    private var description: String {
        switch self {
        case .name:
            return "Name"
        case .email:
            return "Email"
        case let .date(description, _):
            return description
        case let .other(_, description, _):
            return description
        }
    }

    private var value: String {
        switch self {
        case .name(let name):
            return name
        case .email(let email):
            return email
        case let .date(_, date):
            return date.formatted(date: .abbreviated, time: .omitted)
        case let .other(_, _, value):
            return value
        }
    }
}

extension Array where Element == ImmutableListItem {
    var view: some View {
        ForEach(self) { $0.view }
    }
}
