import Foundation

struct AIFuelCoachService {
    struct ChatTurn {
        let isUser: Bool
        let text: String
    }

    enum CoachError: LocalizedError {
        case missingAPIKey
        case apiError(String)
        case invalidResponse
        case emptyReply

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Add OPENAI_API_KEY in the target Info settings to enable live AI."
            case let .apiError(message):
                return message
            case .invalidResponse:
                return "AI service returned a response FYTRR could not read."
            case .emptyReply:
                return "AI service returned an empty reply."
            }
        }
    }

    private var apiKey: String? {
        guard let raw = configValue(for: "OPENAI_API_KEY") else {
            return nil
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty || key == "YOUR_OPENAI_API_KEY" {
            return nil
        }
        return key
    }

    private var model: String {
        let raw = configValue(for: "OPENAI_MODEL")?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (raw?.isEmpty == false ? raw : nil) ?? "gpt-4o-mini"
    }

    var isConfigured: Bool {
        apiKey != nil
    }

    var configurationMessage: String {
        isConfigured ? "Live AI ready." : "Add OPENAI_API_KEY in Info settings for live AI. Smart Coach is active offline."
    }

    private func configValue(for key: String) -> String? {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            return value
        }

        guard
            let resourcePath = Bundle.main.path(forResource: "FYTRR-2026-Info", ofType: "plist"),
            let resourceInfo = NSDictionary(contentsOfFile: resourcePath) as? [String: Any],
            let value = resourceInfo[key] as? String
        else {
            return nil
        }

        return value
    }

    func reply(
        prompt: String,
        conversation: [ChatTurn] = [],
        profile: UserProfile?,
        nearbyRecommendations: [RestaurantRecommendation],
        mealTargetCalories: Int?
    ) async throws -> String {
        guard let apiKey else {
            throw CoachError.missingAPIKey
        }

        let context = buildContext(
            profile: profile,
            nearbyRecommendations: nearbyRecommendations,
            mealTargetCalories: mealTargetCalories
        )

        let recentConversation = conversation.suffix(10).map {
            OpenAIResponsesRequest.InputMessage(
                role: $0.isUser ? "user" : "assistant",
                content: [.init(type: "input_text", text: $0.text)]
            )
        }

        let requestBody = OpenAIResponsesRequest(
            model: model,
            instructions: systemPrompt + "\n\n" + context,
            input: recentConversation + [
                .init(role: "user", content: [.init(type: "input_text", text: prompt)])
            ],
            temperature: 0.55,
            maxOutputTokens: 260
        )

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder.openAIEncoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw CoachError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw CoachError.apiError(apiError.error.message)
            }
            let raw = String(data: data, encoding: .utf8) ?? "status \(http.statusCode)"
            throw CoachError.apiError("AI request failed: \(raw)")
        }

        let decoded = try JSONDecoder().decode(OpenAIResponsesResponse.self, from: data)
        guard let rawReply = decoded.replyText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            throw CoachError.emptyReply
        }

        return rawReply
    }

    private var systemPrompt: String {
        """
        You are FYTRR Coach, a premium performance nutrition assistant.
        Give decisive, practical meal guidance based on the user's profile, calorie target, protein target, recent chat, and nearby restaurant context.
        Use restaurant names from context when available. If no restaurants are available, still help with a useful nutrition plan and tell the user how to refresh nearby fuel.
        Keep responses concise: 3 to 6 short bullets or under 120 words.
        Do not invent exact menu nutrition. Use estimates and say when something is an estimate.
        For medical conditions, eating disorders, allergies, pregnancy, or clinical advice, add a brief safety note and suggest a qualified professional.
        """
    }

    private func buildContext(
        profile: UserProfile?,
        nearbyRecommendations: [RestaurantRecommendation],
        mealTargetCalories: Int?
    ) -> String {
        let top = nearbyRecommendations.prefix(10)
        let restaurants = top.map { recommendation in
            let restaurant = recommendation.restaurant
            let distance = restaurant.formattedDistance ?? "distance n/a"
            let price = restaurant.price ?? "price n/a"
            let rating = String(format: "%.1f", restaurant.rating)
            let address = restaurant.formattedAddress ?? "address n/a"
            return "- \(restaurant.name) | score \(recommendation.score) | rating \(rating) | \(price) | \(distance) | \(restaurant.formattedCategories) | \(address) | FYTRR reason: \(recommendation.reason)"
        }.joined(separator: "\n")

        let profileLine: String = {
            guard let profile else { return "Profile: unavailable." }
            let proteinTarget = Int((profile.weightLbs * profile.proteinTargetMultiplier).rounded())
            return "Profile: name=\(profile.name), goal=\(profile.goal), activity=\(profile.activityLevel), age=\(profile.age), weight=\(Int(profile.weightLbs))lb, dailyCalories=\(profile.dailyCalories), mealsPerDay=\(profile.mealsPerDay), proteinTarget=\(proteinTarget)g, highProtein=\(profile.prioritizeHighProtein), maxPrice=\(String(repeating: "$", count: profile.maxPriceTier))"
        }()

        let mealTargetLine = "Meal target calories: \(mealTargetCalories?.description ?? "unknown")"
        let restaurantLine = restaurants.isEmpty
            ? "Nearby recommendations: none loaded. Tell the user they can open Map or refresh local fuel, but still provide general coaching from profile."
            : "Nearby recommendations:\n\(restaurants)"

        return """
        \(profileLine)
        \(mealTargetLine)
        \(restaurantLine)
        """
    }
}

private struct OpenAIResponsesRequest: Encodable {
    struct InputMessage: Encodable {
        let role: String
        let content: [InputContent]
    }

    struct InputContent: Encodable {
        let type: String
        let text: String
    }

    let model: String
    let instructions: String
    let input: [InputMessage]
    let temperature: Double
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case instructions
        case input
        case temperature
        case maxOutputTokens = "max_output_tokens"
    }
}

private struct OpenAIResponsesResponse: Decodable {
    struct OutputItem: Decodable {
        struct ContentItem: Decodable {
            let type: String?
            let text: String?
        }

        let type: String?
        let content: [ContentItem]?
    }

    let outputText: String?
    let output: [OutputItem]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }

    var replyText: String {
        if let outputText, !outputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return outputText
        }

        return output?
            .flatMap { $0.content ?? [] }
            .compactMap { $0.text }
            .joined(separator: "\n") ?? ""
    }
}

private struct OpenAIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
        let type: String?
        let code: String?
    }

    let error: APIError
}

private extension JSONEncoder {
    static var openAIEncoder: JSONEncoder {
        JSONEncoder()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
