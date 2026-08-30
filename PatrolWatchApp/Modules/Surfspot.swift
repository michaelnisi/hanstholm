import SwiftUI
import DomainTypes
import MockData

struct SurfSpot: View {
    let place: Place

    @Environment(SurfProvider.self) private var surfProvider
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let surfEntry = surfProvider.surfEntry, surfEntry.place.id == place.id {
                TabView {
                    WindView(name: surfEntry.place.name, date: surfEntry.date, wind: surfEntry.wind)
                        .containerBackground(Color.accentColor.gradient, for: .tabView)

                    WaveView(name: surfEntry.place.name, date: surfEntry.date, wave: surfEntry.wave)
                        .containerBackground(Color.accentColor.gradient, for: .tabView)
                }
                .tabViewStyle(.verticalPage)
            } else if let lastError = surfProvider.lastError {
                ContentUnavailableView {
                    Label("Couldn't Load Conditions", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(lastError.localizedDescription)
                } actions: {
                    Button("Retry") {
                        Task { await surfProvider.selectPlace(place) }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if surfProvider.surfEntry?.place.id != place.id {
                await surfProvider.selectPlace(place)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "list.bullet")
                }
            }
        }
    }
}

#Preview {
    SurfSpot(place: MockData.SurfEntry.makePlace())
        .withMockProviders()
}

#Preview("Error") {
    SurfSpot(place: MockData.SurfEntry.makePlace())
        .environment(
            SurfProvider(dependencies: .init(
                cachedEntry: { nil },
                fetchEntry: { throw URLError(.notConnectedToInternet) },
                availablePlaces: { [] },
                selectPlace: { _ in },
                selectedPlace: { MockData.SurfEntry.makePlace() }
            ))
        )
}
