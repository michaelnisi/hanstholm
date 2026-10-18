import Conditions
import Hyde
import WidgetKit

extension ConditionsCoordinator {
    nonisolated static let shared = ConditionsCoordinator(
        configuration: .init(
            plugins: [Hyde()],
            deferredDownloads: nil,
            reloadWidgetTimelines: {
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    )
}
