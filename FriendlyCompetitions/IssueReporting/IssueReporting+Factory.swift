import Factory

extension Container {
    var issueReporter: Factory<IssueReporting> {
        self { IssueReporter() }.scope(.shared)
    }
}
