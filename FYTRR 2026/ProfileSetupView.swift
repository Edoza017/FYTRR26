import SwiftUI
import FirebaseAuth
import CoreLocation

private enum ProfileSetupStep: Int, CaseIterable {
    case personal
    case training
    case review

    var title: String {
        switch self {
        case .personal: return "Personal"
        case .training: return "Training"
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
    @State private var step: ProfileSetupStep = .personal

    @State private var errorMessage: String?
    @State private var isLoading = false

    private let completionLocationManager = CLLocationManager()

    private let sexOptions = ["Male", "Female"]
    private let activityOptions = ["Low", "Moderate", "High"]
    private let goalOptions = ["Lose Fat", "Maintain", "Gain Muscle"]
    private let mealOptions = Array(1...6)

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
        case .training, .review:
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
        }
        .brandCard()
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

            Divider()
                .overlay(BrandPalette.stroke)

            Text("Permissions are requested after you finish onboarding.")
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(BrandPalette.textSecondary)
        }
        .brandCard()
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Final Check")
                    .font(.custom("AvenirNext-Heavy", size: 18))
                    .foregroundStyle(BrandPalette.textPrimary)

                Text("Your profile is ready. Confirm details and launch personalized fuel recommendations.")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(BrandPalette.textSecondary)
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
                    title: "Meals",
                    value: "\(mealsPerDay)",
                    subtitle: "Per Day"
                )
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
            prioritizeHighProtein: prioritizeHighProtein
        )

        let didSave = ProfileStore.saveProfile(profile, uid: uid)

        DispatchQueue.main.async {
            isLoading = false

            if didSave {
                appState.currentUserProfile = profile
                completionLocationManager.requestWhenInUseAuthorization()
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
