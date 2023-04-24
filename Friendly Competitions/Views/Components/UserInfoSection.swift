import SwiftUI

struct UserInfoSection: View {

    let user: User

    var body: some View {
        Section(L10n.Profile.title) {
            HStack {
                ImmutableListItemView(value: user.name, valueType: .name)
                IDPill(id: user.hashId)
            }
            ImmutableListItemView(value: user.email, valueType: .email)
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
