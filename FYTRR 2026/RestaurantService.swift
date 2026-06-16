//
//  RestaurantService.swift
//  FYTRR 2026
//
//  Created by EDWIN MENDOZA on 4/8/26.
//


import Foundation
import CoreLocation

final class RestaurantService {
    func fallbackNearby(lat: Double, lon: Double) -> [Restaurant] {
        Self.mockRestaurants(around: CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }

    func fetchNearby(
        lat: Double,
        lon: Double,
        radiusMiles: Double,
        limit: Int = 20
    ) async throws -> [Restaurant] {
        let fallbackResults = Self.mockRestaurants(around: CLLocationCoordinate2D(latitude: lat, longitude: lon))

        guard let apiKey = configuredAPIKey else {
            return fallbackResults
        }

        let radiusMeters = min(40_000, max(805, Int(radiusMiles * 1_609.34)))
        let cappedLimit = max(5, min(50, limit))

        var merged: [Restaurant] = []
        let minimumDesired = min(10, cappedLimit)

        if let healthyResults = try? await searchBusinessesWithRetry(
            lat: lat,
            lon: lon,
            radiusMeters: radiusMeters,
            limit: cappedLimit,
            apiKey: apiKey,
            categories: "healthmarkets,juicebars,salad,cafes,coffee,restaurants",
            term: "healthy protein"
        ) {
            mergeUnique(into: &merged, newItems: healthyResults)
        }

        if merged.count < minimumDesired,
           let additionalHealthy = try? await searchBusinessesWithRetry(
            lat: lat,
            lon: lon,
            radiusMeters: radiusMeters,
            limit: cappedLimit,
            apiKey: apiKey,
            categories: "restaurants,cafes,coffee",
            term: "high protein bowl salad"
           ) {
            mergeUnique(into: &merged, newItems: additionalHealthy)
        }

        if merged.count < minimumDesired,
           let broadResults = try? await searchBusinessesWithRetry(
            lat: lat,
            lon: lon,
            radiusMeters: radiusMeters,
            limit: cappedLimit,
            apiKey: apiKey,
            categories: nil,
            term: "restaurants cafes coffee"
           ) {
            mergeUnique(into: &merged, newItems: broadResults)
        }

        if merged.count < minimumDesired {
            let expandedRadius = min(40_000, radiusMeters * 2)
            if let expandedResults = try? await searchBusinessesWithRetry(
                lat: lat,
                lon: lon,
                radiusMeters: expandedRadius,
                limit: cappedLimit,
                apiKey: apiKey,
                categories: "restaurants,cafes,coffee",
                term: "healthy"
            ) {
                mergeUnique(into: &merged, newItems: expandedResults)
            }
        }

        guard !merged.isEmpty else { return fallbackResults }

        let ranked = Array(rankForFuelSelection(merged).prefix(cappedLimit))
        let enrichedTop = try? await enrichMenuLinks(
            for: Array(ranked.prefix(min(10, ranked.count))),
            apiKey: apiKey
        )

        guard let enrichedTop else { return ranked }
        let menuMap = Dictionary(uniqueKeysWithValues: enrichedTop.map { ($0.id, $0) })
        return ranked.map { menuMap[$0.id] ?? $0 }
    }

    private var configuredAPIKey: String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: "YELP_API_KEY") as? String else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, trimmed != "YOUR_YELP_API_KEY" else {
            return nil
        }

        return trimmed
    }
}

private extension RestaurantService {
    static let retryableErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .networkConnectionLost,
        .notConnectedToInternet,
        .cannotConnectToHost,
        .cannotFindHost
    ]

    func searchBusinessesWithRetry(
        lat: Double,
        lon: Double,
        radiusMeters: Int,
        limit: Int,
        apiKey: String,
        categories: String?,
        term: String?,
        retries: Int = 1
    ) async throws -> [Restaurant] {
        do {
            return try await searchBusinesses(
                lat: lat,
                lon: lon,
                radiusMeters: radiusMeters,
                limit: limit,
                apiKey: apiKey,
                categories: categories,
                term: term
            )
        } catch {
            guard
                retries > 0,
                let urlError = error as? URLError,
                Self.retryableErrorCodes.contains(urlError.code)
            else {
                throw error
            }

            return try await searchBusinessesWithRetry(
                lat: lat,
                lon: lon,
                radiusMeters: radiusMeters,
                limit: limit,
                apiKey: apiKey,
                categories: categories,
                term: term,
                retries: retries - 1
            )
        }
    }

    func searchBusinesses(
        lat: Double,
        lon: Double,
        radiusMeters: Int,
        limit: Int,
        apiKey: String,
        categories: String?,
        term: String?
    ) async throws -> [Restaurant] {
        var components = URLComponents(string: "https://api.yelp.com/v3/businesses/search")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "sort_by", value: "best_match"),
            URLQueryItem(name: "radius", value: String(radiusMeters)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let categories, categories.isEmpty == false {
            queryItems.append(URLQueryItem(name: "categories", value: categories))
        }
        if let term, term.isEmpty == false {
            queryItems.append(URLQueryItem(name: "term", value: term))
        }

        components?.queryItems = queryItems
        guard let url = components?.url else { throw RestaurantServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RestaurantServiceError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) == false {
            throw RestaurantServiceError.requestFailed(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(YelpResponse.self, from: data).businesses
    }

    func rankForFuelSelection(_ restaurants: [Restaurant]) -> [Restaurant] {
        restaurants.sorted { lhs, rhs in
            score(lhs) > score(rhs)
        }
    }

    func score(_ restaurant: Restaurant) -> Double {
        let distanceMiles = (restaurant.distance ?? 6_437.0) / 1_609.34
        let categoryText = restaurant.searchableCategoryText

        var categoryBoost = 0.0
        if categoryText.contains("coffee") || categoryText.contains("cafe") {
            categoryBoost += 1.2
        }
        if categoryText.contains("healthy")
            || categoryText.contains("salad")
            || categoryText.contains("juice")
            || categoryText.contains("protein") {
            categoryBoost += 1.8
        }

        let priceBoost: Double = {
            guard let price = restaurant.price else { return 0.4 }
            return max(0, 0.8 - (Double(price.count) * 0.15))
        }()

        return (restaurant.rating * 10.0) + categoryBoost + priceBoost - (distanceMiles * 0.7)
    }

    func mergeUnique(into existing: inout [Restaurant], newItems: [Restaurant]) {
        var seen = Set(existing.map(\.id))
        for restaurant in newItems where !seen.contains(restaurant.id) {
            existing.append(restaurant)
            seen.insert(restaurant.id)
        }
    }

    func enrichMenuLinks(for restaurants: [Restaurant], apiKey: String) async throws -> [Restaurant] {
        try await withThrowingTaskGroup(of: Restaurant?.self) { group in
            for restaurant in restaurants {
                group.addTask {
                    if restaurant.menuURL != nil { return restaurant }
                    return try await self.fetchBusinessDetailsAndMerge(base: restaurant, apiKey: apiKey)
                }
            }

            var merged: [Restaurant] = []
            for try await item in group {
                if let item {
                    merged.append(item)
                }
            }
            return merged
        }
    }

    func fetchBusinessDetailsAndMerge(base: Restaurant, apiKey: String) async throws -> Restaurant {
        var components = URLComponents(string: "https://api.yelp.com/v3/businesses/\(base.id)")
        components?.queryItems = [URLQueryItem(name: "locale", value: "en_US")]
        guard let url = components?.url else { return base }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return base }
        guard (200...299).contains(httpResponse.statusCode) else { return base }

        let details = try JSONDecoder().decode(YelpBusinessDetails.self, from: data)
        let menu = details.menuURL ?? details.attributes?.menuURL ?? base.menuURL
        let yelpURL = details.url ?? base.yelpURL

        return Restaurant(
            id: base.id,
            name: base.name,
            rating: base.rating,
            price: base.price,
            distance: base.distance,
            imageURL: base.imageURL,
            menuURL: menu,
            yelpURL: yelpURL,
            latitude: base.latitude,
            longitude: base.longitude,
            address: base.address,
            categories: base.categories
        )
    }
}

struct YelpResponse: Decodable {
    let businesses: [Restaurant]
}

private struct YelpBusinessDetails: Decodable {
    struct Attributes: Decodable {
        let menuURL: String?

        enum CodingKeys: String, CodingKey {
            case menuURL = "menu_url"
        }
    }

    let id: String
    let url: String?
    let menuURL: String?
    let attributes: Attributes?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case menuURL = "menu_url"
        case attributes
    }
}

enum RestaurantServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The restaurant search URL was invalid."
        case .invalidResponse:
            return "The restaurant service returned an invalid response."
        case .requestFailed(let statusCode):
            return "Restaurant search failed with status code \(statusCode)."
        }
    }
}

private extension RestaurantService {
    static func mockRestaurants(around coordinate: CLLocationCoordinate2D) -> [Restaurant] {
        let templates: [(id: String, name: String, rating: Double, price: String, categories: [String], latOffset: Double, lonOffset: Double)] = [
            ("mock-sweetgreen", "Sweetgreen", 4.7, "$$", ["Salads", "Healthy"], 0.0032, -0.0028),
            ("mock-cava", "CAVA", 4.6, "$$", ["Mediterranean", "Healthy"], -0.0044, 0.0031),
            ("mock-poke", "Power Poke Bowl", 4.5, "$$", ["Poke", "Seafood"], 0.0061, 0.0048),
            ("mock-grill", "Fit Grill House", 4.4, "$", ["Grilled Chicken", "American"], -0.0029, -0.0057)
        ]

        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return templates.map { template in
            let latitude = coordinate.latitude + template.latOffset
            let longitude = coordinate.longitude + template.lonOffset
            let point = CLLocation(latitude: latitude, longitude: longitude)
            let distance = origin.distance(from: point)

            return Restaurant(
                id: template.id,
                name: template.name,
                rating: template.rating,
                price: template.price,
                distance: distance,
                imageURL: nil,
                latitude: latitude,
                longitude: longitude,
                address: ["Near You", "Live area sample"],
                categories: template.categories
            )
        }
    }
}
