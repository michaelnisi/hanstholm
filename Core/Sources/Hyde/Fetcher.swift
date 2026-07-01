//
//  Fetcher.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import Foundation
import WidgetKit

actor Fetcher: NSObject {
    let host = "www.hyde.dk"
    
    static let shared = Fetcher()
    
    var completion: (@Sendable () async -> Void)?
    var cached: Data?
    
    private lazy var baseURL: URL = {
        var components: URLComponents = .init()
        components.host = host
        components.scheme = "https"
        
        return components.url!
    }()
    
    private lazy var hanstholm: URL = {
        baseURL.appendingPathComponent("/hanstholm/vejrstation.asp")
    }()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        return URLSession(configuration: config)
    }()
    
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: host)
        config.sessionSendsLaunchEvents = true
                
        return URLSession(configuration: config, delegate: DownloadDelegate(fetcher: self), delegateQueue: nil)
    }()
}

extension Fetcher {
    func retrieve() async throws -> Data {
        dump(hanstholm)
        let (data, response) = try await session.data(from: hanstholm)
        
        guard response.mimeType == "text/html" else {
            throw Hyde.Fault.unexpectedMediaType
        }
        
        return data
    }
}

extension Fetcher {
    func setCompletion(_ completion: @escaping @Sendable () async -> Void) {
        self.completion = completion
    }
    
    func background() {
        let backgroundTask = backgroundSession.downloadTask(with: hanstholm)
        backgroundTask.earliestBeginDate = Date().addingTimeInterval(15 * 60)
        backgroundTask.countOfBytesClientExpectsToSend = 200
        backgroundTask.countOfBytesClientExpectsToReceive = 16 * 1024
        
        backgroundTask.resume()
    }
    
    func update(location: URL) async {
        cached = try? Data(contentsOf: location)
        
        WidgetCenter.shared.reloadAllTimelines()
        await completion?()
    }
}

final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    nonisolated let fetcher: Fetcher

    nonisolated init(fetcher: Fetcher) {
        self.fetcher = fetcher
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task {
            await fetcher.update(location: location)
        }
    }
}
