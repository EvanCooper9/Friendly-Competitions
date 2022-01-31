//
//  UserInfoSection.swift
//  Friendly Competitions
//
//  Created by Evan Cooper on 2022-01-31.
//

import SwiftUI

struct UserInfoSection: View {

    let user: User
    
    var body: some View {
        Section("Profile") {
            HStack {
                ImmutableListItemView(value: user.name, valueType: .name)
                UserHashIDPill(user: user)
            }
            ImmutableListItemView(value: user.email, valueType: .email)
        }
    }
}

struct UserInfoSection_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoSection(user: .evan)
    }
}
