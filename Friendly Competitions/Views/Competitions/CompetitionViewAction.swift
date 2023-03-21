import SwiftUIX

enum CompetitionViewAction {
    case acceptInvite
    case declineInvite
    case delete
    case edit
    case invite
    case join
    case leave
}

extension CompetitionViewAction {

    var buttonTitle: String {
        switch self {
        case .acceptInvite:
            return L10n.Competition.Action.AcceptInvite.buttonTitle
        case .declineInvite:
            return L10n.Competition.Action.DeclineInvite.buttonTitle
        case .delete:
            return L10n.Competition.Action.Delete.buttonTitle
        case .edit:
            return L10n.Competition.Action.Edit.buttonTitle
        case .invite:
            return L10n.Competition.Action.Invite.buttonTitle
        case .join:
            return L10n.Competition.Action.Join.buttonTitle
        case .leave:
            return L10n.Competition.Action.Leave.buttonTitle
        }
    }

    var confirmationTitle: String? {
        switch self {
        case .delete:
            return L10n.Competition.Action.Delete.confirmationTitle
        case .leave:
            return L10n.Competition.Action.Leave.confirmationTitle
        default:
            return nil
        }
    }

    var systemImage: SFSymbolName {
        switch self {
        case .acceptInvite, .join:
            return .personCropCircleBadgeCheckmark
        case .declineInvite:
            return .personCropCircleBadgeXmark
        case .delete:
            return .trash
        case .edit:
            return .squareAndPencil
        case .invite:
            return .personCropCircleBadgePlus
        case .leave:
            return .personCropCircleBadgeCheckmark
        }
    }

    var destructive: Bool {
        switch self {
        case .acceptInvite, .edit, .invite, .join:
            return false
        case .declineInvite, .delete, .leave:
            return true
        }
    }
}
