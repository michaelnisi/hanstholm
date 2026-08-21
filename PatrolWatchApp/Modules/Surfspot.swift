import SwiftUI
import DomainTypes
import MockData

struct SurfSpot: View {
    let surfEntry: SurfEntry

    @Environment(SurfProvider.self) private var surfProvider
    @State private var showingPlacePicker = false

    var body: some View {
        NavigationStack {
            TabView {
                WindView(name: surfEntry.place.name, date: surfEntry.date, wind: surfEntry.wind)
                    .containerBackground(Color.accentColor.gradient, for: .tabView)

                WaveView(name: surfEntry.place.name, date: surfEntry.date, wave: surfEntry.wave)
                    .containerBackground(Color.accentColor.gradient, for: .tabView)
            }
            .tabViewStyle(.verticalPage)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingPlacePicker = true
                    } label: {
                        Image(systemName: "mappin.and.ellipse")
                    }
                }
            }
            .sheet(isPresented: $showingPlacePicker) {
                PlacePicker(selected: surfEntry.place) { place in
                    Task { await surfProvider.selectPlace(place) }
                    showingPlacePicker = false
                }
            }
        }
    }
}

#Preview {
    SurfSpot(
        surfEntry: MockData.SurfEntry.makeSurfEntry()
    )
    .withMockProviders()
}
