import SwiftUI
import SwiftUIX

enum UserViewAction {
    case acceptFriendRequest
    case denyFriendRequest
    case request
    case deleteFriend
}

extension UserViewAction {

    var buttonTitle: String {
        switch self {
        case .acceptFriendRequest:
            return L10n.User.Action.AcceptFriendRequest.title
        case .denyFriendRequest:
            return L10n.User.Action.DeclineFriendRequest.title
        case .request:
            return L10n.User.Action.RequestFriend.title
        case .deleteFriend:
            return L10n.User.Action.DeleteFriend.title
        }
    }

    var destructive: Bool {
        switch self {
        case .acceptFriendRequest, .request:
            return false
        case .denyFriendRequest, .deleteFriend:
            return true
        }
    }

    var systemImage: SFSymbolName {
        switch self {
        case .acceptFriendRequest, .request:
            return .personCropCircleBadgePlus
        case .denyFriendRequest, .deleteFriend:
            return .personCropCircleBadgeMinus
        }
    }
}
