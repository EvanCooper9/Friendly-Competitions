import Factory

public extension Container {
    var widgetDataManager: Factory<WidgetDataManaging> {
        self { WidgetDataManager() }.scope(.shared)
    }
}
