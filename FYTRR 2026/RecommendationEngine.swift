import Foundation

struct RestaurantRecommendation: Identifiable, Equatable {
    let restaurant: Restaurant
    let score: Int
    let reason: String

    var id: String { restaurant.id }
}

struct RecommendationEngine {

    func rank(restaurants: [Restaurant], for profile: UserProfile) -> [RestaurantRecommendation] {
        restaurants
            .filter { restaurant in
                guard let tier = priceTier(for: restaurant.price) else { return true }
                return tier <= profile.maxPriceTier
            }
            .map { restaurant in
                RestaurantRecommendation(
                    restaurant: restaurant,
                    score: score(for: restaurant, profile: profile),
                    reason: reason(for: restaurant, profile: profile)
                )
            }
            .sorted {
                if $0.score == $1.score {
                    return ($0.restaurant.distance ?? .greatestFiniteMagnitude) < ($1.restaurant.distance ?? .greatestFiniteMagnitude)
                }

                return $0.score > $1.score
            }
    }

    private func score(for restaurant: Restaurant, profile: UserProfile) -> Int {
        let categoryScore = categoryScore(for: restaurant, goal: profile.goal)
        let ratingScore = Int((restaurant.rating / 5.0) * 35.0)
        let distanceScore = distanceScore(for: restaurant.distance)
        let priceScore = priceScore(for: restaurant.price)
        let proteinBonus = proteinPreferenceBonus(for: restaurant, prioritizeHighProtein: profile.prioritizeHighProtein)

        return max(0, min(100, categoryScore + ratingScore + distanceScore + priceScore + proteinBonus))
    }

    private func reason(for restaurant: Restaurant, profile: UserProfile) -> String {
        var parts: [String] = []

        if let primaryCategory = restaurant.categories.first, primaryCategory.isEmpty == false {
            parts.append(primaryCategory)
        }

        if let distance = restaurant.formattedDistance {
            parts.append(distance)
        }

        if let price = restaurant.price, price.isEmpty == false {
            parts.append(price)
        }

        if profile.prioritizeHighProtein, isLikelyHighProtein(restaurant) {
            parts.append("high-protein friendly")
        }

        let goalHint: String
        switch profile.goal {
        case "Lose Fat":
            goalHint = "lighter-leaning options"
        case "Gain Muscle":
            goalHint = "protein-friendly options"
        default:
            goalHint = "balanced choices"
        }

        let joinedParts = parts.joined(separator: " • ")
        if joinedParts.isEmpty {
            return "Strong match for \(goalHint)."
        }

        return "\(joinedParts) • Good for \(goalHint)."
    }

    private func categoryScore(for restaurant: Restaurant, goal: String) -> Int {
        let text = restaurant.searchableCategoryText

        switch goal {
        case "Lose Fat":
            if matchesAny(text, keywords: ["salad", "healthy", "juice", "vegan", "vegetarian", "poke", "wrap"]) {
                return 30
            }
        case "Gain Muscle":
            if matchesAny(text, keywords: ["grill", "protein", "chicken", "mediterranean", "poke", "steak", "thai"]) {
                return 30
            }
        default:
            if matchesAny(text, keywords: ["healthy", "mediterranean", "poke", "sandwich", "mexican", "american"]) {
                return 26
            }
        }

        if matchesAny(text, keywords: ["healthy", "food"]) {
            return 20
        }

        return 12
    }

    private func distanceScore(for distanceMeters: Double?) -> Int {
        guard let distanceMeters else { return 10 }

        let miles = distanceMeters / 1609.34

        switch miles {
        case ..<0.5: return 20
        case ..<1.0: return 16
        case ..<2.0: return 12
        default: return 8
        }
    }

    private func priceScore(for price: String?) -> Int {
        switch price {
        case "$": return 15
        case "$$": return 12
        case "$$$": return 8
        case "$$$$": return 5
        default: return 10
        }
    }

    private func proteinPreferenceBonus(for restaurant: Restaurant, prioritizeHighProtein: Bool) -> Int {
        guard prioritizeHighProtein else { return 0 }
        return isLikelyHighProtein(restaurant) ? 7 : 0
    }

    private func isLikelyHighProtein(_ restaurant: Restaurant) -> Bool {
        let text = restaurant.searchableCategoryText
        return matchesAny(text, keywords: ["protein", "grill", "chicken", "steak", "bbq", "poke"])
    }

    private func priceTier(for price: String?) -> Int? {
        guard let price, price.isEmpty == false else { return nil }
        return price.count
    }

    private func matchesAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
