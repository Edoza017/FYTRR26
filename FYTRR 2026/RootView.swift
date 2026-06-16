import SwiftUI

struct RootView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if !appState.isLoggedIn {
            AuthView()
        } else if !appState.hasCompletedProfile {
            ProfileSetupView()
        } else {
            HomeView()
        }
    }
}
#Preview("MVP • Auth") {
    RootView()
        .environmentObject(previewAppState(isLoggedIn: false, hasCompletedProfile: false))
}

#Preview("MVP • Profile Setup") {
    RootView()
        .environmentObject(previewAppState(isLoggedIn: true, hasCompletedProfile: false))
}

#Preview("MVP • Home") {
    RootView()
        .environmentObject(
            previewAppState(
                isLoggedIn: true,
                hasCompletedProfile: true,
                profile: UserProfile(
                    name: "Alex",
                    age: 28,
                    sex: "Male",
                    heightFeet: 5,
                    heightInches: 11,
                    weightLbs: 178,
                    goal: "Maintain",
                    activityLevel: "Moderate",
                    dailyCalories: 2400
                )
            )
        )
}

private func previewAppState(
    isLoggedIn: Bool,
    hasCompletedProfile: Bool,
    profile: UserProfile? = nil
) -> AppState {
    let state = AppState()
    state.isLoggedIn = isLoggedIn
    state.hasCompletedProfile = hasCompletedProfile
    state.currentUserProfile = profile
    return state
}
