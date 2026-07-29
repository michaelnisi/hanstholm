//
//  URLSession+Conditions.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation

extension URLSession {
    /// The foreground session handed to plugins.
    ///
    /// Settings carried over from the `Fetcher` this replaced, so request behaviour is
    /// unchanged.
    public static let conditionsDefault: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForResource = 20

        return URLSession(configuration: configuration)
    }()
}
