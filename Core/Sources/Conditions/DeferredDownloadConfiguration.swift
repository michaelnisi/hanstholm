//
//  DeferredDownloadConfiguration.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation

/// Settings for the background `URLSession` that drives deferred downloads.
///
/// Passing this to `ConditionsCoordinator.Configuration` enables the fast path in that
/// process; passing `nil` disables it, and no background session is ever created.
public struct DeferredDownloadConfiguration: Sendable {
    /// Background session identifier.
    ///
    /// Must match the string given to `.onBackgroundURLSessionEvents(matching:)`. Use
    /// `defaultSessionIdentifier()` for both so they can't drift apart.
    public var sessionIdentifier: String

    /// App Group container. **Required** for background sessions created inside an app
    /// extension — without it the download silently fails to start.
    public var sharedContainerIdentifier: String?

    /// Hint for the scheduler; not a limit.
    public var expectedBytes: Int64

    public init(
        sessionIdentifier: String = DeferredDownloadConfiguration.defaultSessionIdentifier(),
        sharedContainerIdentifier: String? = nil,
        expectedBytes: Int64 = 16 * 1024
    ) {
        self.sessionIdentifier = sessionIdentifier
        self.sharedContainerIdentifier = sharedContainerIdentifier
        self.expectedBytes = expectedBytes
    }

    /// Scopes the identifier to the running bundle, so the two widget extensions don't
    /// share one session identifier by accident.
    public static func defaultSessionIdentifier(
        bundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> String {
        "\(bundleIdentifier ?? "ink.codes.Hanstholm").conditions"
    }
}
