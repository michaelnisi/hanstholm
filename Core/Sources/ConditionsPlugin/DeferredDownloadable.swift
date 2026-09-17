import Foundation
import DomainTypes

public protocol DeferredDownloadable: ConditionsPlugin {
    func deferredRequest(for place: Place) throws -> URLRequest
    func decodeDeferred(_ data: Data, mimeType: String?, for place: Place) async throws -> SurfEntry
}
