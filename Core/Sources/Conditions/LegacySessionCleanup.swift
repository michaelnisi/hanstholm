//
//  LegacySessionCleanup.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation

/// Retires the pre-coordinator background session.
///
/// The identifier moved from the bare host `"hyde.dk"` to a bundle-scoped one, so anything
/// an older build left queued would otherwise sit in the background daemon until it expires,
/// relaunching the extension for events nothing handles any more.
///
/// Safe to delete once a release or two has shipped.
enum LegacySessionCleanup {
    static let sessionIdentifier = "hyde.dk"
    static let appGroup = "group.ink.codes.Hanstholm"
    static let defaultsKey = "ink.codes.Hanstholm.Conditions.didFlushLegacySession"

    static func flushIfNeeded(
        defaults: UserDefaults? = UserDefaults(suiteName: LegacySessionCleanup.appGroup)
    ) async {
        guard let defaults, !defaults.bool(forKey: defaultsKey) else {
            return
        }

        defaults.set(true, forKey: defaultsKey)

        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)

        // Designated initializer: the convenience one is unsupported for background configs.
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)

        for task in await session.allTasks {
            task.cancel()
        }

        session.invalidateAndCancel()
    }
}
