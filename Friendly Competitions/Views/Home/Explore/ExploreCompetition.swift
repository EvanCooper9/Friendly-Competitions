//
//  ExploreCompetition.swift
//  Friendly Competitions
//
//  Created by Evan Cooper on 2022-02-18.
//

import SwiftUI

struct ExploreCompetition: View {

    let competition: Competition

    var body: some View {
        if competition.appOwned {
            FeaturedCompetition(competition: competition)
        } else {
            VStack(alignment: .leading, spacing: 5) {
                Text(competition.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)

                let start = competition.start.formatted(date: .abbreviated, time: .omitted)
                let end = competition.end.formatted(date: .abbreviated, time: .omitted)
                let text = "\(start) - \(end)"
                Label(text, systemImage: "calendar")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

struct ExploreCompetition_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ExploreCompetition(competition: .mock)
            ExploreCompetition(competition: .mockPublic)
        }
        .padding()
    }
}
