import DomainTypes
import SwiftUI

struct WindRows: View {
    let wind: SurfEntry.Wind

    var body: some View {
        Group {
            LabeledContent("Speed", value: wind.speed.current.knots())
            LabeledContent("Gust", value: wind.speed.gust.knots())
            LabeledContent("Direction", value: wind.direction.formatted())
        }
    }
}
