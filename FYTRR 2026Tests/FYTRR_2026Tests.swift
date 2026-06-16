//
//  FYTRR_2026Tests.swift
//  FYTRR 2026Tests
//
//  Created by EDWIN MENDOZA on 4/7/26.
//

import Testing
@testable import FYTRR_2026

struct FYTRR_2026Tests {

    @Test func calorieCalculatorSupportsFatLoss() async throws {
        let calories = CalorieCalculator.calculate(
            age: 28,
            sex: "Male",
            heightFeet: 5,
            heightInches: 10,
            weightLbs: 185,
            activityLevel: "Moderate",
            goal: "Lose Fat"
        )

        #expect(calories == 2556)
    }

    @Test func recommendationEnginePrioritizesHealthyCloserOptions() async throws {
        let profile = UserProfile(
            name: "Edwin",
            age: 28,
            sex: "Male",
            heightFeet: 5,
            heightInches: 10,
            weightLbs: 185,
            goal: "Lose Fat",
            activityLevel: "Moderate",
            dailyCalories: 2414
        )

        let restaurants = [
            Restaurant(
                id: "burger",
                name: "Burger Town",
                rating: 4.8,
                price: "$$",
                distance: 1400,
                imageURL: nil,
                address: ["1 Main St"],
                categories: ["Burgers"]
            ),
            Restaurant(
                id: "salad",
                name: "Lean Greens",
                rating: 4.5,
                price: "$$",
                distance: 450,
                imageURL: nil,
                address: ["2 Main St"],
                categories: ["Salads", "Healthy"]
            )
        ]

        let ranked = RecommendationEngine().rank(restaurants: restaurants, for: profile)

        #expect(ranked.first?.restaurant.id == "salad")
        #expect((ranked.first?.score ?? 0) > (ranked.last?.score ?? 0))
    }

}
