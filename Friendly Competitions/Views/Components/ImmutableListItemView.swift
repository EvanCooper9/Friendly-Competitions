import SwiftUI

struct ImmutableListItemView: View {

    enum ValueType {
        case name
        case email
        case date(description: String)
        case other(systemImage: String, description: String)

        var systemImageName: String {
            switch self {
            case .name:
                return "person.fill"
            case .email:
                return "envelope.fill"
            case .date:
                return "calendar"
            case let .other(systemImage, _):
                return systemImage
            }
        }

        var description: String {
            switch self {
            case .name:
                return "Name"
            case .email:
                return "Email"
            case let .date(description):
                return description
            case let .other(_, description):
                return description
            }
        }
    }

    let value: String
    let valueType: ValueType

    var body: some View {
        HStack {
            Image(systemName: valueType.systemImageName)
            Text(valueType.description)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}
