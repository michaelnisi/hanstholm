import DomainTypes
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol DeferredDownloadable: ConditionsPlugin {
    func deferredRequest(for place: Place) throws -> URLRequest
    func decodeDeferred(_ data: Data, mimeType: String?, for place: Place) async throws -> SurfEntry
}
