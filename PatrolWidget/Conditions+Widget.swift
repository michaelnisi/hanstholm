import Conditions
import Hyde
import WidgetKit

extension ConditionsCoordinator {
    nonisolated static let shared = ConditionsCoordinator(
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
