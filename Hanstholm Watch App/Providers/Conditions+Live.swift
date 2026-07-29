//
//  Conditions+Live.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 29.07.26.
//

import WidgetKit
import Conditions
import HydePlugin

extension ConditionsCoordinator {
    /// The watch app's coordinator.
    ///
    /// Deferred downloads are off here: the app refreshes through `WKApplication` background
    /// tasks, not a background `URLSession`, so it has no reason to create one. The widget
    /// extension owns that path — they meet in the shared `Cache`, never in memory.
    nonisolated static let watchApp = ConditionsCoordinator(
        configuration: .init(
            plugins: [HydePlugin()],
            deferredDownloads: nil,
            reloadWidgetTimelines: {
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    )
}
