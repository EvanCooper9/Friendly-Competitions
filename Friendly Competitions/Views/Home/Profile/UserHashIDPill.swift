//
//  UserHashIDPill.swift
//  Friendly Competitions
//
//  Created by Evan Cooper on 2022-01-31.
//

import SwiftUI

struct UserHashIDPill: View {

    let user: User

    var body: some View {
        Text(user.hashId)
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.gray.opacity(0.1))
            .clipShape(Capsule())
    }
}

struct UserHashIDPill_Previews: PreviewProvider {
    static var previews: some View {
        UserHashIDPill(user: .evan)
    }
}
