import Foundation

// sourcery: AutoMockable
protocol CompetitionCache {
    var competitionsHasPremiumResults: HasPremiumResultsContainerCache? { get set }
}

extension UserDefaults: CompetitionCache {

    private enum Constants {
        static var competitionsHasPremiumResults: String { #function }
    }

    var competitionsHasPremiumResults: HasPremiumResultsContainerCache? {
        get { decode(HasPremiumResultsContainerCache.self, forKey: Constants.competitionsHasPremiumResults) }
        set { encode(newValue, forKey: Constants.competitionsHasPremiumResults) }
    }
}
