//
//  Sticker.swift
//  Friendly Competitions
//
//  Created by Evan Cooper on 2022-02-17.
//

import SwiftUI

struct Sticker: View {

    private enum Constants {
        static let cornerRadius = 10.0
    }

    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .padding(3)
                .background(.regularMaterial)
                .cornerRadius(Constants.cornerRadius, corners: [.topLeft, .topRight])
            Text(text)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(.regularMaterial)
                .cornerRadius(Constants.cornerRadius)
        }
    }
}

struct Sticker_Previews: PreviewProvider {
    static var previews: some View {
        Sticker(text: "Monthly")
    }
}
