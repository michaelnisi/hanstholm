import SwiftUI
import WidgetKit

#if canImport(UIKit)
import UIKit
#endif

struct TileBackground: View {
    var family: WidgetFamily

    var body: some View {
        switch family {
        #if !os(watchOS)
        case .systemSmall, .systemMedium:
            Rectangle().fill(Color(uiColor: .systemBackground).gradient)
        #endif
        default:
            Rectangle().fill(.fill.tertiary)
        }
    }
}
