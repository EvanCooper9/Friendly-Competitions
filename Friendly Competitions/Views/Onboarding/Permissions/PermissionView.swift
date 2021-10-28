//
//  PermissionsView.swift
//  Friendly Competitions
//
//  Created by Evan Cooper on 2021-10-28.
//

import SwiftUI

struct PermissionView: View {

    let permission: Permission
    let canRequestPermission: Bool
    let permissionRequestClosure: (() -> Void)?

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
            Button(action: permissionRequestClosure ?? {}) {
                Text("Allow")
                    .font(.body.bold())
                    .foregroundColor(canRequestPermission ? .blue : .gray)
                    .padding([.top, .bottom], 5)
                    .padding([.leading, .trailing], 15)
                    .background(canRequestPermission ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .clipShape(Capsule())
            }
            .disabled(!canRequestPermission)
        }
        .padding([.top, .bottom], 5)
    }

    init(permission: Permission, canRequestPermission: Bool, permissionRequestClosure: (() -> Void)? = nil) {
        self.permission = permission
        self.canRequestPermission = canRequestPermission
        self.permissionRequestClosure = permissionRequestClosure
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach(Permission.allCases, id: \.self) { permission in
                PermissionView(permission: permission, canRequestPermission: permission == .health)
            }
        }
        .padding()
    }
}
