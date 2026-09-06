import SwiftUI

struct ManagePlacesCard: View {
    @ScaledMetric private var height: CGFloat = PlaceCard.baseHeight

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color.gray.gradient, in: .rect(corners: .concentric(minimum: .fixed(PlaceCard.minimumCornerRadius)), isUniform: true))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ManagePlacesCard {}
        .padding()
}
