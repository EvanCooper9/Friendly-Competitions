import Combine
import SwiftUI
import SwiftUIX

enum Banner: CaseIterable {

    struct Configuration {

        struct Action {
            let cta: String
            let foreground: Color
            let background: Color
        }

        let icon: SFSymbolName?
        let message: String
        let action: Action?
        let foreground: Color
        let background: Color
    }

    case missingCompetitionPermissions
    case missingCompetitionData

    var configuration: Configuration {
        switch self {
        case .missingCompetitionPermissions:
            return .error(message: L10n.Banner.Competition.MissingPermissions.message,
                          cta: L10n.Banner.Competition.MissingPermissions.cta)
        case .missingCompetitionData:
            return .warning(message: L10n.Banner.Competition.MissingData.message,
                            cta: UIApplication.shared.canOpenURL(.health) ? L10n.Banner.Competition.MissingData.cta : nil)
        }
    }

    func view(_ tapped: @escaping () -> Void) -> some View {
        HStack(spacing: 20) {
            if let icon = configuration.icon {
                Image(systemName: icon)
                    .foregroundColor(configuration.foreground)
                    .font(.title2)
            }

            Text(configuration.message)
                .bold()
                .foregroundColor(configuration.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let action = configuration.action {
                Button(action.cta, action: tapped)
                    .bold()
                    .foregroundColor(action.foreground)
                    .padding(.small)
                    .background(action.background)
                    .cornerRadius(10)
            }
        }
        .background(configuration.background)
    }
}

extension Banner.Configuration {
    static func error(message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .red, background: .white)
        }
        return .init(icon: .exclamationmarkCircleFill,
                     message: message,
                     action: action,
                     foreground: .white,
                     background: .red)
    }

    static func warning(message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .orange, background: .white)
        }
        return .init(icon: .exclamationmarkTriangleFill,
                     message: message,
                     action: action,
                     foreground: .white,
                     background: .orange)
    }
}

#if DEBUG
struct Banner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach(Array(Banner.allCases.enumerated()), id: \.offset) { _, banner in
                banner.view {
                    // do nothing
                }
                .padding()
                .background(banner.configuration.background)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}
#endif
