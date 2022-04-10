import SwiftUI

struct AddFriendListItem: View {

    enum Action {
        case competitionInvite
        case friendRequest

        fileprivate func title(actionCompleted: Bool) -> String {
            switch self {
            case .competitionInvite:
                return actionCompleted ? "Invited" : "Invite"
            case .friendRequest:
                return actionCompleted ? "Requested" : "Request"
            }
        }
    }

    let friend: User
    let action: Action
    let disabledIf: Bool
    let onAction: () -> Void

    @State private var requested = false
    private var buttonDisabled: Bool { disabledIf || requested }

    var body: some View {
        HStack {
            Text(friend.name)
            IDPill(id: friend.hashId)
            Spacer()
            Button(action.title(actionCompleted: buttonDisabled)) {
                requested = true
                onAction()
            }
            .tint(.blue)
            .disabled(buttonDisabled)
            .buttonStyle(.bordered)
        }
    }
}
