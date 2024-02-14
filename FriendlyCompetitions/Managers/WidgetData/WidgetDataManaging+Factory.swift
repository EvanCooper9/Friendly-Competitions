import Factory

@available(iOS, introduced: 17)
extension Container {
    var widgetDataManager: Factory<WidgetDataManaging> {
        self { WidgetDataManager() }.scope(.shared)
    }
}
