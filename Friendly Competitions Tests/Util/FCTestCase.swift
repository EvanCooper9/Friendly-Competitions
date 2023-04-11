import Factory
import XCTest

@testable import Friendly_Competitions

class FCTestCase: XCTestCase {

    private var _container = Container()
    var container: Container { _container }

    override func setUp() {
        super.setUp()
        _container = .init()
        Container.shared = _container

//        container.environmentManager.onTest {
//            fatalError("not registered")
//        }
    }
}
