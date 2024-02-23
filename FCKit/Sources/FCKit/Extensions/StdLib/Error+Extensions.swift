import Combine
import FirebaseCrashlytics

extension Error {
    public func reportToCrashlytics(userInfo: [String: Any] = [:], file: String = #file, line: Int = #line) {
        var nsError = self as NSError

        var userInfo = nsError.userInfo.merging(userInfo) { _, newValue in newValue }
        userInfo["file"] = file
        userInfo["line"] = line

        nsError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: nsError.userInfo.merging(userInfo) { _, newValue in newValue }
        )

        print(self)
        print(localizedDescription)
        print(userInfo)
        print(nsError)

        Crashlytics.crashlytics().record(error: nsError)
    }
}

extension Publisher where Failure == Error {
    public func reportErrorToCrashlytics(userInfo: [String: Any] = [:], caller: String = #function, file: String = #file, line: Int = #line) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            var userInfo = userInfo
            userInfo["caller"] = caller
            error.reportToCrashlytics(userInfo: userInfo, file: file, line: line)
            return .error(error)
        }
        .eraseToAnyPublisher()
    }
}
