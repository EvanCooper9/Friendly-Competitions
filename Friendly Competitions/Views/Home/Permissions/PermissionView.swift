//
//  PermissionsView.swift
//  Friendly Competitions
//
//  Created by Evan Cooper on 2021-10-28.
//

import SwiftUI

struct PermissionView: View {

    let permission: Permission
    let status: PermissionStatus
    var permissionRequestClosure: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 15) {
            Image(permission.imageName)
                .font(.largeTitle)
                .shadow(color: .gray.opacity(0.3), radius: 5)
            VStack(alignment: .leading) {
                Text(permission.title)
                Text(permission.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()

            Button(status.buttonTitle) {
                guard status == .notDetermined else { return }
                permissionRequestClosure?()
            }
            .tint(status.buttonColor)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding([.top, .bottom], 5)
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PermissionView(permission: .health, status: .notDetermined)
            PermissionView(permission: .notifications, status: .authorized)
            PermissionView(permission: .contacts, status: .denied)
        }
        .padding()
    }
}
