//
//  UserProfile.swift
//  FYTRR 2026
//
//  Created by EDWIN MENDOZA on 4/7/26.
//


import Foundation

struct UserProfile: Codable, Equatable {
    var name: String
    var age: Int
    var sex: String
    var heightFeet: Int
    var heightInches: Int
    var weightLbs: Double
    var goal: String
    var activityLevel: String
    var dailyCalories: Int
    var mealsPerDay: Int
    var maxPriceTier: Int
    var prioritizeHighProtein: Bool
    var proteinTargetMultiplier: Double

    var heightDescription: String {
        "\(heightFeet)'\(heightInches)\""
    }

    var mealCalorieTarget: Int {
        let mealCount = max(1, mealsPerDay)
        return max(250, Int((Double(dailyCalories) / Double(mealCount)).rounded()))
    }

    var goalSummary: String {
        "\(goal) with a \(activityLevel.lowercased()) routine"
    }

    init(
        name: String,
        age: Int,
        sex: String,
        heightFeet: Int,
        heightInches: Int,
        weightLbs: Double,
        goal: String,
        activityLevel: String,
        dailyCalories: Int,
        mealsPerDay: Int = 3,
        maxPriceTier: Int = 4,
        prioritizeHighProtein: Bool = true,
        proteinTargetMultiplier: Double = 0.8
    ) {
        self.name = name
        self.age = age
        self.sex = sex
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.weightLbs = weightLbs
        self.goal = goal
        self.activityLevel = activityLevel
        self.dailyCalories = dailyCalories
        self.mealsPerDay = min(6, max(1, mealsPerDay))
        self.maxPriceTier = min(4, max(1, maxPriceTier))
        self.prioritizeHighProtein = prioritizeHighProtein
        self.proteinTargetMultiplier = min(1.0, max(0.7, proteinTargetMultiplier))
    }

    init?(firestoreData: [String: Any]) {
        guard
            let name = firestoreData["name"] as? String,
            let age = firestoreData["age"] as? Int,
            let sex = firestoreData["sex"] as? String,
            let heightFeet = firestoreData["heightFeet"] as? Int,
            let heightInches = firestoreData["heightInches"] as? Int,
            let goal = firestoreData["goal"] as? String,
            let activityLevel = firestoreData["activityLevel"] as? String,
            let dailyCalories = firestoreData["dailyCalories"] as? Int
        else {
            return nil
        }

        let weightValue = firestoreData["weightLbs"] ?? firestoreData["weight"]

        let weightLbs: Double
        switch weightValue {
        case let value as Double:
            weightLbs = value
        case let value as Int:
            weightLbs = Double(value)
        default:
            return nil
        }

        let mealsValue = firestoreData["mealsPerDay"]
        let mealsPerDay: Int
        switch mealsValue {
        case let value as Int:
            mealsPerDay = value
        case let value as Double:
            mealsPerDay = Int(value)
        default:
            mealsPerDay = 3
        }

        let maxPriceValue = firestoreData["maxPriceTier"]
        let maxPriceTier: Int
        switch maxPriceValue {
        case let value as Int:
            maxPriceTier = value
        case let value as Double:
            maxPriceTier = Int(value)
        default:
            maxPriceTier = 4
        }

        let prioritizeHighProtein = firestoreData["prioritizeHighProtein"] as? Bool ?? true

        let proteinTargetMultiplier: Double
        switch firestoreData["proteinTargetMultiplier"] {
        case let value as Double:
            proteinTargetMultiplier = value
        case let value as Int:
            proteinTargetMultiplier = Double(value)
        default:
            proteinTargetMultiplier = 0.8
        }

        self.init(
            name: name,
            age: age,
            sex: sex,
            heightFeet: heightFeet,
            heightInches: heightInches,
            weightLbs: weightLbs,
            goal: goal,
            activityLevel: activityLevel,
            dailyCalories: dailyCalories,
            mealsPerDay: mealsPerDay,
            maxPriceTier: maxPriceTier,
            prioritizeHighProtein: prioritizeHighProtein,
            proteinTargetMultiplier: proteinTargetMultiplier
        )
    }

    var firestoreData: [String: Any] {
        [
            "name": name,
            "age": age,
            "sex": sex,
            "heightFeet": heightFeet,
            "heightInches": heightInches,
            "weightLbs": weightLbs,
            "goal": goal,
            "activityLevel": activityLevel,
            "dailyCalories": dailyCalories,
            "mealsPerDay": mealsPerDay,
            "maxPriceTier": maxPriceTier,
            "prioritizeHighProtein": prioritizeHighProtein,
            "proteinTargetMultiplier": proteinTargetMultiplier
        ]
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case age
        case sex
        case heightFeet
        case heightInches
        case weightLbs
        case goal
        case activityLevel
        case dailyCalories
        case mealsPerDay
        case maxPriceTier
        case prioritizeHighProtein
        case proteinTargetMultiplier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let age = try container.decode(Int.self, forKey: .age)
        let sex = try container.decode(String.self, forKey: .sex)
        let heightFeet = try container.decode(Int.self, forKey: .heightFeet)
        let heightInches = try container.decode(Int.self, forKey: .heightInches)
        let weightLbs = try container.decode(Double.self, forKey: .weightLbs)
        let goal = try container.decode(String.self, forKey: .goal)
        let activityLevel = try container.decode(String.self, forKey: .activityLevel)
        let dailyCalories = try container.decode(Int.self, forKey: .dailyCalories)
        let mealsPerDay = try container.decodeIfPresent(Int.self, forKey: .mealsPerDay) ?? 3
        let maxPriceTier = try container.decodeIfPresent(Int.self, forKey: .maxPriceTier) ?? 4
        let prioritizeHighProtein = try container.decodeIfPresent(Bool.self, forKey: .prioritizeHighProtein) ?? true
        let proteinTargetMultiplier = try container.decodeIfPresent(Double.self, forKey: .proteinTargetMultiplier) ?? 0.8

        self.init(
            name: name,
            age: age,
            sex: sex,
            heightFeet: heightFeet,
            heightInches: heightInches,
            weightLbs: weightLbs,
            goal: goal,
            activityLevel: activityLevel,
            dailyCalories: dailyCalories,
            mealsPerDay: mealsPerDay,
            maxPriceTier: maxPriceTier,
            prioritizeHighProtein: prioritizeHighProtein,
            proteinTargetMultiplier: proteinTargetMultiplier
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(sex, forKey: .sex)
        try container.encode(heightFeet, forKey: .heightFeet)
        try container.encode(heightInches, forKey: .heightInches)
        try container.encode(weightLbs, forKey: .weightLbs)
        try container.encode(goal, forKey: .goal)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encode(dailyCalories, forKey: .dailyCalories)
        try container.encode(mealsPerDay, forKey: .mealsPerDay)
        try container.encode(maxPriceTier, forKey: .maxPriceTier)
        try container.encode(prioritizeHighProtein, forKey: .prioritizeHighProtein)
        try container.encode(proteinTargetMultiplier, forKey: .proteinTargetMultiplier)
    }
}
