//
//  DeferredDownloadable.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation
import DomainTypes

/// Opt-in capability: "my data is one plain download whose bytes decode standalone".
///
/// Conforming lets the coordinator drive this plugin through a background `URLSession`,
/// which survives process death and can deliver while the app isn't running. A plugin that
/// can't honestly describe itself this way simply doesn't conform, and the coordinator
/// falls back to the foreground path — no faking a download session.
public protocol DeferredDownloadable: SurfConditionsPlugin {
    /// The request to download.
    ///
    /// Built at *schedule* time and executed by the system minutes to hours later, so it
    /// must stay valid for that long. Don't embed short-lived credentials here; if the
    /// source needs them, don't conform.
    func deferredRequest(for place: Place) throws -> URLRequest

    /// Parses downloaded bytes into an entry.
    ///
    /// Takes the MIME type rather than the whole `URLResponse` so the payload crossing
    /// into the plugin is unambiguously `Sendable`.
    func decodeDeferred(_ data: Data, mimeType: String?, for place: Place) async throws -> SurfEntry
}
