import SwiftUI
import FirebaseAuth
import CoreLocation
import UserNotifications

private enum ProfileSetupStep: Int, CaseIterable {
    case personal
    case training
    case permissions
    case review

    var title: String {
        switch self {
        case .personal: return "Personal"
        case .training: return "Training"
        case .permissions: return "Access"
        case .review: return "Review"
        }
    }
}

struct ProfileSetupView: View {

    @EnvironmentObject var appState: AppState

    @State private var name = ""
    @State private var age = ""
    @State private var sex = "Male"
    @State private var heightFeet = 5
    @State private var heightInches = 10
    @State private var weight = ""
    @State private var activityLevel = "Moderate"
    @State private var goal = "Maintain"
    @State private var mealsPerDay = 3
    @State private var maxPriceTier = 3
    @State private var prioritizeHighProtein = true
    @State private var proteinTargetMultiplier = 0.8
    @State private var selectedBackgroundTheme: BrandTheme = BrandThemeStore.current
    @StateObject private var onboardingHealthKitManager = HealthKitManager()
    @State private var step: ProfileSetupStep = .personal

    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var locationPermissionRequested = false
    @State private var healthPermissionRequested = false
    @State private var notificationPermissionRequested = false
    @State private var permissionStatusMessage: String?

    private let completionLocationManager = CLLocationManager()

    private let sexOptions = ["Male", "Female"]
    private let activityOptions = ["Low", "Moderate", "High"]
    private let goalOptions = ["Lose Fat", "Maintain", "Gain Muscle"]
    private let mealOptions = Array(1...6)
    private let proteinMultiplierOptions = [0.7, 0.8, 0.9, 1.0, 1.2]

    private var progressValue: Double {
        Double(step.rawValue + 1) / Double(ProfileSetupStep.allCases.count)
    }

    private var isPersonalValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let ageInt = Int(age), (13...90).contains(ageInt) else { return false }
        guard let weightDouble = Double(weight), weightDouble > 70, weightDouble < 700 else { return false }
        return true
    }

    private var canContinue: Bool {
        switch step {
        case .personal:
            return isPersonalValid
        case .training, .permissions, .review:
            return true
        }
    }

    var body: some View {
        ZStack {
            BrandBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    progressCard
                    stepContent
                    actionRow

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.custom("AvenirNext-Regular", size: 13))
                            .foregroundStyle(BrandPalette.warning)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
        }
        .environment(\.colorScheme, .dark)
        .onChange(of: selectedBackgroundTheme) { _, newTheme in
            BrandThemeStore.current = newTheme
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandWordmark(height: 52)

            Text("Build Your Profile")
                .font(.custom("AvenirNext-Heavy", size: 30))
                .foregroundStyle(.white)

            Text("Step-by-step setup so recommendations match your exact routine.")
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundStyle(.white.opacity(0.84))
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(step.title) Step")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(BrandPalette.textPrimary)
                Spacer()
                Text("\(step.rawValue + 1)/\(ProfileSetupStep.allCases.count)")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            ProgressView(value: progressValue)
                .tint(BrandPalette.accent)
        }
        .brandCard()
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .personal:
            personalSection
        case .training:
            trainingSection
        case .permissions:
            permissionsSection
        case .review:
            reviewSection
        }
    }

    private var personalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundStyle(BrandPalette.textPrimary)

            TextField(
                "",
                text: $name,
                prompt: Text("Name")
                    .foregroundStyle(BrandPalette.textSecondary.opacity(0.8))
            )
                .brandFieldStyle()
                .accessibilityIdentifier("profile_name_field")

            HStack(spacing: 10) {
                TextField(
                    "",
                    text: $age,
                    prompt: Text("Age")
                        .foregroundStyle(BrandPalette.textSecondary.opacity(0.8))
                )
                    .keyboardType(.numberPad)
                    .brandFieldStyle()
                    .accessibilityIdentifier("profile_age_field")

                TextField(
                    "",
                    text: $weight,
                    prompt: Text("Weight (lbs)")
                        .foregroundStyle(BrandPalette.textSecondary.opacity(0.8))
                )
                    .keyboardType(.decimalPad)
                    .brandFieldStyle()
                    .accessibilityIdentifier("profile_weight_field")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Sex")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)

                Picker("Sex", selection: $sex) {
                    ForEach(sexOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .tint(BrandPalette.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Background")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)

                HStack(spacing: 8) {
                    ForEach(BrandTheme.allCases) { theme in
                        themeChoiceButton(theme)
                    }
                }
            }
        }
        .brandCard()
    }

    private func themeChoiceButton(_ theme: BrandTheme) -> some View {
        let isSelected = selectedBackgroundTheme == theme

        return Button {
            selectedBackgroundTheme = theme
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 28, height: 28)
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
            .background(isSelected ? BrandPalette.accent.opacity(0.16) : BrandPalette.elevated)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? BrandPalette.accent : BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.title) background")
    }

    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Goals")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundStyle(BrandPalette.textPrimary)

            Text("Set your goal and activity level so fueling recommendations match your training.")
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(BrandPalette.textSecondary)

            Text("Height")
                .font(.custom("AvenirNext-Medium", size: 13))
                .foregroundStyle(BrandPalette.textSecondary)

            HStack(spacing: 10) {
                Picker("Feet", selection: $heightFeet) {
                    ForEach(4...7, id: \.self) { value in
                        Text("\(value) ft").tag(value)
                    }
                }
                .brandFieldStyle()

                Picker("Inches", selection: $heightInches) {
                    ForEach(0...11, id: \.self) { value in
                        Text("\(value) in").tag(value)
                    }
                }
                .brandFieldStyle()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Goal")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)

                Picker("Goal", selection: $goal) {
                    ForEach(goalOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .brandFieldStyle()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Activity Level")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)

                Picker("Activity Level", selection: $activityLevel) {
                    ForEach(activityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .brandFieldStyle()
            }

            Picker("Meals per day", selection: $mealsPerDay) {
                ForEach(mealOptions, id: \.self) { count in
                    Text("\(count) meals/day").tag(count)
                }
            }
            .brandFieldStyle()

            Stepper(value: $maxPriceTier, in: 1...4) {
                Text("Max price: \(String(repeating: "$", count: maxPriceTier))")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(BrandPalette.textPrimary)
            }

            Toggle(isOn: $prioritizeHighProtein) {
                Text("Prioritize high-protein options")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(BrandPalette.textPrimary)
            }
            .tint(BrandPalette.accent)

            VStack(alignment: .leading, spacing: 6) {
                Text("Protein target")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)

                Picker("Protein target", selection: $proteinTargetMultiplier) {
                    ForEach(proteinMultiplierOptions, id: \.self) { option in
                        Text(String(format: "%.1fx", option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .tint(BrandPalette.accent)

                Text("Aim for \(previewProteinTarget.map { "\($0)g" } ?? "--") protein/day based on bodyweight.")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }
        }
        .brandCard()
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Connect FYTRR")
                    .font(.custom("AvenirNext-Heavy", size: 18))
                    .foregroundStyle(BrandPalette.textPrimary)

                Text("Enable the essentials now so your map, Apple Watch fuel balance, and meal reminders work on day one.")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            permissionActionRow(
                icon: "location.fill",
                title: "Location",
                subtitle: "Find the best nearby fuel spots.",
                status: locationPermissionRequested ? "Requested" : "Recommended",
                actionTitle: locationPermissionRequested ? "Requested" : "Allow"
            ) {
                completionLocationManager.requestWhenInUseAuthorization()
                locationPermissionRequested = true
                permissionStatusMessage = "Location permission requested."
            }

            permissionActionRow(
                icon: "applewatch",
                title: "Apple Watch + Health",
                subtitle: "Compare calories burned against your daily need.",
                status: healthPermissionRequested ? "Connected" : appleHealthOnboardingStatus,
                actionTitle: healthPermissionRequested ? "Sync" : "Connect"
            ) {
                requestOnboardingHealthAccess()
            }

            permissionActionRow(
                icon: "bell.fill",
                title: "Meal Reminders",
                subtitle: "Use breakfast, lunch, and dinner reminders later.",
                status: notificationPermissionRequested ? "Allowed" : "Optional",
                actionTitle: notificationPermissionRequested ? "Allowed" : "Allow"
            ) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        notificationPermissionRequested = granted
                        permissionStatusMessage = granted ? "Meal reminder permission allowed." : "Notifications were not enabled."
                    }
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(BrandPalette.accent)
                Text("Every 10 meals through FYTRR helps feed a child.")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(BrandPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(BrandPalette.accent.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(BrandPalette.accent.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if let permissionStatusMessage {
                Text(permissionStatusMessage)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }
        }
        .brandCard()
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                BrandNeonLogo(size: 62)
                    .padding(6)
                    .background(BrandPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Final Check")
                        .font(.custom("AvenirNext-Heavy", size: 22))
                        .foregroundStyle(BrandPalette.textPrimary)

                    Text("Your profile is ready for smarter nearby meals, reminders, and fuel balance.")
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundStyle(BrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                reviewHighlightPill(
                    title: "Daily",
                    value: previewDailyCalories.map { "\($0)" } ?? "--",
                    subtitle: "Calories"
                )
                reviewHighlightPill(
                    title: "Per Meal",
                    value: previewPerMealCalories.map { "\($0)" } ?? "--",
                    subtitle: "Target"
                )
                reviewHighlightPill(
                    title: "Protein",
                    value: previewProteinTarget.map { "\($0)g" } ?? "--",
                    subtitle: String(format: "%.1fx", proteinTargetMultiplier)
                )
            }

            HStack(spacing: 10) {
                reviewBenefitPill(icon: "location.fill", title: "Local fuel")
                reviewBenefitPill(icon: "applewatch", title: "Watch ready")
                reviewBenefitPill(icon: "heart.fill", title: "10 meals feed 1")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Profile Summary")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)

                reviewItem(label: "Name", value: name)
                reviewItem(label: "Age", value: age)
                reviewItem(label: "Weight", value: "\(weight) lbs")
                reviewItem(label: "Height", value: "\(heightFeet) ft \(heightInches) in")
                reviewItem(label: "Goal", value: goal)
                reviewItem(label: "Activity Level", value: activityLevel)
                reviewItem(label: "Max Price", value: String(repeating: "$", count: maxPriceTier))
                reviewItem(label: "Protein Priority", value: prioritizeHighProtein ? "On" : "Off")
                reviewItem(label: "Protein Target", value: String(format: "%.1fx bodyweight", proteinTargetMultiplier))
                reviewItem(label: "Background", value: selectedBackgroundTheme.title)
            }
            .padding(12)
            .background(BrandPalette.elevated)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(BrandPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .brandCard()
    }

    private func reviewHighlightPill(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.custom("AvenirNext-DemiBold", size: 10))
                .foregroundStyle(BrandPalette.textSecondary)

            Text(value)
                .font(.custom("AvenirNext-Heavy", size: 18))
                .foregroundStyle(BrandPalette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.custom("AvenirNext-Regular", size: 11))
                .foregroundStyle(BrandPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func reviewBenefitPill(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 11))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(BrandPalette.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(BrandPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func permissionActionRow(
        icon: String,
        title: String,
        subtitle: String,
        status: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(BrandPalette.backgroundTop)
                .frame(width: 40, height: 40)
                .background(BrandPalette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .foregroundStyle(BrandPalette.textPrimary)
                    Text(status)
                        .font(.custom("AvenirNext-DemiBold", size: 10))
                        .foregroundStyle(BrandPalette.accent)
                        .padding(.horizontal, 7)
                        .frame(height: 20)
                        .background(BrandPalette.accent.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(subtitle)
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            Spacer()

            Button(actionTitle, action: action)
                .font(.custom("AvenirNext-DemiBold", size: 12))
                .foregroundStyle(BrandPalette.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(BrandPalette.surface)
                .overlay(Capsule().stroke(BrandPalette.stroke, lineWidth: 1))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(BrandPalette.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BrandPalette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func reviewItem(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(BrandPalette.textSecondary)
            Spacer()
            Text(value.isEmpty ? "--" : value)
                .font(.custom("AvenirNext-DemiBold", size: 13))
                .foregroundStyle(BrandPalette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            if step != .personal {
                Button("Back") {
                    withAnimation {
                        step = ProfileSetupStep(rawValue: step.rawValue - 1) ?? .personal
                    }
                }
                .buttonStyle(BrandSecondaryButtonStyle())
            }

            if step == .review {
                Button {
                    saveProfile()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Finish Setup")
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .disabled(isLoading)
                .accessibilityIdentifier("profile_setup_finish_button")
            } else {
                Button("Continue") {
                    withAnimation {
                        step = ProfileSetupStep(rawValue: step.rawValue + 1) ?? .review
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .disabled(!canContinue)
                .accessibilityIdentifier("profile_setup_continue_button")
            }
        }
    }

    private var previewDailyCalories: Int? {
        guard let ageInt = Int(age), let weightDouble = Double(weight), !name.isEmpty else { return nil }

        return CalorieCalculator.calculate(
            age: ageInt,
            sex: sex,
            heightFeet: heightFeet,
            heightInches: heightInches,
            weightLbs: weightDouble,
            activityLevel: activityLevel,
            goal: goal
        )
    }

    private var previewPerMealCalories: Int? {
        guard let previewDailyCalories else { return nil }
        return max(250, Int((Double(previewDailyCalories) / Double(max(1, mealsPerDay))).rounded()))
    }

    private var previewProteinTarget: Int? {
        guard let weightDouble = Double(weight) else { return nil }
        return Int((weightDouble * proteinTargetMultiplier).rounded())
    }

    private var appleHealthOnboardingStatus: String {
        switch onboardingHealthKitManager.connectionState {
        case .authorized: return "Connected"
        case .denied: return "Permission Needed"
        case .notAvailable: return "Unavailable"
        case .notDetermined: return "Recommended"
        }
    }

    private func requestOnboardingHealthAccess() {
        guard onboardingHealthKitManager.isAvailable else {
            permissionStatusMessage = "Apple Health is unavailable on this device."
            return
        }

        permissionStatusMessage = "Opening Apple Health permission..."
        Task {
            do {
                try await onboardingHealthKitManager.requestAuthorization()
                await MainActor.run {
                    healthPermissionRequested = true
                    permissionStatusMessage = "Apple Health connected for fuel balance."
                }
            } catch {
                await MainActor.run {
                    onboardingHealthKitManager.refreshConnectionState()
                    permissionStatusMessage = "Apple Health permission was not completed."
                }
            }
        }
    }

    func saveProfile() {

        guard !name.isEmpty,
              let ageInt = Int(age),
              let weightDouble = Double(weight),
              (13...90).contains(ageInt),
              weightDouble > 70,
              weightDouble < 700 else {
            errorMessage = "Please enter valid name, age, and weight"
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "User not found"
            return
        }

        isLoading = true
        errorMessage = nil

        let dailyCalories = CalorieCalculator.calculate(
            age: ageInt,
            sex: sex,
            heightFeet: heightFeet,
            heightInches: heightInches,
            weightLbs: weightDouble,
            activityLevel: activityLevel,
            goal: goal
        )

        let profile = UserProfile(
            name: name,
            age: ageInt,
            sex: sex,
            heightFeet: heightFeet,
            heightInches: heightInches,
            weightLbs: weightDouble,
            goal: goal,
            activityLevel: activityLevel,
            dailyCalories: dailyCalories,
            mealsPerDay: mealsPerDay,
            maxPriceTier: maxPriceTier,
            prioritizeHighProtein: prioritizeHighProtein,
            proteinTargetMultiplier: proteinTargetMultiplier,
            backgroundTheme: selectedBackgroundTheme.rawValue
        )

        let didSave = ProfileStore.saveProfile(profile, uid: uid)

        DispatchQueue.main.async {
            isLoading = false

            if didSave {
                BrandThemeStore.current = selectedBackgroundTheme
                appState.currentUserProfile = profile
                appState.hasCompletedProfile = true
            } else {
                errorMessage = "Unable to save profile. Please try again."
            }
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AppState())
}
