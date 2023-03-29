import Factory
import XCTest

class FCTestCase: XCTestCase {

    private var _container = Container()
    var container: Container { _container }

    override func setUp() {
        super.setUp()
        _container = .init()
        Container.shared = _container
    }
}
