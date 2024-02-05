import SwiftUI

struct UserInfoSection: View {

    let user: User

    var body: some View {
        Section(L10n.Profile.title) {
            HStack {
                ImmutableListItemView(value: user.name, valueType: .name)
                if user.isAnonymous != true {
                    IDPill(id: user.hashId)
                }
            }
            if let email = user.email {
                ImmutableListItemView(value: email, valueType: .email)
            }
        }
    }
}

#if DEBUG
struct UserInfoSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            UserInfoSection(user: .evan)
        }
    }
}
#endif
