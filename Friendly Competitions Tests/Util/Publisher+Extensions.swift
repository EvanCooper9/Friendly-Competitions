import Combine
import XCTest

extension Publisher where Output: Equatable {
    func expect(_ expectedValues: Output..., expectation: XCTestExpectation) -> AnyCancellable {
        collect(expectedValues.count)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            }, receiveValue:  { values in
                XCTAssertEqual(values, expectedValues)
                expectation.fulfill()
            })
    }
}
