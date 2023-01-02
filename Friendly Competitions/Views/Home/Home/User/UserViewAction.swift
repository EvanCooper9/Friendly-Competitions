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
            return "Accept invite"
        case .denyFriendRequest:
            return "Decline invite"
        case .request:
            return "Add as friend"
        case .deleteFriend:
            return "Remove friend"
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
