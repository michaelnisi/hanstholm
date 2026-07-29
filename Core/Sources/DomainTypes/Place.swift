//
//  Place.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation

/// A spot conditions can be reported for.
///
/// This exists because a plain `String` was doing three incompatible jobs at once: it was
/// the label rendered in the UI, the key cached conditions were stored under, and the token
/// used to decide which plugin should serve a request. A display name wants to be pretty and
/// changeable, a storage key has to be stable forever, and a routing key has to be unique
/// across every installed plugin. Splitting them apart makes each one able to do its job.
public struct Place: Hashable, Sendable, Codable, Identifiable {
    /// Which plugin serves this place. Routing is exact rather than a name lookup, so two
    /// plugins covering the same spot don't collide.
    public let pluginID: String

    /// Stable identity within that plugin. Never rendered, never changed — cached
    /// conditions are filed under it.
    public let key: String

    /// Display name. Free to change without orphaning anything.
    public let name: String

    /// Globally unique, and what the cache keys on.
    public var id: String {
        "\(pluginID)/\(key)"
    }

    public init(pluginID: String, key: String, name: String) {
        self.pluginID = pluginID
        self.key = key
        self.name = name
    }
}
