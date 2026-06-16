//
//  CalorieCalculator.swift
//  FYTRR 2026
//
//  Created by EDWIN MENDOZA on 4/7/26.
//


import Foundation

struct CalorieCalculator {

    static func calculate(
        age: Int,
        sex: String,
        heightFeet: Int,
        heightInches: Int,
        weightLbs: Double,
        activityLevel: String,
        goal: String
    ) -> Int {

        let heightCm = Double((heightFeet * 12) + heightInches) * 2.54
        let weightKg = weightLbs * 0.453592

        // Revised Harris-Benedict BMR equations (1984)
        let bmr: Double
        if sex.lowercased() == "male" {
            bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * Double(age))
        }

        let multiplier: Double
        switch activityLevel {
        case "Low": multiplier = 1.2
        case "Moderate": multiplier = 1.55
        case "High": multiplier = 1.725
        default: multiplier = 1.2
        }

        var calories = bmr * multiplier

        switch goal {
        case "Lose Fat": calories -= 400
        case "Gain Muscle": calories += 250
        default: break
        }

        return Int(calories.rounded())
    }
}
