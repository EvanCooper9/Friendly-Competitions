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
            return "Accept invite"
        case .declineInvite:
            return "Decline invite"
        case .delete:
            return "Delete competition"
        case .edit:
            return "Edit"
        case .invite:
            return "Invite a friend"
        case .join:
            return "Join competition"
        case .leave:
            return "Leave competition"
        }
    }
    
    var confirmationTitle: String? {
        switch self {
        case .delete:
            return "Are you sure you want to delete?"
        case .edit:
            return "Are you sure? Editing competition dates will re-calculate scores."
        case .leave:
            return "Are you sure you want to leave?"
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
