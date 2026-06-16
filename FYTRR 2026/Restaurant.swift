//
//  Restaurant.swift
//  FYTRR 2026
//
//  Created by EDWIN MENDOZA on 4/8/26.
//


import Foundation
import CoreLocation

struct Restaurant: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let rating: Double
    let price: String?
    let distance: Double?
    let imageURL: String?
    let menuURL: String?
    let yelpURL: String?
    let latitude: Double?
    let longitude: Double?
    let address: [String]
    let categories: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rating
        case price
        case distance
        case imageURL = "image_url"
        case menuURL = "menu_url"
        case yelpURL = "url"
        case coordinates
        case location
        case categories
    }

    init(
        id: String,
        name: String,
        rating: Double,
        price: String? = nil,
        distance: Double? = nil,
        imageURL: String? = nil,
        menuURL: String? = nil,
        yelpURL: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: [String] = [],
        categories: [String] = []
    ) {
        self.id = id
        self.name = name
        self.rating = rating
        self.price = price
        self.distance = distance
        self.imageURL = imageURL
        self.menuURL = menuURL
        self.yelpURL = yelpURL
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.categories = categories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        price = try container.decodeIfPresent(String.self, forKey: .price)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        menuURL = try container.decodeIfPresent(String.self, forKey: .menuURL)
        yelpURL = try container.decodeIfPresent(String.self, forKey: .yelpURL)

        let coordinates = try container.decodeIfPresent(Coordinates.self, forKey: .coordinates)
        latitude = coordinates?.latitude
        longitude = coordinates?.longitude

        let location = try container.decodeIfPresent(Location.self, forKey: .location)
        address = location?.displayAddress ?? []

        let categoryItems = try container.decodeIfPresent([Category].self, forKey: .categories) ?? []
        categories = categoryItems.map(\.title)
    }

    var formattedDistance: String? {
        guard let distance else { return nil }

        let miles = distance / 1609.34
        return String(format: "%.1f mi away", miles)
    }

    var formattedAddress: String? {
        let filtered = address.filter { $0.isEmpty == false }
        return filtered.isEmpty ? nil : filtered.joined(separator: ", ")
    }

    var formattedCategories: String {
        let filtered = categories.filter { $0.isEmpty == false }
        return filtered.isEmpty ? "Restaurant" : filtered.joined(separator: " • ")
    }

    var searchableCategoryText: String {
        categories.joined(separator: " ").lowercased()
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var bestMenuURL: URL? {
        if let menuURL, let url = URL(string: menuURL) {
            return url
        }
        if let yelpURL, let url = URL(string: yelpURL) {
            return url
        }
        return nil
    }
}

private extension Restaurant {
    struct Coordinates: Decodable {
        let latitude: Double?
        let longitude: Double?
    }

    struct Location: Decodable {
        let displayAddress: [String]

        enum CodingKeys: String, CodingKey {
            case displayAddress = "display_address"
        }
    }

    struct Category: Decodable {
        let title: String
    }
}
