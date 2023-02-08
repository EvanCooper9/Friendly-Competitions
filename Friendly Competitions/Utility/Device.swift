import UIKit

struct Device {
    static let modelName: String = { UIDevice.current.name }()
    static let iOSVersion: String = { UIDevice.current.systemVersion }()
}
