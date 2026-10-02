import Conditions
import Hyde
import WidgetKit

extension ConditionsCoordinator {
    nonisolated static let widget = ConditionsCoordinator(
        configuration: .init(
            plugins: [Hyde()],
            deferredDownloads: .init(
                sessionIdentifier: DeferredDownloadConfiguration.defaultSessionIdentifier(),
                sharedContainerIdentifier: "group.ink.codes.Patrol"
            ),
            reloadWidgetTimelines: {
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    )
}
