import Foundation

public struct DeferredDownloadConfiguration: Sendable {
    public var sessionIdentifier: String
    public var sharedContainerIdentifier: String?
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

    public static func defaultSessionIdentifier(
        bundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> String {
        "\(bundleIdentifier ?? "ink.codes.Hanstholm").conditions"
    }
}
