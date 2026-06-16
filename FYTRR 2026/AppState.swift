import Foundation
import FirebaseCore
import FirebaseAuth

private enum UITestLaunchMode: String {
    case auth = "UITEST_AUTH"
    case profileSetup = "UITEST_PROFILE_SETUP"
    case home = "UITEST_HOME"
}

final class AppState: ObservableObject {

    @Published var isLoggedIn: Bool = false
    @Published var hasCompletedProfile: Bool = false
    @Published var currentUserProfile: UserProfile?

    private var authListener: AuthStateDidChangeListenerHandle?

    private var uiTestMode: UITestLaunchMode? {
        let args = ProcessInfo.processInfo.arguments
        if args.contains(UITestLaunchMode.auth.rawValue) { return .auth }
        if args.contains(UITestLaunchMode.profileSetup.rawValue) { return .profileSetup }
        if args.contains(UITestLaunchMode.home.rawValue) { return .home }
        return nil
    }

    private var isFirebaseConfigured: Bool {
        FirebaseApp.app() != nil
    }

    init() {
        if let uiTestMode {
            applyUITestMode(uiTestMode)
            return
        }

        guard isFirebaseConfigured else { return }
        listenToAuthChanges()
    }

    private func listenToAuthChanges() {
        authListener = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isLoggedIn = (user != nil)

                if let uid = user?.uid {
                    self.checkUserProfile(uid: uid)
                } else {
                    self.hasCompletedProfile = false
                    self.currentUserProfile = nil
                }
            }
        }
    }

    private func applyUITestMode(_ mode: UITestLaunchMode) {
        switch mode {
        case .auth:
            isLoggedIn = false
            hasCompletedProfile = false
            currentUserProfile = nil
        case .profileSetup:
            isLoggedIn = true
            hasCompletedProfile = false
            currentUserProfile = nil
        case .home:
            isLoggedIn = true
            hasCompletedProfile = true
            currentUserProfile = UserProfile(
                name: "UITest User",
                age: 30,
                sex: "Male",
                heightFeet: 5,
                heightInches: 11,
                weightLbs: 180,
                goal: "Maintain",
                activityLevel: "Moderate",
                dailyCalories: 2400,
                mealsPerDay: 3
            )
        }
    }

    private func checkUserProfile(uid: String) {
        if let profile = ProfileStore.loadProfile(uid: uid) {
            hasCompletedProfile = true
            currentUserProfile = profile
        } else {
            hasCompletedProfile = false
            currentUserProfile = nil
        }
    }

    func refreshProfile() {
        guard isFirebaseConfigured, let uid = Auth.auth().currentUser?.uid else { return }
        checkUserProfile(uid: uid)
    }

    func logout() {
        if isFirebaseConfigured {
            try? Auth.auth().signOut()
        }

        self.isLoggedIn = false
        self.hasCompletedProfile = false
        self.currentUserProfile = nil
    }

    deinit {
        if isFirebaseConfigured, let handle = authListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
