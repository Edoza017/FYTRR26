import SwiftUI
import FirebaseCore

@main
struct FYTRRApp: App {

    @StateObject var appState = AppState()

    init() {
        configureFirebaseIfAvailable()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .tint(BrandPalette.accent)
                .environment(\.font, .custom("AvenirNextCondensed-Regular", size: 16))
        }
    }

    private func configureFirebaseIfAvailable() {
        guard FirebaseApp.app() == nil else { return }

        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
        }
    }
}
