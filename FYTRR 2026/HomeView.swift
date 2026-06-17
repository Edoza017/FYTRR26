import SwiftUI
import CoreLocation
import MapKit
import FirebaseAuth
import UIKit
import PhotosUI
import UserNotifications

private enum HomeDashboardTab: String, CaseIterable, Identifiable {
    case home
    case fuel
    case map

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .fuel: return "Fuel"
        case .map: return "Map"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .fuel: return "fork.knife"
        case .map: return "map"
        }
    }
}

private struct FuelCoachMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

private struct RestaurantMapPoint: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

private enum RecommendationBadgeKind {
    case highProtein
    case lowerCalorie
    case budgetFriendly
    case closeBy

    var title: String {
        switch self {
        case .highProtein: return "High Protein"
        case .lowerCalorie: return "Lower Cal"
        case .budgetFriendly: return "Budget"
        case .closeBy: return "Nearby"
        }
    }

    var color: Color {
        switch self {
        case .highProtein: return BrandPalette.accent.opacity(0.26)
        case .lowerCalorie: return BrandPalette.elevated
        case .budgetFriendly: return BrandPalette.elevated
        case .closeBy: return BrandPalette.elevated
        }
    }
}

private enum MapDisplayMode: String, CaseIterable, Identifiable {
    case map = "Map"
    case list = "List"
    case search = "Search"

    var id: String { rawValue }
}

private enum DeliveryProvider: String, CaseIterable, Identifiable {
    case doorDash = "DoorDash"
    case uberEats = "Uber Eats"

    var id: String { rawValue }
}

private enum FuelFilter: String, CaseIterable, Identifiable {
    case highProtein = "High Protein"
    case menuReady = "Menu Ready"
    case underDoubleDollar = "Under $$"
    case topRated = "Top Rated 4.5+"
    case local = "Local <3 mi"

    var id: String { rawValue }
}

private enum MapQuickFilter: String, CaseIterable, Identifiable {
    case highProtein = "High Protein"
    case topRated = "Top Rated"
    case nearMe = "Near Me"
    case value = "Best Value"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .highProtein: return "figure.strengthtraining.traditional"
        case .topRated: return "star.fill"
        case .nearMe: return "location.fill"
        case .value: return "dollarsign.circle.fill"
        }
    }
}

struct HomeView: View {

    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @EnvironmentObject var appState: AppState
    @Environment(\.openURL) private var openURL

    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: HomeDashboardTab = .home
    @State private var isShowingProfileSheet = false
    @State private var radiusMiles: Double = 3.0
    @State private var profileGoal: String = "Maintain"
    @State private var profileActivityLevel: String = "Moderate"
    @State private var profileMealsPerDay: Int = 3
    @State private var profileMaxPriceTier: Int = 4
    @State private var profilePrioritizeHighProtein = true
    @State private var profileProteinTargetMultiplier: Double = 0.8
    @State private var selectedProfileTheme: BrandTheme = BrandThemeStore.current
    @State private var profileUpdateMessage: String?
    @State private var isSavingProfile = false
    @State private var lastUpdatedAt: Date?
    @State private var isUsingFallbackData = false
    @State private var activeFuelFilters: Set<FuelFilter> = []
    @State private var selectedDeliveryProvider: DeliveryProvider = .doorDash
    @State private var coachInputText = ""
    @State private var coachMessages: [FuelCoachMessage] = []
    @State private var isCoachLoading = false
    @State private var coachStatusMessage: String?
    @State private var sleepHours: Double?
    @State private var trainingStrain: Double?
    @State private var vo2Max: Double?
    @State private var activeEnergyKcal: Double?
    @State private var basalEnergyKcal: Double?
    @State private var isReadinessLoading = false
    @State private var performanceMessage: String?
    @State private var selectedProfilePhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?
    @State private var mealOrderHistory: [MealOrderEntry] = []
    @State private var orderCelebrationMessage: String?
    @AppStorage("fytrr.didRunPostProfilePermissionPrompt") private var didRunPostProfilePermissionPrompt = false
    @AppStorage("fytrr.healthIntegrationEnabled") private var isHealthIntegrationEnabled = true
    @State private var isShowingMapExperience = false
    @State private var mapSearchCenter: CLLocationCoordinate2D?
    @State private var nearbyOpenTriggerMessage: String?
    @State private var fuelCheckInMessage: String?
    @State private var creditToastMessage: String?
    @State private var reminderStatusMessage: String?
    @AppStorage("fytrr.lastFuelCheckInDay") private var lastFuelCheckInDay = ""
    @AppStorage("fytrr.currentFuelStreak") private var currentFuelStreak = 0
    @AppStorage("fytrr.creditBalance") private var fytrrCreditBalance = 0
    @AppStorage("fytrr.lifetimeCredits") private var fytrrLifetimeCredits = 0
    @AppStorage("fytrr.lastMealOrderCreditKey") private var lastMealOrderCreditKey = ""
    @AppStorage("fytrr.breakfastReminderEnabled") private var isBreakfastReminderEnabled = false
    @AppStorage("fytrr.lunchReminderEnabled") private var isLunchReminderEnabled = false
    @AppStorage("fytrr.dinnerReminderEnabled") private var isDinnerReminderEnabled = false
    @AppStorage("fytrr.breakfastReminderHour") private var breakfastReminderHour = 8
    @AppStorage("fytrr.breakfastReminderMinute") private var breakfastReminderMinute = 0
    @AppStorage("fytrr.lunchReminderHour") private var lunchReminderHour = 11
    @AppStorage("fytrr.lunchReminderMinute") private var lunchReminderMinute = 30
    @AppStorage("fytrr.dinnerReminderHour") private var dinnerReminderHour = 17
    @AppStorage("fytrr.dinnerReminderMinute") private var dinnerReminderMinute = 30
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    )

    private let service = RestaurantService()
    private let recommendationEngine = RecommendationEngine()
    private let aiCoachService = AIFuelCoachService()
    private let dailyFuelCreditAward = 10
    private let mealOrderCreditAward = 15
    private let weeklyStreakCreditBonus = 25
    private let mealRewardCreditTarget = 500
    private static let fuelDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var profile: UserProfile? {
        appState.currentUserProfile
    }

    private var profileStorageID: String {
        Auth.auth().currentUser?.uid ?? "local"
    }

    private var recommendations: [RestaurantRecommendation] {
        if let profile {
            return recommendationEngine.rank(restaurants: restaurants, for: profile)
        }

        return restaurants
            .sorted { lhs, rhs in
                (lhs.distance ?? .greatestFiniteMagnitude) < (rhs.distance ?? .greatestFiniteMagnitude)
            }
            .map { restaurant in
                let score = Int(max(1, min(100, (restaurant.rating / 5.0) * 100.0)))
                return RestaurantRecommendation(
                    restaurant: restaurant,
                    score: score,
                    reason: "Closest match based on your current location."
                )
            }
    }

    private var filteredRecommendations: [RestaurantRecommendation] {
        recommendations.filter { recommendation in
            guard let distance = recommendation.restaurant.distance else { return true }
            return distance <= radiusMiles * 1609.34
        }
        .filter { recommendation in
            guard !activeFuelFilters.isEmpty else { return true }

            return activeFuelFilters.allSatisfy { filter in
                switch filter {
                case .highProtein:
                    return isHighProteinRestaurant(recommendation.restaurant)
                case .menuReady:
                    return recommendation.restaurant.bestMenuURL != nil
                case .underDoubleDollar:
                    guard let price = recommendation.restaurant.price else { return true }
                    return price.count <= 2
                case .topRated:
                    return recommendation.restaurant.rating >= 4.5
                case .local:
                    guard let distance = recommendation.restaurant.distance else { return false }
                    return distance <= 4828.03
                }
            }
        }
    }

    private var topFuelRecommendations: [RestaurantRecommendation] {
        Array(filteredRecommendations.prefix(10))
    }

    private var dailyFuelPlanRecommendations: [RestaurantRecommendation] {
        guard !filteredRecommendations.isEmpty else { return [] }

        let ranked = filteredRecommendations.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return (lhs.restaurant.distance ?? .greatestFiniteMagnitude) < (rhs.restaurant.distance ?? .greatestFiniteMagnitude)
        }

        guard ranked.count > 3 else { return ranked }

        let dayIndex = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        let rotation = dayIndex % ranked.count
        let rotated = Array(ranked[rotation...]) + Array(ranked[..<rotation])
        return Array(rotated.prefix(3))
    }

    private var hasCheckedInToday: Bool {
        lastFuelCheckInDay == Self.fuelDayFormatter.string(from: Date())
    }

    private var streakTitleText: String {
        currentFuelStreak == 1 ? "1-day fuel streak" : "\(currentFuelStreak)-day fuel streak"
    }

    private var nextMealRewardCreditTarget: Int {
        guard fytrrCreditBalance > 0 else { return mealRewardCreditTarget }
        return ((fytrrCreditBalance / mealRewardCreditTarget) + 1) * mealRewardCreditTarget
    }

    private var creditsToNextMealReward: Int {
        max(0, nextMealRewardCreditTarget - fytrrCreditBalance)
    }

    private var mealRewardCreditProgress: Double {
        guard mealRewardCreditTarget > 0 else { return 0 }
        if fytrrCreditBalance > 0 && fytrrCreditBalance % mealRewardCreditTarget == 0 {
            return 1
        }
        return min(1.0, max(0.0, Double(fytrrCreditBalance % mealRewardCreditTarget) / Double(mealRewardCreditTarget)))
    }

    private var creditTierTitle: String {
        switch fytrrCreditBalance {
        case 0: return "Start earning today"
        case 1...99: return "Fuel Starter"
        case 100...249: return "Meal Credit Builder"
        case 250...499: return "Halfway to Reward"
        default: return "Reward Ready"
        }
    }

    private var creditRewardMessage: String {
        if fytrrCreditBalance >= mealRewardCreditTarget && fytrrCreditBalance % mealRewardCreditTarget == 0 {
            return "Meal reward ready. Keep stacking credits while FYTRR prepares redemptions."
        }
        return "\(creditsToNextMealReward) credits until your next future meal reward."
    }

    private var mapPoints: [RestaurantMapPoint] {
        filteredRecommendations.compactMap { recommendation in
            guard let coordinate = recommendation.restaurant.coordinate else { return nil }
            return RestaurantMapPoint(
                id: recommendation.restaurant.id,
                name: recommendation.restaurant.name,
                coordinate: coordinate
            )
        }
    }

    private var isShowingMockData: Bool {
        restaurants.contains { $0.id.hasPrefix("mock-") }
    }

    private var isLocationDenied: Bool {
        locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted
    }

    private var isWaitingForLocation: Bool {
        locationManager.isRequestingLocation
            || ((locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways)
                && locationManager.location == nil)
    }

    private var canSearch: Bool {
        true
    }

    private var yelpStatusText: String {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: "YELP_API_KEY") as? String else {
            return "Yelp API key missing in target Info settings. Add YELP_API_KEY for live data."
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "YOUR_YELP_API_KEY" {
            return "Yelp API key placeholder detected. Set YELP_API_KEY in target Info settings for live data."
        }

        return "Live Yelp data is enabled."
    }

    private var fuelEmptyStateMessage: String {
        if isLocationDenied {
            return "Location is off. Enable location in Map controls to get local fuel spots."
        }

        if isWaitingForLocation {
            return "Finding nearby fuel spots. Keep FYTRR open for a moment while iOS gets your location."
        }

        if yelpStatusText.contains("missing") || yelpStatusText.contains("placeholder") {
            return "Yelp live data is off. Add your Yelp API key in target Info settings."
        }

        if let errorMessage {
            let lowered = errorMessage.lowercased()
            if lowered.contains("internet") || lowered.contains("network") {
                return "No internet connection. Pull to refresh when online."
            }
            if lowered.contains("timed out") {
                return "Request timed out. Try refresh or reduce radius."
            }
            if lowered.contains("location") {
                return "Location is still warming up. Tap Refresh Location or search a city."
            }
            return errorMessage
        }

        if isUsingFallbackData {
            return "Showing preview fuel spots. Enable location or search a city for live nearby matches."
        }

        return activeFuelFilters.isEmpty
            ? "No matches in your selected radius yet."
            : "No matches with selected filters. Clear a filter or increase radius."
    }

    private let goalOptions = ["Lose Fat", "Maintain", "Gain Muscle"]
    private let activityOptions = ["Low", "Moderate", "High"]

    private var draftDailyCalories: Int? {
        guard let profile else { return nil }
        return CalorieCalculator.calculate(
            age: profile.age,
            sex: profile.sex,
            heightFeet: profile.heightFeet,
            heightInches: profile.heightInches,
            weightLbs: profile.weightLbs,
            activityLevel: profileActivityLevel,
            goal: profileGoal
        )
    }

    private var draftMealCalories: Int? {
        guard let draftDailyCalories else { return nil }
        let mealCount = max(1, profileMealsPerDay)
        return max(250, Int((Double(draftDailyCalories) / Double(mealCount)).rounded()))
    }

    private var draftProteinTarget: Int? {
        guard let profile else { return nil }
        let factor = min(1.2, max(0.7, profileProteinTargetMultiplier))
        return Int((profile.weightLbs * factor).rounded())
    }

    private var appleHealthStatusText: String {
        if isReadinessLoading { return "Syncing..." }
        if healthKitManager.connectionState == .notAvailable { return "Unavailable" }
        if sleepHours != nil || trainingStrain != nil || vo2Max != nil { return "Connected" }

        switch healthKitManager.connectionState {
        case .authorized:
            return "Connected"
        case .denied:
            return "Permission Needed"
        case .notAvailable:
            return "Unavailable"
        case .notDetermined:
            return "Not Connected"
        }
    }

    private var trainingReadinessScore: Int? {
        guard sleepHours != nil || trainingStrain != nil || vo2Max != nil else { return nil }

        let sleepComponent: Double = {
            guard let sleepHours else { return 28 }
            return min(50, max(0, (sleepHours / 8.0) * 50))
        }()

        let vo2Component: Double = {
            guard let vo2Max else { return 18 }
            return min(30, max(0, ((vo2Max - 28.0) / 24.0) * 30.0))
        }()

        let loadComponent: Double = {
            guard let trainingStrain else { return 14 }
            return min(20, max(0, (1.0 - (trainingStrain / 21.0)) * 20.0))
        }()

        let score = Int((sleepComponent + vo2Component + loadComponent).rounded())
        return min(100, max(0, score))
    }

    private var trainingReadinessLabel: String {
        guard let trainingReadinessScore else { return "Insufficient Data" }
        switch trainingReadinessScore {
        case 85...100: return "Peak"
        case 70...84: return "Strong"
        case 55...69: return "Moderate"
        default: return "Recover"
        }
    }

    private var totalEnergyBurnedKcal: Int? {
        guard activeEnergyKcal != nil || basalEnergyKcal != nil else { return nil }
        return Int(((activeEnergyKcal ?? 0) + (basalEnergyKcal ?? 0)).rounded())
    }

    private var fuelBalanceGap: Int? {
        guard let totalEnergyBurnedKcal, let profile else { return nil }
        return totalEnergyBurnedKcal - profile.dailyCalories
    }

    private var fuelBalanceTitle: String {
        guard isHealthIntegrationEnabled else { return "Apple Watch Off" }
        guard let fuelBalanceGap else { return "Connect Apple Health" }

        switch fuelBalanceGap {
        case ..<(-250): return "Fuel Ahead"
        case -250...250: return "On Target"
        default: return "Refuel Needed"
        }
    }

    private var fuelBalanceMessage: String {
        guard isHealthIntegrationEnabled else {
            return "Turn on Apple Watch + Health in Profile to compare calories burned against your daily need."
        }

        guard let fuelBalanceGap, let profile else {
            return "Connect Apple Watch or Health data to compare total calories burned against your daily need."
        }

        let gap = abs(fuelBalanceGap)
        switch fuelBalanceGap {
        case ..<(-250):
            return "You are about \(gap) calories under today's target of \(profile.dailyCalories). Stay steady and use lighter meals."
        case -250...250:
            return "You are within \(gap) calories of today's \(profile.dailyCalories)-calorie target."
        default:
            return "You have burned about \(gap) calories above today's need. Add a recovery meal with protein and carbs."
        }
    }

    private var hasProfileChanges: Bool {
        guard let profile else { return false }
        return profile.goal != profileGoal
            || profile.activityLevel != profileActivityLevel
            || profile.mealsPerDay != profileMealsPerDay
            || profile.maxPriceTier != profileMaxPriceTier
            || profile.prioritizeHighProtein != profilePrioritizeHighProtein
            || abs(profile.proteinTargetMultiplier - profileProteinTargetMultiplier) > 0.001
            || profile.backgroundTheme != selectedProfileTheme.rawValue
    }

    private var canSaveProfileChanges: Bool {
        profile != nil && hasProfileChanges && !isSavingProfile
    }

    private var mealMilestones: [Int] { [1, 5, 10, 25, 50, 100] }

    private var currentMealMilestone: Int {
        mealMilestones.last(where: { mealOrderHistory.count >= $0 }) ?? 0
    }

    private var nextMealMilestone: Int {
        mealMilestones.first(where: { mealOrderHistory.count < $0 }) ?? ((mealMilestones.last ?? 100) + 50)
    }

    private var mealMilestoneProgress: Double {
        let previous = currentMealMilestone
        let next = nextMealMilestone
        let span = max(1, next - previous)
        let progressInSpan = max(0, mealOrderHistory.count - previous)
        return min(1.0, max(0.0, Double(progressInSpan) / Double(span)))
    }

    private var mealTierTitle: String {
        switch mealOrderHistory.count {
        case 0: return "Getting Started"
        case 1...4: return "Fuel Rookie"
        case 5...9: return "Fuel Builder"
        case 10...24: return "Consistency Athlete"
        case 25...49: return "Readiness Streak"
        case 50...99: return "Elite Fueler"
        default: return "FYTRR Legend"
        }
    }

    private var mealMilestoneMessage: String {
        let remaining = max(0, nextMealMilestone - mealOrderHistory.count)
        if remaining == 0 {
            return "Milestone unlocked. Keep stacking wins."
        }
        return "\(remaining) more to unlock \(nextMealMilestone) total meals."
    }

    private var childrenFedCount: Int {
        mealOrderHistory.count / 10
    }

    private var mealsToNextChildImpact: Int {
        let remainder = mealOrderHistory.count % 10
        return remainder == 0 ? 10 : 10 - remainder
    }

    private var childImpactProgress: Double {
        let remainder = mealOrderHistory.count % 10
        return Double(remainder) / 10.0
    }

    private var childImpactMessage: String {
        if mealOrderHistory.isEmpty {
            return "Every 10 meals ordered helps provide 1 meal to a child."
        }
        return "\(mealsToNextChildImpact) meals until your next child meal is funded."
    }

    private var locationActionTitle: String {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return "Open Settings"
        case .authorizedAlways, .authorizedWhenInUse:
            return "Refresh Location"
        case .notDetermined:
            return "Enable Location"
        default:
            return "Enable Location"
        }
    }

    var body: some View {
        ZStack {
            BrandBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    metricsRow
                    activeDashboardContent
                    logoutButton
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .refreshable {
                if let location = locationManager.location {
                    fetchRestaurants(location: location)
                } else {
                    locationManager.start()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            dashboardBar
        }
        .onAppear {
            if profile == nil {
                appState.refreshProfile()
            }
            locationManager.start()
            syncMapCamera()
            syncProfileEditor()
            loadProfileAssets()
            requestPostProfilePermissionsIfNeeded()
            if let location = locationManager.location {
                fetchRestaurants(location: location)
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            syncMapCamera()
            if let newLocation {
                fetchRestaurants(location: newLocation)
            }
        }
        .onChange(of: radiusMiles) { _, _ in
            syncMapCamera()
            if let location = locationManager.location {
                fetchRestaurants(location: location)
            }
        }
        .onChange(of: appState.currentUserProfile) { _, _ in
            syncProfileEditor()
            loadProfileAssets()
            requestPostProfilePermissionsIfNeeded()
            if let location = locationManager.location {
                fetchRestaurants(location: location)
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .map {
                isShowingMapExperience = true
            }
        }
        .onChange(of: selectedProfilePhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let jpegData = image.jpegData(compressionQuality: 0.9) {
                    await MainActor.run {
                        profilePhotoData = jpegData
                    }
                    ProfileStore.saveProfilePhotoData(jpegData, uid: profileStorageID)
                }
            }
        }
        .sheet(isPresented: $isShowingProfileSheet) {
            profileSheet
        }
        .fullScreenCover(isPresented: $isShowingMapExperience, onDismiss: {
            if selectedTab == .map {
                selectedTab = .fuel
            }
        }) {
            FullScreenMapExperience(
                radiusMiles: $radiusMiles,
                mapCameraPosition: $mapCameraPosition,
                mapPoints: mapPoints,
                recommendations: filteredRecommendations,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onUseCurrentLocation: {
                    locationManager.start()
                    if let location = locationManager.location {
                        fetchRestaurants(location: location)
                    }
                },
                onSearchCurrentArea: {
                    if let mapSearchCenter {
                        fetchRestaurants(location: CLLocation(latitude: mapSearchCenter.latitude, longitude: mapSearchCenter.longitude))
                    } else if let location = locationManager.location {
                        fetchRestaurants(location: location)
                    } else {
                        locationManager.start()
                    }
                },
                onSearchCity: { city in
                    searchCityAndFetch(city)
                },
                mapCenterCoordinate: $mapSearchCenter,
                mealTargetCalories: profile?.mealCalorieTarget,
                onOpenMenu: { restaurant in
                    openMenu(for: restaurant)
                },
                onOpenDirections: { restaurant in
                    openDirections(for: restaurant)
                },
                onOrderDoorDash: { restaurantName in
                    openDoorDash(for: restaurantName)
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                BrandInlineLockup(markHeight: 22, wordmarkHeight: 28, spacing: 8)
                Spacer()
                profileAvatarButton
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.map { "Today, \($0.name)" } ?? "Today")
                    .font(.custom("AvenirNext-Heavy", size: 32))
                    .foregroundStyle(BrandPalette.textPrimary)

                Text("Find a meal that fits your target.")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(BrandPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileAvatarButton: some View {
        Button {
            isShowingProfileSheet = true
        } label: {
            HStack(spacing: 8) {
                Group {
                    if let profilePhotoData,
                       let image = UIImage(data: profilePhotoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(profileInitials)
                            .font(.custom("AvenirNext-Heavy", size: 13))
                            .foregroundStyle(BrandPalette.backgroundTop)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(BrandPalette.accent)
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(BrandPalette.accent, lineWidth: 2))

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(BrandPalette.textSecondary)
            }
            .padding(.leading, 4)
            .padding(.trailing, 10)
            .frame(height: 44)
            .background(BrandPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .accessibilityIdentifier("home_profile_button")
        .accessibilityLabel("Open profile")
    }

    private var profileInitials: String {
        let name = profile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? "FY"
        let initials = name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
        return initials.isEmpty ? "FY" : initials.uppercased()
    }

    private var profileSheet: some View {
        NavigationStack {
            ZStack {
                BrandBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        profileSheetHeader
                        profileBlock
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isShowingProfileSheet = false
                    }
                    .foregroundStyle(BrandPalette.accent)
                }
            }
        }
    }

    private var profileSheetHeader: some View {
        HStack(spacing: 12) {
            Group {
                if let profilePhotoData,
                   let image = UIImage(data: profilePhotoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(profileInitials)
                        .font(.custom("AvenirNext-Heavy", size: 24))
                        .foregroundStyle(BrandPalette.backgroundTop)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(BrandPalette.accent)
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(Circle())
            .overlay(Circle().stroke(BrandPalette.accent, lineWidth: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(profile?.name ?? "FYTRR Athlete")
                    .font(.custom("AvenirNext-Heavy", size: 22))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text(profile.map { "\($0.goal) • \($0.dailyCalories) daily calories" } ?? "Finish setup to personalize fuel.")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var metricsRow: some View {
        HStack(spacing: 10) {
            targetCircleCard(
                title: "Daily",
                valueText: profile.map { "\($0.dailyCalories)" } ?? "--",
                subtitle: "Calories",
                progress: profile.map { min(1.0, max(0.0, Double($0.dailyCalories) / 3500.0)) } ?? 0,
                progressColor: BrandPalette.success
            )

            targetCircleCard(
                title: "Per Meal",
                valueText: profile.map { "\($0.mealCalorieTarget)" } ?? "--",
                subtitle: "Target",
                progress: profile.map { min(1.0, max(0.0, Double($0.mealCalorieTarget) / 1200.0)) } ?? 0,
                progressColor: Color.white
            )

            targetCircleCard(
                title: "Meals",
                valueText: profile.map { "\($0.mealsPerDay)" } ?? "--",
                subtitle: "Per Day",
                progress: profile.map { min(1.0, max(0.0, Double($0.mealsPerDay) / 6.0)) } ?? 0,
                progressColor: BrandPalette.accent
            )
        }
    }

    private func targetCircleCard(
        title: String,
        valueText: String,
        subtitle: String,
        progress: Double,
        progressColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.custom("AvenirNext-DemiBold", size: 11))
                .foregroundStyle(BrandPalette.textSecondary)

            ZStack {
                Circle()
                    .stroke(BrandPalette.stroke, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(valueText)
                        .font(.custom("AvenirNext-Heavy", size: 16))
                        .monospacedDigit()
                        .foregroundStyle(BrandPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(subtitle)
                        .font(.custom("AvenirNext-Regular", size: 10))
                        .foregroundStyle(BrandPalette.textSecondary)
                }
            }
            .frame(height: 84)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var impactSummaryBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(BrandPalette.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Impact: \(childrenFedCount) child meals funded")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text(childImpactMessage)
                    .font(.custom("AvenirNext-Regular", size: 11))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var creditsMiniBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(BrandPalette.backgroundTop)
                .frame(width: 30, height: 30)
                .background(BrandPalette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(fytrrCreditBalance) FYTRR Credits")
                    .font(.custom("AvenirNext-Heavy", size: 14))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text(creditRewardMessage)
                    .font(.custom("AvenirNext-Regular", size: 11))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text(creditTierTitle.uppercased())
                .font(.custom("AvenirNext-DemiBold", size: 9))
                .foregroundStyle(BrandPalette.accent)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(BrandPalette.accent.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(10)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var profileCreditsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(BrandPalette.backgroundTop)
                    .frame(width: 44, height: 44)
                    .background(BrandPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(fytrrCreditBalance) credits")
                        .font(.custom("AvenirNext-Heavy", size: 22))
                        .monospacedDigit()
                        .foregroundStyle(BrandPalette.textPrimary)
                    Text(creditTierTitle)
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(BrandPalette.accent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(fytrrLifetimeCredits)")
                        .font(.custom("AvenirNext-Heavy", size: 16))
                        .monospacedDigit()
                        .foregroundStyle(BrandPalette.textPrimary)
                    Text("lifetime")
                        .font(.custom("AvenirNext-Regular", size: 11))
                        .foregroundStyle(BrandPalette.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Future meal reward")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(BrandPalette.textSecondary)
                    Spacer()
                    Text("\(Int((mealRewardCreditProgress * 100).rounded()))%")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundStyle(BrandPalette.textSecondary)
                }

                ProgressView(value: mealRewardCreditProgress)
                    .tint(BrandPalette.accent)

                Text(creditRewardMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 7) {
                creditEarnRuleRow(icon: "checkmark.circle.fill", title: "Daily fuel check-in", value: "+\(dailyFuelCreditAward)")
                creditEarnRuleRow(icon: "flame.fill", title: "Every 7-day streak", value: "+\(weeklyStreakCreditBonus)")
                creditEarnRuleRow(icon: "bag.fill", title: "Open order flow", value: "+\(mealOrderCreditAward)")
            }
            .padding(10)
            .background(BrandPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text("Credits are tracked in FYTRR now and can support future meal rewards, partner offers, or gift-card redemptions.")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(BrandPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func creditEarnRuleRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BrandPalette.accent)
                .frame(width: 18)

            Text(title)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(BrandPalette.textPrimary)

            Spacer()

            Text(value)
                .font(.custom("AvenirNext-Heavy", size: 12))
                .foregroundStyle(BrandPalette.accent)
        }
    }

    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.custom("AvenirNext-DemiBold", size: 11))
                .foregroundStyle(BrandPalette.textSecondary)

            Text(value)
                .font(.custom("AvenirNext-Heavy", size: 20))
                .monospacedDigit()
                .foregroundStyle(BrandPalette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(BrandPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundStyle(BrandPalette.textPrimary)

            switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                if let location = locationManager.location {
                    Text("Connected: \(location.coordinate.latitude.formatted(.number.precision(.fractionLength(3)))), \(location.coordinate.longitude.formatted(.number.precision(.fractionLength(3))))")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundStyle(BrandPalette.textSecondary)
                } else {
                    Text("Permission granted. FYTRR is finding your current area.")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundStyle(BrandPalette.textSecondary)
                }
            case .denied, .restricted:
                Text("Location is disabled. Tap Open Settings to enable it.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(BrandPalette.warning)
            default:
                Text("Enable location so FYTRR can score nearby meals.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            if let locationErrorMessage = locationManager.locationErrorMessage {
                Text(locationErrorMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.warning)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Radius")
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .foregroundStyle(BrandPalette.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f miles", radiusMiles))
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .foregroundStyle(BrandPalette.textPrimary)
                }

                Slider(value: $radiusMiles, in: 0.5...10.0, step: 0.5)
                    .tint(BrandPalette.accent)
            }

            Text(yelpStatusText)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(BrandPalette.textSecondary)

            Text("Adjustable radius: 0.5 to 10 miles.")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(BrandPalette.textSecondary)

            if let lastUpdatedAt {
                Text("Last updated \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            } else {
                Text("No data loaded yet. Enable location and tap Refresh.")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            HStack(spacing: 10) {
                Button(locationActionTitle) {
                    if isLocationDenied {
                        locationManager.openSettings()
                    } else {
                        locationManager.start()
                    }
                }
                .buttonStyle(BrandSecondaryButtonStyle())

                Button(filteredRecommendations.isEmpty ? "Find Matches" : "Refresh") {
                    if let location = locationManager.location {
                        fetchRestaurants(location: location)
                    } else if isLocationDenied {
                        loadFallbackData()
                    } else {
                        locationManager.start()
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .disabled(!canSearch)
                .accessibilityIdentifier("home_find_matches_button")
            }
        }
        .brandCard()
    }

    @ViewBuilder
    private var activeDashboardContent: some View {
        switch selectedTab {
        case .home:
            releaseHomeContent
        case .fuel:
            recommendationsBlock
        case .map:
            VStack(spacing: 12) {
                locationCard
                mapBlock
            }
        }
    }

    private var releaseHomeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            dailyFuelPlanCard
            fuelStreakReminderCard
        }
    }

    private var dailyFuelPlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    sectionHeader("Daily Fuel Plan")
                    Text(dailyPlanSubtitle)
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundStyle(BrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("TODAY")
                    .font(.custom("AvenirNext-DemiBold", size: 11))
                    .foregroundStyle(BrandPalette.backgroundTop)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(BrandPalette.accent)
                    .clipShape(Capsule())
            }

            if let nearbyOpenTriggerMessage {
                Label(nearbyOpenTriggerMessage, systemImage: "location.fill")
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(BrandPalette.accent)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BrandPalette.accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if isLoading && dailyFuelPlanRecommendations.isEmpty {
                ProgressView("Building today's picks...")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .tint(BrandPalette.success)
            }

            if dailyFuelPlanRecommendations.isEmpty && !isLoading {
                homeEmptyFuelState
            } else {
                ForEach(Array(dailyFuelPlanRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                    dailyFuelPickRow(recommendation, slot: index)
                }
            }

            HStack(spacing: 10) {
                Button(hasCheckedInToday ? "Fueled Today" : "Mark Fueled") {
                    registerFuelCheckIn(source: "Daily plan")
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .disabled(hasCheckedInToday)
                .opacity(hasCheckedInToday ? 0.72 : 1)

                Button("Refresh") {
                    refreshFuelMatches()
                }
                .buttonStyle(BrandSecondaryButtonStyle())
            }

            if let fuelCheckInMessage {
                Text(fuelCheckInMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let creditToastMessage {
                Text(creditToastMessage)
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(BrandPalette.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .brandCard()
    }

    private var fuelStreakReminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                fuelHeatGauge

                VStack(alignment: .leading, spacing: 3) {
                    Text(streakTitleText)
                        .font(.custom("AvenirNext-Heavy", size: 18))
                        .foregroundStyle(BrandPalette.textPrimary)
                    Text(hasCheckedInToday ? "Logged for today. Keep the chain alive tomorrow." : "Open FYTRR, pick a meal, and mark fueled once daily.")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(BrandPalette.textSecondary)
                }

                Spacer()
            }

            Divider()
                .overlay(BrandPalette.stroke)

            VStack(spacing: 8) {
                reminderTimeRow(
                    title: "Breakfast reminder",
                    isOn: $isBreakfastReminderEnabled,
                    identifier: "fytrr.breakfastFuelReminder",
                    hour: $breakfastReminderHour,
                    minute: $breakfastReminderMinute
                )

                reminderTimeRow(
                    title: "Lunch reminder",
                    isOn: $isLunchReminderEnabled,
                    identifier: "fytrr.lunchFuelReminder",
                    hour: $lunchReminderHour,
                    minute: $lunchReminderMinute
                )

                reminderTimeRow(
                    title: "Dinner reminder",
                    isOn: $isDinnerReminderEnabled,
                    identifier: "fytrr.dinnerFuelReminder",
                    hour: $dinnerReminderHour,
                    minute: $dinnerReminderMinute
                )
            }

            if let reminderStatusMessage {
                Text(reminderStatusMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .brandCard()
    }

    private var fuelHeatGauge: some View {
        let filledBars = max(1, min(5, currentFuelStreak))

        return VStack(spacing: 4) {
            Image(systemName: hasCheckedInToday ? "flame.fill" : "flame")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(hasCheckedInToday ? BrandPalette.backgroundTop : BrandPalette.accent)
                .frame(width: 36, height: 32)
                .background(hasCheckedInToday ? BrandPalette.accent : BrandPalette.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < filledBars ? BrandPalette.accent : BrandPalette.stroke)
                        .frame(width: 5, height: CGFloat(8 + index * 3))
                }
            }
        }
        .frame(width: 46)
        .accessibilityLabel("Fuel streak heat level \(filledBars) of 5")
    }

    private var homeEmptyFuelState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(fuelEmptyStateMessage)
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundStyle(BrandPalette.textSecondary)

            Button(filteredRecommendations.isEmpty ? "Find Meals" : "Refresh") {
                refreshFuelMatches()
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .accessibilityIdentifier("home_find_matches_button")
        }
        .padding(12)
        .background(BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var dailyPlanSubtitle: String {
        if let profile {
            return "Three picks refreshed daily around your \(profile.mealCalorieTarget)-calorie meal target."
        }
        return "Three picks refreshed daily from the best nearby matches."
    }

    private func dailyFuelPickRow(_ recommendation: RestaurantRecommendation, slot: Int) -> some View {
        HStack(alignment: .top, spacing: 11) {
            VStack(spacing: 2) {
                Text("\(slot + 1)")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(BrandPalette.backgroundTop)
                Text(dailyPickLabel(for: slot))
                    .font(.custom("AvenirNext-DemiBold", size: 9))
                    .foregroundStyle(BrandPalette.backgroundTop.opacity(0.8))
            }
            .frame(width: 42, height: 48)
            .background(BrandPalette.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(recommendation.restaurant.name)
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(BrandPalette.textPrimary)
                    .lineLimit(1)

                Text(menuBasedMealRecommendationText(for: recommendation))
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(recommendation.restaurant.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                        .foregroundStyle(BrandPalette.warning)
                    if let distance = recommendation.restaurant.formattedDistance {
                        Label(distance, systemImage: "location")
                            .foregroundStyle(BrandPalette.textSecondary)
                    }
                    Text("Fit \(recommendation.score)")
                        .foregroundStyle(BrandPalette.accent)
                }
                .font(.custom("AvenirNext-DemiBold", size: 11))
            }

            Spacer(minLength: 4)

            Button {
                openMenu(for: recommendation.restaurant)
            } label: {
                Image(systemName: "menucard")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(BrandPalette.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .accessibilityLabel("Open menu for \(recommendation.restaurant.name)")
        }
        .padding(10)
        .background(BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func reminderTimeRow(
        title: String,
        isOn: Binding<Bool>,
        identifier: String,
        hour: Binding<Int>,
        minute: Binding<Int>
    ) -> some View {
        let enabled = isOn.wrappedValue

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: reminderIcon(for: title))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(enabled ? BrandPalette.backgroundTop : BrandPalette.accent)
                    .frame(width: 36, height: 36)
                    .background(enabled ? BrandPalette.accent : BrandPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .foregroundStyle(BrandPalette.textPrimary)
                    Text(enabled ? "\(formattedReminderTime(hour: hour.wrappedValue, minute: minute.wrappedValue)) daily" : "Off")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(enabled ? BrandPalette.accent : BrandPalette.textSecondary)
                }

                Spacer()

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(BrandPalette.accent)
                    .onChange(of: isOn.wrappedValue) { _, enabled in
                        updateFuelReminder(identifier: identifier, enabled: enabled, hour: hour.wrappedValue, minute: minute.wrappedValue)
                    }
            }

            if enabled {
                HStack(spacing: 8) {
                    Picker("\(title) hour", selection: hour) {
                        ForEach(0..<24, id: \.self) { value in
                            Text(formattedHour(value)).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BrandPalette.accent)
                    .frame(maxWidth: .infinity)

                    Picker("\(title) minute", selection: minute) {
                        ForEach([0, 15, 30, 45], id: \.self) { value in
                            Text(String(format: "%02d", value)).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BrandPalette.accent)
                    .frame(maxWidth: .infinity)
                }
                .font(.custom("AvenirNext-DemiBold", size: 13))
                .padding(8)
                .background(BrandPalette.backgroundTop.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(BrandPalette.accent.opacity(0.28), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: hour.wrappedValue) { _, newHour in
                    if isOn.wrappedValue {
                        updateFuelReminder(identifier: identifier, enabled: true, hour: newHour, minute: minute.wrappedValue)
                    }
                }
                .onChange(of: minute.wrappedValue) { _, newMinute in
                    if isOn.wrappedValue {
                        updateFuelReminder(identifier: identifier, enabled: true, hour: hour.wrappedValue, minute: newMinute)
                    }
                }
            }
        }
        .padding(10)
        .background(enabled ? BrandPalette.accent.opacity(0.11) : BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(enabled ? BrandPalette.accent.opacity(0.42) : BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func reminderIcon(for title: String) -> String {
        let lowercased = title.lowercased()
        if lowercased.contains("breakfast") { return "sunrise.fill" }
        if lowercased.contains("lunch") { return "sun.max.fill" }
        return "moon.stars.fill"
    }

    private func formattedHour(_ hour: Int) -> String {
        let normalized = ((hour % 24) + 24) % 24
        switch normalized {
        case 0: return "12 AM"
        case 1...11: return "\(normalized) AM"
        case 12: return "12 PM"
        default: return "\(normalized - 12) PM"
        }
    }

    private func formattedReminderTime(hour: Int, minute: Int) -> String {
        let normalizedHour = ((hour % 24) + 24) % 24
        let suffix = normalizedHour < 12 ? "AM" : "PM"
        let displayHour = normalizedHour == 0 ? 12 : (normalizedHour > 12 ? normalizedHour - 12 : normalizedHour)
        return String(format: "%d:%02d %@", displayHour, minute, suffix)
    }

    private func legacyReminderToggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        identifier: String,
        hour: Int,
        minute: Int
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(BrandPalette.accent)
                .onChange(of: isOn.wrappedValue) { _, enabled in
                    updateFuelReminder(identifier: identifier, enabled: enabled, hour: hour, minute: minute)
                }
        }
        .padding(10)
        .background(BrandPalette.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func dailyPickLabel(for slot: Int) -> String {
        switch slot {
        case 0: return "BEST"
        case 1: return "LEAN"
        default: return "FAST"
        }
    }

    private var homeStatusText: String {
        if let profile {
            return "Target: \(profile.mealCalorieTarget) calories per meal. Ranked by FYTRR health fit, Yelp rating, distance, and menu availability."
        }
        return "Ranked by FYTRR health fit, Yelp rating, distance, and menu availability."
    }

    private func compactRecommendationRow(_ recommendation: RestaurantRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.restaurant.name)
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundStyle(BrandPalette.textPrimary)
                        .lineLimit(1)

                    Text(recommendation.restaurant.formattedCategories)
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(BrandPalette.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(recommendation.score)")
                    .font(.custom("AvenirNext-Heavy", size: 14))
                    .foregroundStyle(BrandPalette.backgroundTop)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(BrandPalette.success)
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                Label(recommendation.restaurant.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    .foregroundStyle(BrandPalette.warning)

                if let price = recommendation.restaurant.price {
                    Text(price)
                        .foregroundStyle(BrandPalette.textSecondary)
                }

                if let distance = recommendation.restaurant.formattedDistance {
                    Label(distance, systemImage: "location")
                        .foregroundStyle(BrandPalette.textSecondary)
                }
            }
            .font(.custom("AvenirNext-Medium", size: 12))

            Text(menuBasedMealRecommendationText(for: recommendation))
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(BrandPalette.textSecondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Button {
                    openMenu(for: recommendation.restaurant)
                } label: {
                    fuelActionLabel(title: "Menu", icon: "menucard", isPrimary: false)
                }
                .buttonStyle(.plain)

                Button {
                    openSelectedProvider(for: recommendation.restaurant.name)
                } label: {
                    fuelActionLabel(title: "Order", icon: "bag", isPrimary: true)
                }
                .buttonStyle(.plain)

                Button {
                    openDirections(for: recommendation.restaurant)
                } label: {
                    fuelActionLabel(title: "Go", icon: "arrow.triangle.turn.up.right.diamond", isPrimary: false)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recommendationsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            performanceDashboard

            HStack {
                sectionHeader("Best Nearby Fuel")
                Spacer()
                Button {
                    isShowingMapExperience = true
                } label: {
                    Label("Map", systemImage: "map")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                }
                .foregroundStyle(BrandPalette.accent)
            }

            Text(homeStatusText)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(BrandPalette.textSecondary)

            if isLoading {
                ProgressView()
                    .tint(BrandPalette.success)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(BrandPalette.warning)
            }

            if isShowingMockData {
                Text(yelpStatusText.contains("enabled") ? "Preview results are showing until live nearby matches load." : "Showing preview restaurants until live data is enabled.")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            if isUsingFallbackData {
                Text(isLocationDenied ? "Location is off, so FYTRR is showing preview fuel spots." : "FYTRR is finding your location. Search a city if you want results right away.")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(isLocationDenied ? BrandPalette.warning : BrandPalette.textSecondary)
            }

            filterChipsRow

            if topFuelRecommendations.isEmpty {
                Text(fuelEmptyStateMessage)
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            ForEach(Array(topFuelRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                recommendationCard(
                    for: recommendation,
                    rank: index + 1,
                    featured: recommendation.id == topFuelRecommendations.first?.id
                )
            }
        }
        .brandCard()
    }

    private var mapBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Map")

            Text("Explore nearby meals in your current radius.")
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundStyle(BrandPalette.textSecondary)

            Button("Open Map") {
                isShowingMapExperience = true
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .accessibilityIdentifier("home_open_full_map_button")
        }
        .brandCard()
    }

    private var deliveryBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Delivery")

            if isLoading {
                ProgressView("Loading delivery options…")
                    .tint(BrandPalette.success)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(BrandPalette.warning)
            }

            Text("Order from your active provider.")
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(BrandPalette.textSecondary)

            if let orderCelebrationMessage {
                Text(orderCelebrationMessage)
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(BrandPalette.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(BrandPalette.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if let creditToastMessage {
                Text(creditToastMessage)
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(BrandPalette.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(BrandPalette.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack(spacing: 8) {
                providerQuickActionButton(provider: .doorDash, logoText: "D", activeColor: Color(red: 0.74, green: 0.22, blue: 0.20))
                providerQuickActionButton(provider: .uberEats, logoText: "U", activeColor: Color(red: 0.16, green: 0.52, blue: 0.30))

                Text("Active: \(selectedDeliveryProvider.rawValue)")
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(BrandPalette.elevated)
                    .clipShape(Capsule())

                Spacer()
            }

            if filteredRecommendations.isEmpty {
                Text("Find recommendations first to see delivery links.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            ForEach(filteredRecommendations.prefix(6)) { recommendation in
                VStack(alignment: .leading, spacing: 10) {
                    Text(recommendation.restaurant.name)
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundStyle(BrandPalette.textPrimary)

                    HStack(spacing: 12) {
                        Label(recommendation.restaurant.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                            .foregroundStyle(BrandPalette.warning)

                        if let price = recommendation.restaurant.price {
                            Label(price, systemImage: "dollarsign.circle")
                                .foregroundStyle(BrandPalette.textSecondary)
                        }

                        if let distance = recommendation.restaurant.formattedDistance {
                            Label(distance, systemImage: "location")
                                .foregroundStyle(BrandPalette.textSecondary)
                        }
                    }
                    .font(.custom("AvenirNext-Medium", size: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top meal picks")
                            .font(.custom("AvenirNext-DemiBold", size: 12))
                            .foregroundStyle(BrandPalette.textSecondary)

                        ForEach(mealSuggestions(for: recommendation).prefix(2), id: \.self) { suggestion in
                            HStack(spacing: 6) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 10, weight: .semibold))
                                Text(suggestion)
                                    .font(.custom("AvenirNext-Regular", size: 12))
                            }
                            .foregroundStyle(BrandPalette.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(BrandPalette.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(BrandPalette.stroke, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        }
                    }

                    HStack {
                        Button {
                            openSelectedProvider(for: recommendation.restaurant.name)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedDeliveryProvider == .doorDash ? "scooter" : "bag")
                                Text("Order")
                            }
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(BrandPalette.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(BrandPalette.surface.opacity(0.96))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(BrandPalette.accent.opacity(0.35), lineWidth: 0.8)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                }
                .padding(12)
                .background(BrandPalette.elevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(BrandPalette.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .brandCard()
    }

    private func providerQuickActionButton(provider: DeliveryProvider, logoText: String, activeColor: Color) -> some View {
        Button {
            selectedDeliveryProvider = provider
        } label: {
            Text(logoText)
                .font(.custom("AvenirNext-Heavy", size: 16))
                .foregroundStyle(selectedDeliveryProvider == provider ? .white : BrandPalette.textSecondary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(selectedDeliveryProvider == provider ? activeColor : BrandPalette.elevated)
                )
                .overlay(
                    Circle()
                        .stroke(BrandPalette.stroke, lineWidth: selectedDeliveryProvider == provider ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(provider.rawValue)
    }

    private var aiCoachBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Coach")

            Text("Plan your next meal from your profile, targets, and nearby fuel.")
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(BrandPalette.textSecondary)

            coachConnectionBanner

            HStack(spacing: 8) {
                coachQuickPromptButton("Best next meal") {
                    sendCoachPrompt("What should I eat next based on my goal and nearby options?")
                }
                coachQuickPromptButton("Post-workout") {
                    sendCoachPrompt("Build me a post-workout meal plan for today.")
                }
                coachQuickPromptButton("Protein target") {
                    sendCoachPrompt("Help me hit my protein target with practical meals.")
                }
            }
            .disabled(isCoachLoading)

            if topFuelRecommendations.isEmpty {
                Button {
                    if let location = locationManager.location {
                        fetchRestaurants(location: location)
                    } else if isLocationDenied {
                        loadFallbackData()
                    } else {
                        locationManager.start()
                    }
                } label: {
                    Label("Load Nearby Fuel", systemImage: "location.magnifyingglass")
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandSecondaryButtonStyle())
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(coachMessages) { message in
                        HStack {
                            if message.isUser { Spacer() }
                            Text(message.text)
                                .font(.custom("AvenirNext-Regular", size: 13))
                                .foregroundStyle(BrandPalette.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(message.isUser ? BrandPalette.accent.opacity(0.35) : BrandPalette.elevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(BrandPalette.stroke, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            if !message.isUser { Spacer() }
                        }
                    }
                }
            }
            .frame(minHeight: 180, maxHeight: 300)

            if isCoachLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(BrandPalette.accent)
                    Text("AI Coach is thinking…")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(BrandPalette.textSecondary)
                }
            }

            HStack(spacing: 8) {
                TextField("Ask your fuel coach...", text: $coachInputText)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .brandFieldStyle()

                Button("Send") {
                    sendCoachPrompt(coachInputText)
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .frame(maxWidth: 90)
                .disabled(isCoachLoading || coachInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .brandCard()
    }

    private var coachConnectionBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: aiCoachService.isConfigured ? "bolt.fill" : "wand.and.stars")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(aiCoachService.isConfigured ? BrandPalette.success : BrandPalette.warning)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(aiCoachService.isConfigured ? "Live AI" : "Smart Coach")
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(BrandPalette.textPrimary)

                Text(coachStatusMessage ?? aiCoachService.configurationMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func coachQuickPromptButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 11))
                .foregroundStyle(BrandPalette.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(BrandPalette.elevated)
                .overlay(
                    Capsule()
                        .stroke(BrandPalette.stroke, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func ensureCoachBootstrapped() {
        guard coachMessages.isEmpty else { return }
        coachMessages = [
            FuelCoachMessage(
                text: "I’m your Coach. Ask me for the best meal choice from your top nearby spots.",
                isUser: false
            )
        ]
    }

    private func sendCoachPrompt(_ rawPrompt: String) {
        let prompt = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        let conversationContext: [AIFuelCoachService.ChatTurn] = coachMessages.suffix(8).map {
            AIFuelCoachService.ChatTurn(isUser: $0.isUser, text: $0.text)
        }

        coachStatusMessage = aiCoachService.isConfigured ? "Asking live AI with your latest FYTRR context." : "Smart Coach is answering from your profile and local rules."
        coachMessages.append(FuelCoachMessage(text: prompt, isUser: true))
        coachInputText = ""
        isCoachLoading = true

        Task {
            do {
                let response = try await aiCoachService.reply(
                    prompt: prompt,
                    conversation: conversationContext,
                    profile: profile,
                    nearbyRecommendations: topFuelRecommendations,
                    mealTargetCalories: profile?.mealCalorieTarget
                )

                await MainActor.run {
                    coachMessages.append(FuelCoachMessage(text: response, isUser: false))
                    coachStatusMessage = "Live AI response complete."
                    isCoachLoading = false
                }
            } catch {
                let fallback = coachResponse(for: prompt)
                await MainActor.run {
                    coachMessages.append(FuelCoachMessage(text: fallback, isUser: false))
                    coachStatusMessage = "\(error.localizedDescription) Smart Coach response shown."
                    isCoachLoading = false
                }
            }
        }
    }

    private func coachResponse(for prompt: String) -> String {
        let promptLower = prompt.lowercased()
        let closest = topFuelRecommendations
        let top = Array(closest.prefix(3))
        let target = profile?.mealCalorieTarget
        let targetText = target.map { "\($0) cal/meal target" } ?? "your current meal target"
        let proteinTarget = profile.map { Int(($0.weightLbs * $0.proteinTargetMultiplier).rounded()) }
        let proteinText = proteinTarget.map { "\($0)g protein/day" } ?? "a protein-forward target"

        if top.isEmpty {
            if promptLower.contains("post") || promptLower.contains("workout") {
                return "Post-workout: aim for \(targetText), 35-50g protein, carbs from rice/potatoes/fruit, and fluids. Good order pattern: grilled chicken or salmon bowl, double vegetables, rice on the side. Tap Load Nearby Fuel for restaurant picks."
            }
            if promptLower.contains("protein") {
                return "To hit \(proteinText), split protein across meals: eggs or Greek yogurt early, lean chicken/tuna/salmon bowl midday, and another 35-50g protein dinner. Keep each meal near \(targetText). Tap Load Nearby Fuel for local options."
            }
            if promptLower.contains("low") || promptLower.contains("calorie") {
                return "Lower-calorie move: choose lean protein, vegetables, sauce on the side, and one measured carb. Keep the order near \(targetText). Avoid fried sides and sugary drinks. Tap Load Nearby Fuel for nearby matches."
            }
            return "Best next move: build a meal around \(targetText) with 35-50g protein, vegetables, and a controlled carb. For your \(profile?.goal.lowercased() ?? "performance") goal, start with grilled chicken, salmon, poke, Mediterranean, or bowl-style spots. Tap Load Nearby Fuel for local picks."
        }

        if promptLower.contains("protein") {
            let picks = top.map { recommendation in
                let meals = mealSuggestions(for: recommendation)
                return "\(recommendation.restaurant.name): \(meals.prefix(2).joined(separator: " or "))"
            }.joined(separator: " | ")
            return "For \(targetText) and \(proteinText), prioritize: \(picks). Ask for double protein, sauce on the side, and skip fried add-ons."
        }

        if promptLower.contains("low") || promptLower.contains("calorie") {
            let picks = top.map { recommendation in
                let meal = mealSuggestions(for: recommendation).first ?? "Protein bowl + vegetables"
                return "\(recommendation.restaurant.name): \(meal)"
            }.joined(separator: " | ")
            return "Lower-calorie strategy: lean protein, vegetables, sauce on side, and one controlled carb. Start with \(picks). Keep it near \(targetText)."
        }

        if promptLower.contains("post") || promptLower.contains("workout") {
            let first = top.first
            let suggestion = first.map { mealSuggestions(for: $0).first ?? "Chicken bowl + vegetables" } ?? "Chicken bowl + vegetables"
            let place = first?.restaurant.name ?? "your nearest healthy spot"
            return "Post-workout best move: \(suggestion) from \(place). Add a carb source, water, and keep the total near \(targetText)."
        }

        let first = top.first
        let mealA = first.map { mealSuggestions(for: $0).first ?? "Chicken bowl + vegetables" } ?? "Chicken bowl + vegetables"
        let mealB = first.map { mealSuggestions(for: $0).dropFirst().first ?? "Salmon plate + brown rice" } ?? "Salmon plate + brown rice"
        let place = first?.restaurant.name ?? "your top nearby spot"
        return "Best immediate choice at \(place): \(mealA) or \(mealB). It aligns with \(targetText); ask for extra lean protein if you still need \(proteinText)."
    }

    private func mealSuggestions(for recommendation: RestaurantRecommendation) -> [String] {
        let restaurant = recommendation.restaurant
        let text = "\(restaurant.name.lowercased()) \(restaurant.searchableCategoryText)"

        if text.contains("chipotle") {
            return ["Chicken bowl + fajita veggies", "Steak salad bowl + black beans"]
        }
        if text.contains("cava") {
            return ["Grilled chicken greens + grains bowl", "Harissa honey chicken salad bowl"]
        }
        if text.contains("sweetgreen") {
            return ["Harvest bowl + extra chicken", "Chicken pesto parm salad"]
        }
        if text.contains("panera") {
            return ["Greek salad + chicken", "Turkey chili + apple"]
        }
        if text.contains("jersey mike") || text.contains("sandwich") {
            return ["Turkey sub in a tub", "Chicken cheesesteak bowl-style"]
        }

        if text.contains("poke") {
            return ["Ahi tuna poke bowl + greens", "Salmon poke bowl + edamame"]
        }
        if text.contains("mediterranean") {
            return ["Chicken shawarma plate + veggies", "Salmon bowl + hummus"]
        }
        if text.contains("mexican") {
            return ["Grilled chicken bowl (no tortilla)", "Steak fajita bowl + black beans"]
        }
        if text.contains("thai") || text.contains("asian") {
            return ["Chicken basil stir-fry + rice", "Shrimp veggie stir-fry"]
        }
        if text.contains("salad") || text.contains("healthy") || text.contains("vegan") {
            return ["Protein salad + olive oil", "Grain bowl + double protein"]
        }
        if text.contains("grill") || text.contains("steak") || text.contains("bbq") {
            return ["Grilled salmon + vegetables", "Lean steak plate + sweet potato"]
        }

        return ["Chicken bowl + vegetables", "Salmon plate + brown rice"]
    }

    private func menuBasedMealRecommendationText(for recommendation: RestaurantRecommendation) -> String {
        let primaryMeal = mealSuggestions(for: recommendation).first ?? "Protein bowl + vegetables"
        let targetText = profile.map { "around \($0.mealCalorieTarget) cal" } ?? "balanced portions"
        let sourceText = recommendation.restaurant.bestMenuURL == nil ? "Yelp category pick" : "Menu-informed pick"
        return "\(sourceText): \(primaryMeal), \(targetText)."
    }

    private func targetMealOptionText(for recommendation: RestaurantRecommendation) -> String {
        let primaryMeal = mealSuggestions(for: recommendation).first ?? "Protein bowl + vegetables"
        guard let target = profile?.mealCalorieTarget else {
            return "Best meal option: \(primaryMeal)."
        }
        return "Best meal option (\(target) cal target): \(primaryMeal)."
    }

    private var profileBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Profile")

            if profile == nil {
                Text("No profile loaded yet. Complete setup or sign in again to edit settings.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(BrandPalette.textSecondary)
            } else {
                profileSectionCard(title: "Profile") {
                    HStack(spacing: 14) {
                        Group {
                            if let profilePhotoData,
                               let image = UIImage(data: profilePhotoData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(10)
                                    .foregroundStyle(BrandPalette.textSecondary)
                            }
                        }
                        .frame(width: 74, height: 74)
                        .background(BrandPalette.surface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(BrandPalette.stroke, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 8) {
                            Text(profile?.name ?? "Member")
                                .font(.custom("AvenirNext-DemiBold", size: 16))
                                .foregroundStyle(BrandPalette.textPrimary)

                            PhotosPicker(selection: $selectedProfilePhotoItem, matching: .images, photoLibrary: .shared()) {
                                Text(profilePhotoData == nil ? "Add Profile Photo" : "Change Profile Photo")
                                    .font(.custom("AvenirNext-DemiBold", size: 13))
                                    .foregroundStyle(BrandPalette.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(BrandPalette.surface)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(BrandPalette.stroke, lineWidth: 1))
                            }
                        }

                        Spacer()
                    }
                }

                profileSectionCard(title: "FYTRR Credits") {
                    profileCreditsSummary
                }

                profileSectionCard(title: "App Theme") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose your app background and accent color.")
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundStyle(BrandPalette.textSecondary)

                        HStack(spacing: 8) {
                            ForEach(BrandTheme.allCases) { theme in
                                profileThemeButton(theme)
                            }
                        }
                    }
                }

                profileSectionCard(title: "Apple Watch + Health") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "applewatch")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(isHealthIntegrationEnabled ? BrandPalette.backgroundTop : BrandPalette.accent)
                                .frame(width: 42, height: 42)
                                .background(isHealthIntegrationEnabled ? BrandPalette.accent : BrandPalette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(appleHealthStatusText)
                                    .font(.custom("AvenirNext-DemiBold", size: 14))
                                    .foregroundStyle(BrandPalette.textPrimary)

                                Text(isHealthIntegrationEnabled ? "Use Apple Watch calories for daily fuel balance." : "Apple Watch fuel balance is turned off.")
                                    .font(.custom("AvenirNext-Regular", size: 12))
                                    .foregroundStyle(BrandPalette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Toggle("", isOn: $isHealthIntegrationEnabled)
                                .labelsHidden()
                                .tint(BrandPalette.accent)
                                .onChange(of: isHealthIntegrationEnabled) { _, enabled in
                                    if enabled {
                                        connectAndLoadReadinessMetrics()
                                    } else {
                                        sleepHours = nil
                                        trainingStrain = nil
                                        vo2Max = nil
                                        activeEnergyKcal = nil
                                        basalEnergyKcal = nil
                                        performanceMessage = "Apple Watch fuel balance is off."
                                    }
                                }
                        }

                        Button(healthPrimaryActionTitle) {
                            if isHealthIntegrationEnabled {
                                connectAndLoadReadinessMetrics()
                            } else {
                                isHealthIntegrationEnabled = true
                                connectAndLoadReadinessMetrics()
                            }
                        }
                        .buttonStyle(BrandSecondaryButtonStyle())
                        .disabled(isReadinessLoading || healthKitManager.connectionState == .notAvailable)

                        if let performanceMessage {
                            Text(performanceMessage)
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundStyle(BrandPalette.textSecondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("PLAN IMPACT")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 12))
                        .tracking(1.0)
                        .foregroundStyle(BrandPalette.textSecondary)

                    HStack(spacing: 8) {
                        profileImpactMetric(title: "Daily", value: draftDailyCalories.map { "\($0)" } ?? "--")
                        profileImpactMetric(title: "Meal", value: draftMealCalories.map { "\($0)" } ?? "--")
                        profileImpactMetric(title: "Protein", value: draftProteinTarget.map { "\($0)g" } ?? "--")
                    }
                }
                .padding(12)
                .background(BrandPalette.elevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(BrandPalette.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                profileSectionCard(title: "Goals") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Goal")
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(BrandPalette.textSecondary)

                        Picker("Goal", selection: $profileGoal) {
                            ForEach(goalOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(BrandPalette.accent)

                        Text("Activity")
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(BrandPalette.textSecondary)

                        Picker("Activity", selection: $profileActivityLevel) {
                            ForEach(activityOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(BrandPalette.accent)
                    }
                }

                profileSectionCard(title: "Nutrition Targets") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Meals per day")
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(BrandPalette.textSecondary)

                        Picker("Meals per day", selection: $profileMealsPerDay) {
                            ForEach(1...6, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(BrandPalette.accent)

                        Stepper(value: $profileMaxPriceTier, in: 1...4) {
                            Text("Budget cap: \(String(repeating: "$", count: profileMaxPriceTier))")
                                .font(.custom("AvenirNext-Regular", size: 14))
                                .foregroundStyle(BrandPalette.textPrimary)
                        }

                        Toggle(isOn: $profilePrioritizeHighProtein) {
                            Text("Prioritize high-protein spots")
                                .font(.custom("AvenirNext-Regular", size: 14))
                                .foregroundStyle(BrandPalette.textPrimary)
                        }
                        .tint(BrandPalette.accent)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Protein target")
                                .font(.custom("AvenirNext-DemiBold", size: 13))
                                .foregroundStyle(BrandPalette.textSecondary)

                            Picker("Protein target", selection: $profileProteinTargetMultiplier) {
                                Text("0.7x").tag(0.7)
                                Text("0.8x").tag(0.8)
                                Text("0.9x").tag(0.9)
                                Text("1.0x").tag(1.0)
                                Text("1.2x").tag(1.2)
                            }
                            .pickerStyle(.segmented)
                            .tint(BrandPalette.accent)

                            Text("Daily protein: \(draftProteinTarget.map { "\($0)g" } ?? "--")")
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundStyle(BrandPalette.textSecondary)
                        }
                    }
                }

                profileSectionCard(title: "Meals Ordered") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(mealOrderHistory.count) total meals")
                                    .font(.custom("AvenirNext-Heavy", size: 16))
                                    .foregroundStyle(BrandPalette.textPrimary)

                                Text(mealTierTitle)
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .foregroundStyle(BrandPalette.accent)
                            }

                            Spacer()

                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("\(currentMealMilestone)")
                                    .font(.custom("AvenirNext-Heavy", size: 12))
                            }
                            .foregroundStyle(BrandPalette.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(BrandPalette.accent.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Progress to \(nextMealMilestone)")
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .foregroundStyle(BrandPalette.textSecondary)
                                Spacer()
                                Text("\(Int((mealMilestoneProgress * 100).rounded()))%")
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .foregroundStyle(BrandPalette.textSecondary)
                            }

                            ProgressView(value: mealMilestoneProgress)
                                .tint(BrandPalette.accent)

                            Text(mealMilestoneMessage)
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundStyle(BrandPalette.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Children fed", systemImage: "heart.fill")
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .foregroundStyle(BrandPalette.accent)
                                Spacer()
                                Text("\(childrenFedCount)")
                                    .font(.custom("AvenirNext-Heavy", size: 14))
                                    .foregroundStyle(BrandPalette.textPrimary)
                            }

                            ProgressView(value: childImpactProgress)
                                .tint(BrandPalette.success)

                            Text(childImpactMessage)
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundStyle(BrandPalette.textSecondary)
                        }
                        .padding(10)
                        .background(BrandPalette.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(BrandPalette.stroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        if mealOrderHistory.isEmpty {
                            Text("No meals ordered yet. Your first order unlocks Fuel Rookie.")
                                .font(.custom("AvenirNext-Regular", size: 12))
                                .foregroundStyle(BrandPalette.textSecondary)
                        } else {
                            Divider()
                                .overlay(BrandPalette.stroke)

                            Text("Recent meals")
                                .font(.custom("AvenirNext-DemiBold", size: 12))
                                .foregroundStyle(BrandPalette.textSecondary)

                            ForEach(mealOrderHistory.prefix(5)) { order in
                                HStack(spacing: 8) {
                                    Text(order.restaurantName)
                                        .font(.custom("AvenirNext-Medium", size: 13))
                                        .foregroundStyle(BrandPalette.textPrimary)
                                    Spacer()
                                    Text(order.provider)
                                        .font(.custom("AvenirNext-DemiBold", size: 11))
                                        .foregroundStyle(BrandPalette.textSecondary)
                                    Text(order.orderedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.custom("AvenirNext-Regular", size: 11))
                                        .foregroundStyle(BrandPalette.textSecondary)
                                }
                            }
                        }
                    }
                }

                VStack(spacing: 8) {
                    if !hasProfileChanges {
                        Text("No unsaved changes.")
                            .font(.custom("AvenirNext-Regular", size: 12))
                            .foregroundStyle(BrandPalette.textSecondary)
                    }

                    Button {
                        saveProfileSettings()
                    } label: {
                        if isSavingProfile {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Profile")
                        }
                    }
                    .buttonStyle(BrandPrimaryButtonStyle())
                    .disabled(!canSaveProfileChanges)
                    .accessibilityIdentifier("profile_save_button")
                }
            }

            if let profileUpdateMessage {
                Text(profileUpdateMessage)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)
            }
        }
        .brandCard()
    }

    private func profileSectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.custom("AvenirNextCondensed-Heavy", size: 12))
                .tracking(0.8)
                .foregroundStyle(BrandPalette.textSecondary)

            content()
        }
        .padding(12)
        .background(BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func profileThemeButton(_ theme: BrandTheme) -> some View {
        let isSelected = selectedProfileTheme == theme

        return Button {
            selectedProfileTheme = theme
            BrandThemeStore.current = theme
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? BrandPalette.textPrimary : BrandPalette.stroke, lineWidth: isSelected ? 2 : 1)
                    )

                Text(theme.title)
                    .font(.custom("AvenirNext-DemiBold", size: 10))
                    .foregroundStyle(isSelected ? BrandPalette.textPrimary : BrandPalette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isSelected ? BrandPalette.accent.opacity(0.16) : BrandPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? BrandPalette.accent : BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.title) theme")
    }

    private func profileImpactMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.custom("AvenirNextCondensed-DemiBold", size: 10))
                .tracking(0.8)
                .foregroundStyle(BrandPalette.textSecondary)
            Text(value)
                .font(.custom("AvenirNext-Heavy", size: 20))
                .foregroundStyle(BrandPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundStyle(BrandPalette.textPrimary)

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(BrandPalette.success)
            }
        }
    }

    private func recommendationBadges(for recommendation: RestaurantRecommendation) -> [RecommendationBadgeKind] {
        var badges: [RecommendationBadgeKind] = []
        let categoryText = recommendation.restaurant.searchableCategoryText

        if isHighProteinRestaurant(recommendation.restaurant) {
            badges.append(.highProtein)
        }

        if categoryText.contains("salad") || categoryText.contains("healthy") || categoryText.contains("vegan") {
            badges.append(.lowerCalorie)
        }

        if recommendation.restaurant.price == "$" || recommendation.restaurant.price == "$$" {
            badges.append(.budgetFriendly)
        }

        if let distance = recommendation.restaurant.distance, distance <= 1609.34 {
            badges.append(.closeBy)
        }

        return Array(badges.prefix(3))
    }

    private func isHighProteinRestaurant(_ restaurant: Restaurant) -> Bool {
        let text = "\(restaurant.name.lowercased()) \(restaurant.searchableCategoryText)"
        return ["protein", "grill", "chicken", "steak", "poke", "bbq", "cava", "chipotle", "mediterranean", "seafood", "korean", "jersey mike"]
            .contains { text.contains($0) }
    }

    private func explainabilityReasons(for recommendation: RestaurantRecommendation) -> [String] {
        var reasons: [String] = []

        if let distance = recommendation.restaurant.distance {
            let miles = distance / 1609.34
            reasons.append(String(format: "Within %.1f mi", miles))
        }

        if let profile, profile.prioritizeHighProtein {
            if isHighProteinRestaurant(recommendation.restaurant) {
                reasons.append("Matches high-protein preference")
            }
        }

        if recommendation.restaurant.bestMenuURL != nil {
            reasons.append("Menu available")
        }

        if let profile, let price = recommendation.restaurant.price, price.count <= profile.maxPriceTier {
            reasons.append("Within \(String(repeating: "$", count: profile.maxPriceTier)) budget")
        }

        if recommendation.restaurant.rating >= 4.5 {
            reasons.append("Top rated")
        }

        return Array(reasons.prefix(3))
    }

    private func recommendationCard(for recommendation: RestaurantRecommendation, rank: Int, featured: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.restaurant.name)
                        .font(.custom("AvenirNext-DemiBold", size: 18))
                        .foregroundStyle(BrandPalette.textPrimary)

                    Text(recommendation.restaurant.formattedCategories)
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundStyle(BrandPalette.textSecondary)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("#\(rank)")
                        .font(.custom("AvenirNext-Heavy", size: 17))
                    Text("\(recommendation.score)")
                        .font(.custom("AvenirNext-DemiBold", size: 10))
                }
                .foregroundStyle(featured ? BrandPalette.backgroundTop : BrandPalette.textPrimary)
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(featured ? BrandPalette.success : BrandPalette.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            let badges = recommendationBadges(for: recommendation)
            if !badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                            Text(badge.title)
                                .font(.custom("AvenirNext-DemiBold", size: 11))
                                .foregroundStyle(BrandPalette.textPrimary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(badge.color)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Text(recommendation.reason)
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundStyle(BrandPalette.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BrandPalette.accent)
                        .padding(.top, 2)
                    Text(menuBasedMealRecommendationText(for: recommendation))
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(BrandPalette.textPrimary)
                }

                ForEach(mealSuggestions(for: recommendation).prefix(2), id: \.self) { meal in
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BrandPalette.success)
                        Text(meal)
                            .font(.custom("AvenirNext-Regular", size: 12))
                            .foregroundStyle(BrandPalette.textSecondary)
                    }
                }
            }
            .padding(10)
            .background(BrandPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            let reasons = explainabilityReasons(for: recommendation)
            if !reasons.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(reasons, id: \.self) { reason in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text(reason)
                                .font(.custom("AvenirNext-Medium", size: 12))
                        }
                        .foregroundStyle(BrandPalette.textSecondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Label(recommendation.restaurant.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    .foregroundStyle(BrandPalette.warning)

                if let price = recommendation.restaurant.price {
                    Label(price, systemImage: "dollarsign.circle")
                        .foregroundStyle(BrandPalette.textSecondary)
                }

                if let distance = recommendation.restaurant.formattedDistance {
                    Label(distance, systemImage: "location")
                        .foregroundStyle(BrandPalette.textSecondary)
                }
            }
            .font(.custom("AvenirNext-Medium", size: 12))

            if let address = recommendation.restaurant.formattedAddress {
                Text(address)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            HStack(spacing: 8) {
                Button {
                    openMenu(for: recommendation.restaurant)
                } label: {
                    fuelActionLabel(title: "Menu", icon: "menucard", isPrimary: false)
                }
                .buttonStyle(.plain)

                Button {
                    openSelectedProvider(for: recommendation.restaurant.name)
                } label: {
                    fuelActionLabel(title: "Order", icon: "scooter", isPrimary: true)
                }
                .buttonStyle(.plain)

                Button {
                    openDirections(for: recommendation.restaurant)
                } label: {
                    fuelActionLabel(title: "Go", icon: "arrow.triangle.turn.up.right.diamond", isPrimary: false)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(featured ? BrandPalette.overlay : BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var performanceDashboard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily Fuel Readiness")
                        .font(.custom("AvenirNext-Heavy", size: 17))
                        .foregroundStyle(BrandPalette.textPrimary)
                    Text("Check once a day before you pick where to eat.")
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(BrandPalette.textSecondary)
                }

                Spacer()

                if isReadinessLoading {
                    ProgressView()
                        .tint(BrandPalette.success)
                } else {
                    Text(appleHealthStatusText.uppercased())
                        .font(.custom("AvenirNext-DemiBold", size: 10))
                        .foregroundStyle(BrandPalette.backgroundTop)
                        .padding(.horizontal, 9)
                        .frame(height: 24)
                        .background(BrandPalette.accent)
                        .clipShape(Capsule())
                }
            }

            creditsMiniBanner

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Balance")
                        .font(.custom("AvenirNext-DemiBold", size: 15))
                        .foregroundStyle(BrandPalette.textPrimary)
                    Spacer()
                    Text(totalEnergyBurnedKcal.map { "\($0)" } ?? "--")
                        .font(.custom("AvenirNext-Heavy", size: 20))
                        .monospacedDigit()
                        .foregroundStyle(BrandPalette.textPrimary)
                }

                Text(fuelBalanceTitle)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.accent)

                ProgressView(value: Double(totalEnergyBurnedKcal ?? 0), total: Double(max(profile?.dailyCalories ?? 1, 1)))
                    .tint(BrandPalette.accent)

                Text(fuelBalanceMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(BrandPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 10) {
                metricCard(
                    title: "Burned",
                    value: totalEnergyBurnedKcal.map { "\($0)" } ?? "--",
                    subtitle: "Today"
                )
                metricCard(
                    title: "Need",
                    value: profile.map { "\($0.dailyCalories)" } ?? "--",
                    subtitle: "Daily"
                )
                metricCard(
                    title: "Gap",
                    value: fuelBalanceGap.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "--",
                    subtitle: "Calories"
                )
            }

            HStack(spacing: 10) {
                metricCard(
                    title: "Active",
                    value: activeEnergyKcal.map { "\(Int($0.rounded()))" } ?? "--",
                    subtitle: "Move"
                )
                metricCard(
                    title: "Resting",
                    value: basalEnergyKcal.map { "\(Int($0.rounded()))" } ?? "--",
                    subtitle: "Basal"
                )
                metricCard(
                    title: "Ready",
                    value: trainingReadinessScore.map { "\($0)" } ?? "--",
                    subtitle: trainingReadinessLabel
                )
            }

            if let performanceMessage {
                Text(performanceMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            HStack(spacing: 8) {
                Button(healthPrimaryActionTitle) {
                    if isHealthIntegrationEnabled {
                        connectAndLoadReadinessMetrics()
                    } else {
                        isHealthIntegrationEnabled = true
                        connectAndLoadReadinessMetrics()
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .disabled(isReadinessLoading || healthKitManager.connectionState == .notAvailable)

                Button(hasCheckedInToday ? "Checked In" : "Log Fuel") {
                    registerFuelCheckIn(source: "Fuel readiness")
                }
                .buttonStyle(BrandSecondaryButtonStyle())
                .disabled(hasCheckedInToday)
                .opacity(hasCheckedInToday ? 0.72 : 1)
            }
        }
        .padding(12)
        .background(BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var healthPrimaryActionTitle: String {
        if !isHealthIntegrationEnabled { return "Turn On Apple Watch" }
        return healthKitManager.connectionState == .authorized ? "Sync Apple Health" : "Connect Apple Health"
    }

    private func fuelActionLabel(title: String, icon: String, isPrimary: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 11))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isPrimary ? BrandPalette.backgroundTop : BrandPalette.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(isPrimary ? BrandPalette.accent : BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isPrimary ? BrandPalette.accent : BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FuelFilter.allCases) { filter in
                    Button {
                        if activeFuelFilters.contains(filter) {
                            activeFuelFilters.remove(filter)
                        } else {
                            activeFuelFilters.insert(filter)
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.custom("AvenirNext-DemiBold", size: 12))
                            .foregroundStyle(activeFuelFilters.contains(filter) ? BrandPalette.textPrimary : BrandPalette.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(activeFuelFilters.contains(filter) ? BrandPalette.accent.opacity(0.28) : BrandPalette.elevated)
                            .overlay(
                                Capsule()
                                    .stroke(BrandPalette.stroke, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                }

                if !activeFuelFilters.isEmpty {
                    Button("Clear") {
                        activeFuelFilters.removeAll()
                    }
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(BrandPalette.warning)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(BrandPalette.elevated)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var dashboardBar: some View {
        HStack(spacing: 8) {
            ForEach(HomeDashboardTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                        Text(tab.title)
                    }
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(selectedTab == tab ? BrandPalette.textPrimary : BrandPalette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ? BrandPalette.accent : BrandPalette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selectedTab == tab ? BrandPalette.accent : BrandPalette.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .accessibilityIdentifier("home_tab_\(tab.rawValue)")
            }
        }
        .padding(10)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private var logoutButton: some View {
        Button("Log Out") {
            appState.logout()
        }
        .buttonStyle(BrandSecondaryButtonStyle())
    }

    private func syncProfileEditor() {
        guard let profile else { return }
        profileGoal = profile.goal
        profileActivityLevel = profile.activityLevel
        profileMealsPerDay = min(6, max(1, profile.mealsPerDay))
        profileMaxPriceTier = min(4, max(1, profile.maxPriceTier))
        profilePrioritizeHighProtein = profile.prioritizeHighProtein
        profileProteinTargetMultiplier = min(1.2, max(0.7, profile.proteinTargetMultiplier))
        selectedProfileTheme = BrandTheme(rawValue: profile.backgroundTheme) ?? BrandThemeStore.current
        BrandThemeStore.current = selectedProfileTheme
    }

    private func requestPostProfilePermissionsIfNeeded() {
        guard profile != nil else { return }
        guard !didRunPostProfilePermissionPrompt else { return }

        didRunPostProfilePermissionPrompt = true
        locationManager.start()
    }

    private func refreshFuelMatches() {
        if let location = locationManager.location {
            fetchRestaurants(location: location)
        } else if isLocationDenied {
            loadFallbackData()
        } else {
            locationManager.start()
        }
    }

    private func registerFuelCheckIn(source: String) {
        let today = Self.fuelDayFormatter.string(from: Date())
        guard lastFuelCheckInDay != today else {
            fuelCheckInMessage = "Today is already logged. Your streak is set."
            creditToastMessage = "Daily credits already earned. Come back tomorrow for +\(dailyFuelCreditAward)."
            return
        }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()).map { Self.fuelDayFormatter.string(from: $0) }
        currentFuelStreak = lastFuelCheckInDay == yesterday ? currentFuelStreak + 1 : 1
        lastFuelCheckInDay = today
        fuelCheckInMessage = "Fuel logged from \(source). \(streakTitleText) active."

        let streakBonus = currentFuelStreak % 7 == 0 ? weeklyStreakCreditBonus : 0
        let totalAward = dailyFuelCreditAward + streakBonus
        let reason: String
        if streakBonus > 0 {
            reason = "\(source) and \(currentFuelStreak)-day streak"
        } else {
            reason = source
        }
        awardCredits(totalAward, reason: reason)
    }

    private func awardCredits(_ amount: Int, reason: String) {
        guard amount > 0 else { return }

        let previousRewardCount = fytrrCreditBalance / mealRewardCreditTarget
        fytrrCreditBalance += amount
        fytrrLifetimeCredits += amount
        let newRewardCount = fytrrCreditBalance / mealRewardCreditTarget

        if newRewardCount > previousRewardCount {
            creditToastMessage = "+\(amount) FYTRR Credits for \(reason). Future meal reward unlocked."
        } else {
            creditToastMessage = "+\(amount) FYTRR Credits for \(reason). \(creditsToNextMealReward) to next reward."
        }
    }

    private func updateFuelReminder(identifier: String, enabled: Bool, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()

        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            reminderStatusMessage = "Reminder removed."
            return
        }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    if identifier.contains("breakfast") {
                        isBreakfastReminderEnabled = false
                    } else if identifier.contains("lunch") {
                        isLunchReminderEnabled = false
                    } else {
                        isDinnerReminderEnabled = false
                    }
                    reminderStatusMessage = "Notifications are off. Enable them in Settings to use meal reminders."
                    return
                }

                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute

                let content = UNMutableNotificationContent()
                content.title = "FYTRR Fuel Window"
                content.body = "Open FYTRR for nearby meals that match your goal."
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                center.removePendingNotificationRequests(withIdentifiers: [identifier])
                center.add(request) { error in
                    DispatchQueue.main.async {
                        reminderStatusMessage = error == nil
                            ? "Daily reminder scheduled."
                            : "Could not schedule reminder. Try again."
                    }
                }
            }
        }
    }

    private func updateNearbyOpenTrigger() {
        guard let first = topFuelRecommendations.first else {
            nearbyOpenTriggerMessage = nil
            return
        }

        let distance = first.restaurant.formattedDistance ?? "nearby"
        nearbyOpenTriggerMessage = "Best nearby now: \(first.restaurant.name) • \(distance)"
    }

    private func loadProfileAssets() {
        profilePhotoData = ProfileStore.loadProfilePhotoData(uid: profileStorageID)
        mealOrderHistory = ProfileStore.loadMealHistory(uid: profileStorageID)
    }

    private func recordMealOrder(restaurantName: String, provider: DeliveryProvider) {
        let entry = MealOrderEntry(
            id: UUID().uuidString,
            restaurantName: restaurantName,
            provider: provider.rawValue,
            orderedAt: Date()
        )
        ProfileStore.addMealOrder(entry, uid: profileStorageID)
        mealOrderHistory = ProfileStore.loadMealHistory(uid: profileStorageID)
        registerFuelCheckIn(source: restaurantName)

        let today = Self.fuelDayFormatter.string(from: Date())
        let creditKey = "\(today)|\(provider.rawValue)|\(restaurantName.lowercased())"
        if lastMealOrderCreditKey != creditKey {
            lastMealOrderCreditKey = creditKey
            awardCredits(mealOrderCreditAward, reason: "opening \(provider.rawValue)")
        } else {
            creditToastMessage = "Order credits already earned for this pick today."
        }

        if mealOrderHistory.count % 10 == 0 {
            orderCelebrationMessage = "Impact unlocked: You just funded 1 child meal."
        } else {
            orderCelebrationMessage = "\(mealsToNextChildImpact) meals until your next child meal is funded."
        }
    }

    private func saveProfileSettings() {
        guard var existingProfile = profile else { return }

        existingProfile.goal = profileGoal
        existingProfile.activityLevel = profileActivityLevel
        existingProfile.mealsPerDay = profileMealsPerDay
        existingProfile.maxPriceTier = profileMaxPriceTier
        existingProfile.prioritizeHighProtein = profilePrioritizeHighProtein
        existingProfile.proteinTargetMultiplier = min(1.2, max(0.7, profileProteinTargetMultiplier))
        existingProfile.backgroundTheme = selectedProfileTheme.rawValue
        existingProfile.dailyCalories = CalorieCalculator.calculate(
            age: existingProfile.age,
            sex: existingProfile.sex,
            heightFeet: existingProfile.heightFeet,
            heightInches: existingProfile.heightInches,
            weightLbs: existingProfile.weightLbs,
            activityLevel: profileActivityLevel,
            goal: profileGoal
        )

        BrandThemeStore.current = selectedProfileTheme
        appState.currentUserProfile = existingProfile

        guard let uid = Auth.auth().currentUser?.uid else {
            profileUpdateMessage = "Profile updated locally. Sign in to sync changes."
            return
        }

        isSavingProfile = true
        profileUpdateMessage = nil

        let didSave = ProfileStore.saveProfile(existingProfile, uid: uid)
        DispatchQueue.main.async {
            self.isSavingProfile = false
            self.profileUpdateMessage = didSave
                ? "Profile updated successfully."
                : "Unable to save changes. Please try again."
        }
    }

    private func syncMapCamera() {
        guard let location = locationManager.location else { return }
        updateMapCamera(center: location.coordinate)
    }

    private func updateMapCamera(center: CLLocationCoordinate2D) {
        let delta = max(0.02, radiusMiles / 35.0)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        )

        mapCameraPosition = .region(region)
        mapSearchCenter = center
    }

    private func searchCityAndFetch(_ city: String) {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCity.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let placemarks = try await CLGeocoder().geocodeAddressString(trimmedCity)
                guard let coordinate = placemarks.first?.location?.coordinate else {
                    throw NSError(
                        domain: "FYTRR.CitySearch",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "City not found. Try a different city name."]
                    )
                }

                await MainActor.run {
                    updateMapCamera(center: coordinate)
                }
                fetchRestaurants(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Couldn't find that city. Try full city name (for example: Miami, FL)."
                }
            }
        }
    }

    private func loadReadinessMetrics() {
        guard isHealthIntegrationEnabled else {
            sleepHours = nil
            trainingStrain = nil
            vo2Max = nil
            activeEnergyKcal = nil
            basalEnergyKcal = nil
            performanceMessage = "Apple Watch fuel balance is off."
            return
        }

        healthKitManager.refreshConnectionState()

        guard healthKitManager.isAvailable else {
            performanceMessage = "Apple Health is unavailable on this device."
            return
        }

        isReadinessLoading = true
        Task {
            do {
                let metrics = try await healthKitManager.fetchTodayMetrics()
                await MainActor.run {
                    self.sleepHours = metrics.sleepHours
                    self.trainingStrain = metrics.trainingStrain
                    self.vo2Max = metrics.vo2Max
                    self.activeEnergyKcal = metrics.activeEnergyKcal
                    self.basalEnergyKcal = metrics.basalEnergyKcal
                    self.isReadinessLoading = false

                    if metrics.sleepHours == nil
                        && metrics.trainingStrain == nil
                        && metrics.vo2Max == nil
                        && metrics.activeEnergyKcal == nil
                        && metrics.basalEnergyKcal == nil {
                        self.performanceMessage = "Connected. No recent Apple Health data yet."
                    } else {
                        self.performanceMessage = "Apple Health fuel balance synced."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isReadinessLoading = false
                    self.performanceMessage = "Unable to sync Apple Health right now. Try again."
                }
            }
        }
    }

    private func connectAndLoadReadinessMetrics() {
        guard healthKitManager.isAvailable else {
            performanceMessage = "Apple Health is unavailable on this device."
            return
        }

        isReadinessLoading = true
        performanceMessage = "Opening Apple Health permission..."

        Task {
            do {
                try await healthKitManager.requestAuthorization()
                await MainActor.run {
                    self.isReadinessLoading = false
                }
                loadReadinessMetrics()
            } catch {
                await MainActor.run {
                    self.isReadinessLoading = false
                    self.performanceMessage = "Apple Health permission was not completed. Open Health permissions in Settings and try again."
                    self.healthKitManager.refreshConnectionState()
                }
            }
        }
    }

    private func deliveryBadge(for index: Int, recommendation: RestaurantRecommendation) -> String {
        if index == 0 { return "Best Match" }
        if (recommendation.restaurant.distance ?? .greatestFiniteMagnitude) < 1609.34 { return "Fastest" }
        if recommendation.restaurant.price == "$" { return "Best Value" }
        return "Top Pick"
    }

    private func openSelectedProvider(for restaurantName: String) {
        switch selectedDeliveryProvider {
        case .doorDash:
            openDoorDash(for: restaurantName)
        case .uberEats:
            openUberEats(for: restaurantName)
        }
    }

    private func openDoorDash(for restaurantName: String) {
        recordMealOrder(restaurantName: restaurantName, provider: .doorDash)
        guard let url = doorDashURL(for: restaurantName) else { return }
        openURL(url)
    }

    private func openUberEats(for restaurantName: String) {
        recordMealOrder(restaurantName: restaurantName, provider: .uberEats)
        guard let url = uberEatsURL(for: restaurantName) else { return }
        openURL(url)
    }

    private func doorDashURL(for restaurantName: String) -> URL? {
        let encoded = restaurantName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? restaurantName
        return URL(string: "https://www.doordash.com/search/store/\(encoded)/")
    }

    private func uberEatsURL(for restaurantName: String) -> URL? {
        var components = URLComponents(string: "https://www.ubereats.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: restaurantName)]
        return components?.url
    }

    private func openMenu(for restaurant: Restaurant) {
        if let url = restaurant.bestMenuURL {
            openURL(url)
        } else if let yelpURL = restaurant.yelpURL, let url = URL(string: yelpURL) {
            openURL(url)
        } else {
            openSelectedProvider(for: restaurant.name)
        }
    }

    private func openDirections(for restaurant: Restaurant) {
        var components = URLComponents(string: "https://maps.apple.com/")

        if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
            components?.queryItems = [
                URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
                URLQueryItem(name: "q", value: restaurant.name),
                URLQueryItem(name: "dirflg", value: "d")
            ]
        } else {
            let destination = [restaurant.name, restaurant.formattedAddress]
                .compactMap { $0 }
                .joined(separator: ", ")
            components?.queryItems = [
                URLQueryItem(name: "daddr", value: destination),
                URLQueryItem(name: "q", value: restaurant.name),
                URLQueryItem(name: "dirflg", value: "d")
            ]
        }

        guard let url = components?.url else { return }
        openURL(url)
    }

    func fetchRestaurants(location: CLLocation) {
        isLoading = true
        errorMessage = nil
        isUsingFallbackData = false

        Task {
            do {
                let results = try await service.fetchNearby(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude,
                    radiusMiles: radiusMiles
                )

                await MainActor.run {
                    self.restaurants = results
                    self.isLoading = false
                    self.lastUpdatedAt = Date()
                    self.isUsingFallbackData = results.allSatisfy { $0.id.hasPrefix("mock-") }
                    self.updateMapCamera(center: location.coordinate)
                    self.updateNearbyOpenTrigger()
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func loadFallbackData() {
        let center = mapSearchCenter ?? CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        restaurants = service.fallbackNearby(lat: center.latitude, lon: center.longitude)
        isUsingFallbackData = true
        isLoading = false
        errorMessage = nil
        lastUpdatedAt = Date()
        updateNearbyOpenTrigger()
    }
}

private struct FullScreenMapExperience: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var radiusMiles: Double
    @Binding var mapCameraPosition: MapCameraPosition

    let mapPoints: [RestaurantMapPoint]
    let recommendations: [RestaurantRecommendation]
    let isLoading: Bool
    let errorMessage: String?
    let onUseCurrentLocation: () -> Void
    let onSearchCurrentArea: () -> Void
    let onSearchCity: (String) -> Void
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    let mealTargetCalories: Int?
    let onOpenMenu: (Restaurant) -> Void
    let onOpenDirections: (Restaurant) -> Void
    let onOrderDoorDash: (String) -> Void

    @State private var searchText: String = ""
    @State private var citySearchText: String = ""
    @State private var selectedRecommendation: RestaurantRecommendation?
    @State private var hasPendingAreaSearch = false
    @State private var lastSearchedCenter: CLLocationCoordinate2D?
    @State private var lastSearchedSpan: MKCoordinateSpan?
    @State private var latestMapRegion: MKCoordinateRegion?
    @State private var isShowingListSheet = false
    @State private var rotatingSearchIndex = 0
    @State private var activeQuickFilter: MapQuickFilter?

    private let mapPrimaryColor = BrandPalette.accent
    private let mapInkColor = Color(red: 0.13, green: 0.13, blue: 0.14)
    private let mapMutedColor = Color(red: 0.43, green: 0.43, blue: 0.46)
    private let mapSurfaceColor = Color.white
    private let mapSecondaryColor = BrandPalette.accent.opacity(0.16)
    private let rotatingSearchHints: [String] = ["High protein", "Low carb", "Chipotle", "CAVA", "Panera", "Jersey Mike's"]

    var body: some View {
        NavigationStack {
            ZStack {
                mapCard
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandInlineLockup(markHeight: 30, wordmarkHeight: 38, spacing: 8)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(mapPrimaryColor)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var searchPromptText: String {
        guard !rotatingSearchHints.isEmpty else { return "Search restaurant or cuisine" }
        return "Search for \(rotatingSearchHints[rotatingSearchIndex])"
    }

    private var filteredSearchRecommendations: [RestaurantRecommendation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var results = recommendations

        if !query.isEmpty {
            results = results.filter { recommendation in
                recommendation.restaurant.name.lowercased().contains(query)
                    || recommendation.restaurant.formattedCategories.lowercased().contains(query)
                    || recommendation.reason.lowercased().contains(query)
            }
        }

        if let activeQuickFilter {
            results = results.filter { recommendation in
                switch activeQuickFilter {
                case .highProtein:
                    return isHighProteinRestaurant(recommendation.restaurant)
                case .topRated:
                    return recommendation.restaurant.rating >= 4.5
                case .nearMe:
                    guard let distance = recommendation.restaurant.distance else { return false }
                    return distance <= 3218.68
                case .value:
                    guard let price = recommendation.restaurant.price else { return true }
                    return price.count <= 2
                }
            }
        }

        return results
    }

    private var mapResultsSummary: String {
        if isLoading { return "Loading nearby fuel" }
        if visibleRecommendations.isEmpty { return "No visible matches" }
        let countText = visibleRecommendations.count == 1 ? "1 match" : "\(visibleRecommendations.count) matches"
        if let activeQuickFilter { return "\(countText) • \(activeQuickFilter.rawValue)" }
        return "\(countText) nearby"
    }

    private var topRecommendations: [RestaurantRecommendation] {
        Array(
            filteredSearchRecommendations
                .sorted { lhs, rhs in
                    if lhs.score != rhs.score { return lhs.score > rhs.score }
                    return (lhs.restaurant.distance ?? .greatestFiniteMagnitude) < (rhs.restaurant.distance ?? .greatestFiniteMagnitude)
                }
                .prefix(10)
        )
    }

    private var visibleRecommendations: [RestaurantRecommendation] {
        topRecommendations
    }

    private var visibleMapPoints: [RestaurantMapPoint] {
        visibleRecommendations.compactMap { recommendation in
            mapPoints.first(where: { $0.id == recommendation.id })
        }
    }

    private var mapCard: some View {
        ZStack(alignment: .top) {
            Map(position: $mapCameraPosition) {
                ForEach(Array(visibleMapPoints.enumerated()), id: \.element.id) { index, point in
                    Annotation(point.name, coordinate: point.coordinate) {
                        yelpStylePin(number: index + 1, isSelected: selectedRecommendation?.id == point.id)
                            .onTapGesture {
                                selectedRecommendation = visibleRecommendations.first(where: { $0.id == point.id })
                            }
                    }
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                mapCenterCoordinate = context.region.center
                latestMapRegion = context.region
                hasPendingAreaSearch = shouldShowAreaSearchButton(for: context.region)
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .accessibilityIdentifier("home_fullscreen_map_view")

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(mapPrimaryColor)
                        TextField(
                            "",
                            text: $searchText,
                            prompt: Text(searchPromptText)
                                .font(.custom("AvenirNext-Regular", size: 14))
                                .foregroundStyle(mapMutedColor)
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(mapInkColor)
                        .tint(mapPrimaryColor)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(mapSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 5)

                    Button {
                        isShowingListSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                            Text("List")
                        }
                        .font(.custom("AvenirNext-DemiBold", size: 13))
                        .foregroundStyle(mapInkColor)
                        .padding(.horizontal, 13)
                        .frame(height: 48)
                        .background(mapSurfaceColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
                    }
                    .accessibilityIdentifier("fuel_map_list_button")
                }

                quickFilterBar

                Text(mapResultsSummary)
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(mapInkColor)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(mapSurfaceColor.opacity(0.94))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)

                if hasPendingAreaSearch {
                    Button {
                        onSearchCurrentArea()
                        if let center = mapCenterCoordinate {
                            lastSearchedCenter = center
                        }
                        if let region = latestMapRegion {
                            lastSearchedSpan = region.span
                        }
                        hasPendingAreaSearch = false
                    } label: {
                        Label("Search this area", systemImage: "arrow.clockwise")
                    }
                    .font(.custom("AvenirNext-Heavy", size: 14))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(mapPrimaryColor)
                    .clipShape(Capsule())
                    .shadow(color: mapPrimaryColor.opacity(0.35), radius: 14, x: 0, y: 5)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            if isLoading {
                ProgressView("Loading fuel spots...")
                    .tint(mapPrimaryColor)
                    .padding(.top, 136)
            }

            if let errorMessage, visibleRecommendations.isEmpty {
                mapStatusMessage(errorMessage, warning: true)
                    .padding(.top, 180)
            } else if visibleRecommendations.isEmpty && !isLoading {
                mapStatusMessage("No matches yet. Move the map, increase radius, or adjust your search.", warning: false)
                    .padding(.top, 180)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        onUseCurrentLocation()
                        onSearchCurrentArea()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 54, height: 54)
                            .background(mapPrimaryColor)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 176)
                    .accessibilityIdentifier("fuel_map_location_button")
                }
            }

            bottomRecommendationRail
        }
        .sheet(item: $selectedRecommendation) { recommendation in
            MapRestaurantDetailSheet(
                recommendation: recommendation,
                mealTargetCalories: mealTargetCalories,
                onOpenMenu: onOpenMenu,
                onOpenDirections: onOpenDirections,
                onOrderDoorDash: onOrderDoorDash
            )
        }
        .sheet(isPresented: $isShowingListSheet) {
            mapListSheet
        }
        .onAppear {
            if abs(radiusMiles - 3.0) > 0.001 {
                radiusMiles = 3.0
            }
            if lastSearchedCenter == nil {
                lastSearchedCenter = mapCenterCoordinate
            }
            if lastSearchedSpan == nil {
                if let region = latestMapRegion {
                    lastSearchedSpan = region.span
                }
            }
            onSearchCurrentArea()
        }
        .task {
            guard rotatingSearchHints.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                if searchText.isEmpty {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            rotatingSearchIndex = (rotatingSearchIndex + 1) % rotatingSearchHints.count
                        }
                    }
                }
            }
        }
    }

    private var quickFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapQuickFilter.allCases) { filter in
                    quickFilterChip(filter)
                }

                if activeQuickFilter != nil {
                    Button("Clear") {
                        activeQuickFilter = nil
                    }
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundStyle(mapPrimaryColor)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(mapSurfaceColor)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private func quickFilterChip(_ filter: MapQuickFilter) -> some View {
        let isSelected = activeQuickFilter == filter
        return Button {
            activeQuickFilter = isSelected ? nil : filter
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .bold))
                Text(filter.rawValue)
                    .font(.custom("AvenirNext-DemiBold", size: 12))
            }
            .foregroundStyle(isSelected ? .black : mapInkColor)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(isSelected ? mapPrimaryColor : mapSurfaceColor)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(isSelected ? 0.20 : 0.12), radius: 8, x: 0, y: 4)
        }
    }

    private func isHighProteinRestaurant(_ restaurant: Restaurant) -> Bool {
        let text = "\(restaurant.name.lowercased()) \(restaurant.searchableCategoryText)"
        return ["protein", "grill", "chicken", "steak", "poke", "bbq", "cava", "chipotle", "mediterranean", "seafood", "korean", "jersey mike"]
            .contains { text.contains($0) }
    }

    private func yelpStylePin(number: Int, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? mapInkColor : mapPrimaryColor)
                .frame(width: isSelected ? 42 : 36, height: isSelected ? 42 : 36)
                .shadow(color: Color.black.opacity(0.26), radius: 8, x: 0, y: 4)

            Text("\(number)")
                .font(.system(size: isSelected ? 16 : 14, weight: .heavy))
                .foregroundStyle(isSelected ? .white : .black)
        }
        .overlay(Circle().stroke(.white, lineWidth: 4))
        .contentShape(Circle())
    }

    private var bottomRecommendationRail: some View {
        VStack {
            Spacer()

            if !visibleRecommendations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(visibleRecommendations.prefix(8).enumerated()), id: \.element.id) { index, recommendation in
                            mapPreviewCard(recommendation: recommendation, rank: index + 1)
                                .onTapGesture {
                                    selectedRecommendation = recommendation
                                }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
                .background(
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
            }
        }
    }

    private func mapPreviewCard(recommendation: RestaurantRecommendation, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(mapPrimaryColor)
                        .frame(width: 54, height: 54)

                    Text("\(rank)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(recommendation.restaurant.name)
                        .font(.custom("AvenirNext-Heavy", size: 17))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(recommendation.restaurant.formattedCategories)
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        darkRatingBadge(recommendation.restaurant.rating)
                        if let price = recommendation.restaurant.price {
                            Text(price)
                                .font(.custom("AvenirNext-DemiBold", size: 12))
                                .foregroundStyle(Color.white.opacity(0.72))
                        }
                        if let distance = recommendation.restaurant.formattedDistance {
                            Text(distance)
                                .font(.custom("AvenirNext-DemiBold", size: 12))
                                .foregroundStyle(Color.white.opacity(0.72))
                                .lineLimit(1)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button {
                    onOpenMenu(recommendation.restaurant)
                } label: {
                    mapActionLabel(title: "Menu", icon: "menucard", isPrimary: false)
                }

                Button {
                    onOrderDoorDash(recommendation.restaurant.name)
                } label: {
                    mapActionLabel(title: "Order", icon: "bag", isPrimary: true)
                }

                Button {
                    onOpenDirections(recommendation.restaurant)
                } label: {
                    mapActionLabel(title: "Go", icon: "arrow.triangle.turn.up.right.diamond", isPrimary: false)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 326, alignment: .leading)
        .background(Color.black.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(mapPrimaryColor.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.36), radius: 20, x: 0, y: 9)
    }

    private func darkRatingBadge(_ rating: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .black))
            Text(rating.formatted(.number.precision(.fractionLength(1))))
                .font(.custom("AvenirNext-DemiBold", size: 12))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 7)
        .frame(height: 22)
        .background(mapPrimaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func mapActionLabel(title: String, icon: String, isPrimary: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 11))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isPrimary ? .black : .white)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(isPrimary ? mapPrimaryColor : Color.white.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isPrimary ? mapPrimaryColor : Color.white.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func ratingBadge(_ rating: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .black))
            Text(rating.formatted(.number.precision(.fractionLength(1))))
                .font(.custom("AvenirNext-DemiBold", size: 12))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .frame(height: 22)
        .background(mapPrimaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func mapStatusMessage(_ message: String, warning: Bool) -> some View {
        Text(message)
            .font(.custom("AvenirNext-Regular", size: 14))
            .foregroundStyle(warning ? BrandPalette.warning : mapMutedColor)
            .padding(12)
            .background(mapSurfaceColor.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
    }

    private var mapListSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(mapPrimaryColor)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 7) {
                                Text(recommendation.restaurant.name)
                                    .font(.custom("AvenirNext-DemiBold", size: 17))
                                    .foregroundStyle(mapInkColor)

                                Text(recommendation.reason)
                                    .font(.custom("AvenirNext-Regular", size: 13))
                                    .foregroundStyle(mapMutedColor)

                                HStack(spacing: 8) {
                                    ratingBadge(recommendation.restaurant.rating)

                                    if let price = recommendation.restaurant.price {
                                        Text(price)
                                            .font(.custom("AvenirNext-DemiBold", size: 12))
                                            .foregroundStyle(mapMutedColor)
                                    }

                                    if let distance = recommendation.restaurant.formattedDistance {
                                        Label(distance, systemImage: "location")
                                            .foregroundStyle(mapMutedColor)
                                    }
                                }
                                .font(.custom("AvenirNext-Medium", size: 12))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(mapSurfaceColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onTapGesture {
                            selectedRecommendation = recommendation
                            isShowingListSheet = false
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(red: 0.94, green: 0.95, blue: 0.93))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Fuel Nearby")
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundStyle(mapInkColor)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isShowingListSheet = false
                    }
                    .foregroundStyle(mapPrimaryColor)
                }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    private func shouldShowAreaSearchButton(for region: MKCoordinateRegion) -> Bool {
        guard let lastSearchedCenter else { return false }
        let oldCenter = CLLocation(latitude: lastSearchedCenter.latitude, longitude: lastSearchedCenter.longitude)
        let newCenter = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let movedEnough = oldCenter.distance(from: newCenter) > 200

        let zoomChangedEnough: Bool = {
            guard let lastSearchedSpan else { return false }
            let latRatio = abs(region.span.latitudeDelta - lastSearchedSpan.latitudeDelta) / max(lastSearchedSpan.latitudeDelta, 0.0001)
            let lonRatio = abs(region.span.longitudeDelta - lastSearchedSpan.longitudeDelta) / max(lastSearchedSpan.longitudeDelta, 0.0001)
            return latRatio > 0.2 || lonRatio > 0.2
        }()

        return movedEnough || zoomChangedEnough
    }
}

private struct MapRestaurantDetailSheet: View {
    let recommendation: RestaurantRecommendation
    let mealTargetCalories: Int?
    let onOpenMenu: (Restaurant) -> Void
    let onOpenDirections: (Restaurant) -> Void
    let onOrderDoorDash: (String) -> Void

    private var menuRecommendationText: String {
        let categoryText = "\(recommendation.restaurant.name.lowercased()) \(recommendation.restaurant.searchableCategoryText)"
        let calorieText = mealTargetCalories.map { "around \($0) calories" } ?? "balanced calories"
        let prefix = recommendation.restaurant.bestMenuURL == nil ? "Recommended" : "Menu-informed pick"

        if categoryText.contains("chipotle") {
            return "\(prefix): Chicken bowl with fajita veggies, salsa, and black beans, \(calorieText)."
        }
        if categoryText.contains("cava") {
            return "\(prefix): Grilled chicken greens + grains bowl with sauce on the side, \(calorieText)."
        }
        if categoryText.contains("sweetgreen") {
            return "\(prefix): Harvest bowl with extra chicken or protein salad, \(calorieText)."
        }
        if categoryText.contains("panera") {
            return "\(prefix): Greek salad with chicken or turkey chili, \(calorieText)."
        }

        if categoryText.contains("poke") {
            return "\(prefix): Salmon poke bowl with extra greens, \(calorieText)."
        }
        if categoryText.contains("mediterranean") {
            return "\(prefix): Chicken + hummus bowl with double veggies, \(calorieText)."
        }
        if categoryText.contains("grill") || categoryText.contains("chicken") {
            return "\(prefix): Grilled chicken plate with rice and vegetables, \(calorieText)."
        }
        if categoryText.contains("salad") || categoryText.contains("healthy") {
            return "\(prefix): Protein salad with lean chicken and olive oil dressing, \(calorieText)."
        }
        return "\(prefix): Lean protein bowl with vegetables, \(calorieText)."
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 44, height: 5)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 4)

                Text(recommendation.restaurant.name)
                    .font(.custom("AvenirNext-Heavy", size: 24))
                    .foregroundStyle(BrandPalette.textPrimary)

                Text(menuRecommendationText)
                    .font(.custom("AvenirNext-Regular", size: 15))
                    .foregroundStyle(BrandPalette.textSecondary)

                HStack(spacing: 8) {
                    Label(recommendation.restaurant.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(BrandPalette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    if let price = recommendation.restaurant.price {
                        Text(price)
                            .foregroundStyle(BrandPalette.textSecondary)
                    }

                    if let distance = recommendation.restaurant.formattedDistance {
                        Label(distance, systemImage: "location")
                            .foregroundStyle(BrandPalette.textSecondary)
                    }
                }
                .font(.custom("AvenirNext-DemiBold", size: 13))

                Button {
                    onOpenMenu(recommendation.restaurant)
                } label: {
                    Label("Menu", systemImage: "menucard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(BrandPalette.accent)

                Button {
                    onOpenDirections(recommendation.restaurant)
                } label: {
                    Label("Go", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(BrandPalette.accent)

                Button {
                    onOrderDoorDash(recommendation.restaurant.name)
                } label: {
                    Label("Order", systemImage: "bag")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle())

                Spacer()
            }
            .padding(20)
            .background(BrandBackground())
            .navigationTitle("Menu Pick")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(previewAppState())
}

private func previewAppState() -> AppState {
    let state = AppState()
    state.isLoggedIn = true
    state.hasCompletedProfile = true
    state.currentUserProfile = UserProfile(
        name: "Alex",
        age: 28,
        sex: "Male",
        heightFeet: 5,
        heightInches: 11,
        weightLbs: 178,
        goal: "Maintain",
        activityLevel: "Moderate",
        dailyCalories: 2400,
        mealsPerDay: 3
    )
    return state
}
