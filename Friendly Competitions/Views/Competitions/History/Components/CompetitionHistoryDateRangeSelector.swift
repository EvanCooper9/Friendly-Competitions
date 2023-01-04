import SwiftUI

struct CompetitionHistoryDateRangeSelector: View {
    
    let ranges: [CompetitionHistoryDateRange]
    let select: (CompetitionHistoryDateRange) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack {
                    ForEach(ranges, id: \.start) { range in
                        Button {
                            select(range)
                        } label: {
                            HStack {
                                if range.locked {
                                    Image(systemName: .lockFill).font(.footnote)
                                }
                                Text(range.title)
                            }
                            .padding(.vertical, .small)
                            .padding(.horizontal, .regular)
                            .background(background)
                            .foregroundColor(range.selected ? .accentColor : .label)
                            .overlay {
                                if range.selected {
                                    Capsule()
                                        .stroke(Color.accentColor, lineWidth: 1)
                                }
                            }
                            .clipShape(Capsule())
                            .if(range.selected) { view in
                                view.shadow(color: .gray.opacity(0.25), radius: 10)
                            }
                        }
                        .id(range.title)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                .onChange(of: ranges) { ranges in
                    guard let id = ranges.first(where: { $0.selected })?.id else { return }
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
                .onAppear {
                    guard let id = ranges.first(where: { $0.selected })?.id else { return }
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, -20)
    }
    
    private var background: some View {
        switch colorScheme {
        case .dark:
            return Color.systemFill
        case .light:
            return Color.white
        @unknown default:
            return Color.white
        }
    }
}
