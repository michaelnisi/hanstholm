//
//  Conditions+Widget.swift
//  HanstholmWidgetExtension
//
//  Created by Michael Nisi on 29.07.26.
//

import WidgetKit
import Conditions
import HydePlugin

extension ConditionsCoordinator {
    /// The widget extensions' coordinator, shared source between the watchOS and iOS
    /// extensions. They are separate processes with separate bundle identifiers, so the
    /// bundle-scoped session identifier keeps their background sessions apart.
    nonisolated static let widget = ConditionsCoordinator(
        configuration: .init(
            plugins: [HydePlugin()],
            deferredDownloads: .init(
                sessionIdentifier: DeferredDownloadConfiguration.defaultSessionIdentifier(),
                // Required for a background session created inside an app extension.
                sharedContainerIdentifier: "group.ink.codes.Hanstholm"
            ),
            reloadWidgetTimelines: {
                WidgetCenter.shared.reloadAllTimelines()
            }
        )
    )
}
