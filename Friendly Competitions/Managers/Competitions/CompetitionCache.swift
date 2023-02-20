import Foundation

// sourcery: AutoMockable
protocol CompetitionCache {
    var competitionsDateInterval: DateInterval { get set }
    var competitionsHasPremiumResults: HasPremiumResultsContainerCache? { get set }
}

extension UserDefaults: CompetitionCache {
    
    private enum Constants {
        static var competitionsDateIntervalKey: String { #function }
        static var competitionsHasPremiumResults: String { #function }
    }
    
    var competitionsDateInterval: DateInterval {
        get { decode(DateInterval.self, forKey: Constants.competitionsDateIntervalKey) ?? .init() }
        set { encode(newValue, forKey: Constants.competitionsDateIntervalKey) }
    }
    
    var competitionsHasPremiumResults: HasPremiumResultsContainerCache? {
        get { decode(HasPremiumResultsContainerCache.self, forKey: Constants.competitionsHasPremiumResults) }
        set { encode(newValue, forKey: Constants.competitionsHasPremiumResults) }
    }
}
