import SwiftUI

extension View {
    public func cappedDynamicType() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}
