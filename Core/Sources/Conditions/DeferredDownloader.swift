//
//  DeferredDownloader.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation

/// Owns the background `URLSession` used for deferred downloads.
///
/// Deliberately a lock-guarded class rather than an actor: the WidgetKit background events
/// handler and the `URLSession` delegate queue both reach in from `nonisolated` contexts and
/// need answers *synchronously*. `NSLock` rather than `Synchronization.Mutex` because the
/// package deploys to watchOS 10 and `Mutex` needs 11.
final class DeferredDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

    /// Routes a finished download back to the plugin and place that asked for it.
    ///
    /// Stored in `URLSessionTask.taskDescription`, which survives the process being killed
    /// and relaunched to handle the download. JSON with an explicit `version` rather than a
    /// delimited string, because `place` is free text and a token minted by a previously
    /// installed build must fail to decode rather than silently misparse.
    struct Token: Codable, Equatable, Sendable {
        static let currentVersion = 1

        var version: Int
        var pluginID: String
        var place: String

        init(pluginID: String, place: String) {
            self.version = Self.currentVersion
            self.pluginID = pluginID
            self.place = place
        }

        init?(taskDescription: String?) {
            guard let taskDescription,
                  let data = taskDescription.data(using: .utf8),
                  let token = try? JSONDecoder().decode(Token.self, from: data),
                  token.version == Self.currentVersion else {
                return nil
            }

            self = token
        }

        func encoded() -> String? {
            guard let data = try? JSONEncoder().encode(self) else {
                return nil
            }

            return String(data: data, encoding: .utf8)
        }
    }

    typealias Ingest = @Sendable (Data, String?, Token?) async -> Void

    private let lock = NSLock()
    private var storedSession: URLSession?
    private var storedIngest: Ingest?
    private var storedCompletion: (@Sendable @MainActor () -> Void)?
    private var pending: [Task<Void, Never>] = []

    private let configuration: DeferredDownloadConfiguration

    init(configuration: DeferredDownloadConfiguration) {
        self.configuration = configuration

        super.init()
    }

    func setIngest(_ ingest: @escaping Ingest) {
        lock.lock()
        storedIngest = ingest
        lock.unlock()
    }

    /// Idempotent and synchronous.
    ///
    /// Creating the session is what makes delegate callbacks flow at all: after a relaunch
    /// triggered by a finished download, nothing else reconstitutes it, so a session that
    /// is only ever built when *scheduling* leaves the delivery path dead.
    private func session() -> URLSession {
        lock.lock()

        defer {
            lock.unlock()
        }

        if let storedSession {
            return storedSession
        }

        let sessionConfiguration = URLSessionConfiguration.background(
            withIdentifier: configuration.sessionIdentifier
        )
        sessionConfiguration.sessionSendsLaunchEvents = true
        sessionConfiguration.sharedContainerIdentifier = configuration.sharedContainerIdentifier

        let session = URLSession(
            configuration: sessionConfiguration,
            delegate: self,
            delegateQueue: nil
        )
        storedSession = session

        return session
    }

    func schedule(_ request: URLRequest, token: Token, after delay: TimeInterval) {
        let task = session().downloadTask(with: request)

        task.taskDescription = token.encoded()
        task.earliestBeginDate = Date().addingTimeInterval(delay)
        task.countOfBytesClientExpectsToSend = 200
        task.countOfBytesClientExpectsToReceive = configuration.expectedBytes

        task.resume()
    }

    /// Stores the WidgetKit completion **and** reconstitutes the session, synchronously.
    ///
    /// Both halves matter, and they have to happen together: storing the completion behind
    /// an `await` lets a download that finishes first find nothing to call, and storing it
    /// without recreating the session means no download ever reports back at all.
    func adopt(completion: @escaping @Sendable @MainActor () -> Void) {
        lock.lock()
        storedCompletion = completion
        lock.unlock()

        _ = session()
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Read synchronously — the temporary file is removed as soon as this returns.
        guard let data = try? Data(contentsOf: location) else {
            logger.error("deferred download: unreadable payload")
            return
        }

        let token = Token(taskDescription: downloadTask.taskDescription)
        let mimeType = downloadTask.response?.mimeType

        lock.lock()
        let ingest = storedIngest
        lock.unlock()

        guard let ingest else {
            logger.error("deferred download: no ingest registered")
            return
        }

        let work = Task {
            await ingest(data, mimeType, token)
        }

        lock.lock()
        pending.append(work)
        lock.unlock()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            logger.error("deferred download failed: \(error)")
        }
    }

    #if !os(macOS)
    /// The only correct place to call WidgetKit's completion.
    ///
    /// Draining `pending` first is load-bearing: calling the completion while an ingest task
    /// is still writing means the system may suspend the extension mid-write, which is the
    /// same "background result never sticks" failure this replaces, one layer down.
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        lock.lock()
        let work = pending
        pending = []
        let completion = storedCompletion
        storedCompletion = nil
        lock.unlock()

        Task {
            for task in work {
                await task.value
            }

            if let completion {
                await MainActor.run {
                    completion()
                }
            }
        }
    }
    #endif
}
