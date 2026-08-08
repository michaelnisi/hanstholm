import Foundation
import DomainTypes

final class DeferredDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    struct Token: Codable, Equatable, Sendable {
        static let currentVersion = 1

        var version: Int
        var place: Place

        init(place: Place) {
            self.version = Self.currentVersion
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

    func adopt(completion: @escaping @Sendable @MainActor () -> Void) {
        lock.lock()
        storedCompletion = completion
        lock.unlock()

        _ = session()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
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
