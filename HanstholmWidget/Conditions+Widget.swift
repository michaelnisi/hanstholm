import WidgetKit
import Conditions
import Hyde

extension ConditionsCoordinator {
    nonisolated static let widget = ConditionsCoordinator(
        configuration: .init(
            plugins: [Hyde()],
            deferredDownloads: .init(
                sessionIdentifier: DeferredDownloadConfiguration.defaultSessionIdentifier(),
                sharedContainerIdentifier: "group.ink.codes.Hanstholm"
            ),
            reloadWidgetTimelines: {
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    )
}
