import Factory
import XCTest

class FCTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        Container.shared = Container()
    }
}
