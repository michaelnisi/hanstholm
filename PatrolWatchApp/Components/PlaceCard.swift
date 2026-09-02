import SwiftUI
import DomainTypes

struct PlaceCard: View {
    static let baseHeight: CGFloat = 72
    static let minimumCornerRadius: CGFloat = 12

    @ScaledMetric private var height: CGFloat = PlaceCard.baseHeight

    let place: Place
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: place.icon)
                    .font(.title2)
                Text(place.name)
                    .fontDesign(.rounded)
                    .fontWeight(.semibold)
                    .font(.body)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.accentColor.gradient, in: .rect(corners: .concentric(minimum: .fixed(Self.minimumCornerRadius)), isUniform: true))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        PlaceCard(place: .init(pluginID: "mock", key: "hanstholm", name: "Hanstholm", icon: "water.waves"), isSelected: true) {}
        PlaceCard(place: .init(pluginID: "mock", key: "hvide-sande", name: "Hvide Sande", icon: "water.waves"), isSelected: false) {}
    }
    .padding()
}
