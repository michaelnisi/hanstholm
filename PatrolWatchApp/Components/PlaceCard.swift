import SwiftUI
import DomainTypes

struct PlaceCard: View {
    static let height: CGFloat = 72

    let place: Place
    let isSelected: Bool
    var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: isExpanded ? 8 : 4) {
            Image(systemName: place.icon)
                .font(isExpanded ? .largeTitle : .title2)
            Text(place.name)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .font(isExpanded ? .title3 : .body)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: isExpanded ? .infinity : nil)
        .frame(height: isExpanded ? nil : Self.height)
        .background(Color.accentColor.gradient, in: .rect(cornerRadius: isExpanded ? 0 : 16))
        .overlay(alignment: .topTrailing) {
            if isSelected && !isExpanded {
                Image(systemName: "checkmark.circle.fill")
                    .padding(6)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PlaceCard(place: .init(pluginID: "mock", key: "hanstholm", name: "Hanstholm", icon: "water.waves"), isSelected: true)
        PlaceCard(place: .init(pluginID: "mock", key: "hvide-sande", name: "Hvide Sande", icon: "water.waves"), isSelected: false)
    }
    .padding()
}

#Preview("Expanded") {
    PlaceCard(place: .init(pluginID: "mock", key: "hanstholm", name: "Hanstholm", icon: "water.waves"), isSelected: true, isExpanded: true)
        .ignoresSafeArea()
}
