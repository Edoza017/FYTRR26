import Foundation

struct MealOrderEntry: Codable, Identifiable {
    let id: String
    let restaurantName: String
    let provider: String
    let orderedAt: Date
}

struct ProfileStore {
    private static func profileKey(for uid: String) -> String {
        "fytrr.profile.\(uid)"
    }

    private static func photoKey(for uid: String) -> String {
        "fytrr.profile.photo.\(uid)"
    }

    private static func mealHistoryKey(for uid: String) -> String {
        "fytrr.profile.meals.\(uid)"
    }

    static func loadProfile(uid: String) -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey(for: uid)) else {
            return nil
        }

        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    @discardableResult
    static func saveProfile(_ profile: UserProfile, uid: String) -> Bool {
        guard let data = try? JSONEncoder().encode(profile) else {
            return false
        }

        UserDefaults.standard.set(data, forKey: profileKey(for: uid))
        return true
    }

    static func deleteProfile(uid: String) {
        UserDefaults.standard.removeObject(forKey: profileKey(for: uid))
    }

    static func loadProfilePhotoData(uid: String) -> Data? {
        UserDefaults.standard.data(forKey: photoKey(for: uid))
    }

    static func saveProfilePhotoData(_ data: Data, uid: String) {
        UserDefaults.standard.set(data, forKey: photoKey(for: uid))
    }

    static func loadMealHistory(uid: String) -> [MealOrderEntry] {
        guard let data = UserDefaults.standard.data(forKey: mealHistoryKey(for: uid)),
              let entries = try? JSONDecoder().decode([MealOrderEntry].self, from: data) else {
            return []
        }

        return entries.sorted { $0.orderedAt > $1.orderedAt }
    }

    static func addMealOrder(_ entry: MealOrderEntry, uid: String) {
        var entries = loadMealHistory(uid: uid)
        entries.insert(entry, at: 0)
        entries = Array(entries.prefix(30))

        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: mealHistoryKey(for: uid))
        }
    }
}
