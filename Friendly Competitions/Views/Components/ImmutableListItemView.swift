import SwiftUI
import SwiftUIX

struct ImmutableListItemView: View {

    enum ValueType {
        case name
        case email
        case date(description: String)
        case other(systemImage: SFSymbolName, description: String)

        var systemImageName: SFSymbolName {
            switch self {
            case .name:
                return .personFill
            case .email:
                return .envelopeFill
            case .date:
                return .calendar
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
            Label(valueType.description, systemImage: valueType.systemImageName)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}
