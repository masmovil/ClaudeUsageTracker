//
//  LiteLLMManager.swift
//  Claude Usage Tracker
//
//  Copyright © 2025 Sergio Bañuls. All rights reserved.
//  Licensed under Personal Use License (Non-Commercial)
//

import Foundation

class LiteLLMManager: ObservableObject {
    @Published var apiKey: String = "" {
        didSet {
            saveAPIKey()
        }
    }
    @Published var isUsingAPI: Bool = false
    @Published var todaySpend: Double = 0.0
    @Published var budgetResetDate: Date? = nil
    @Published var totalKeySpend: Double = 0.0 // Total real desde /key/info

    private let apiBaseURL = "https://llm.tools.cloud.masorange.es"
    private let userDefaultsKey = "litellm_api_key"

    struct DailyActivity: Codable {
        let date: String
        let metrics: Metrics
        let breakdown: Breakdown?

        struct Metrics: Codable {
            let spend: Double
            let prompt_tokens: Int
            let completion_tokens: Int
            let cache_read_input_tokens: Int
            let cache_creation_input_tokens: Int
            let total_tokens: Int
            let successful_requests: Int
            let failed_requests: Int
        }
        
        struct Breakdown: Codable {
            let models: [String: ModelActivity]?
        }
        
        struct ModelActivity: Codable {
            let metrics: Metrics
        }
    }

    struct APIResponse: Codable {
        let results: [DailyActivity]
        let metadata: PaginationMetadata?
    }

    struct PaginationMetadata: Codable {
        let page: Int
        let total_pages: Int
        let has_more: Bool
        let total_spend: Double?
    }

    struct UserInfoResponse: Codable {
        let user_info: UserInfoData

        struct UserInfoData: Codable {
            let user_id: String
            let spend: Double
            let max_budget: Double?
            let budget_duration: String?
            let budget_reset_at: String?
        }
    }

    struct KeyInfoResponse: Codable {
        let info: KeyInfoData

        struct KeyInfoData: Codable {
            let spend: Double
            let max_budget: Double?
        }
    }

    init() {
        loadAPIKey()
    }

    private func saveAPIKey() {
        UserDefaults.standard.set(apiKey, forKey: userDefaultsKey)
    }

    private func loadAPIKey() {
        apiKey = UserDefaults.standard.string(forKey: userDefaultsKey) ?? ""
    }

    func hasValidAPIKey() -> Bool {
        return !apiKey.isEmpty && apiKey.hasPrefix("sk-")
    }

    func fetchUsageData() async throws -> (monthlyData: [(month: String, cost: Double, details: ClaudeUsageManager.TokenBreakdown)], modelData: [(model: String, cost: Double, details: ClaudeUsageManager.TokenBreakdown)]) {
        guard hasValidAPIKey() else {
            throw LiteLLMError.missingAPIKey
        }

        // Calculate date range - fetch last 12 months
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -12, to: endDate) ?? endDate

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)

        print("📅 [API] Fetching data from \(startDateString) to \(endDateString)")

        // Fetch all pages
        var allResults: [DailyActivity] = []
        var currentPage = 1
        var hasMore = true

        while hasMore {
            // Build URL with page parameter
            guard let url = URL(string: "\(apiBaseURL)/user/daily/activity?start_date=\(startDateString)&end_date=\(endDateString)&page=\(currentPage)") else {
                throw LiteLLMError.invalidURL
            }

            // Create request
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Perform request
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LiteLLMError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw LiteLLMError.apiError(statusCode: httpResponse.statusCode)
            }

            // Parse response
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(APIResponse.self, from: data)

            print("📄 [API] Page \(currentPage): \(apiResponse.results.count) days")

            allResults.append(contentsOf: apiResponse.results)

            // Check if there are more pages
            if let metadata = apiResponse.metadata {
                hasMore = metadata.has_more
                if hasMore {
                    currentPage += 1
                }
            } else {
                hasMore = false
            }
        }

        print("📊 [API] Total: \(allResults.count) days of data across \(currentPage) page(s)")
        if let firstDate = allResults.first?.date,
           let lastDate = allResults.last?.date {
            print("📊 [API] Date range: \(firstDate) to \(lastDate)")
        }

        // Group by month AND accumulate by model
        var monthlyDict: [String: ClaudeUsageManager.TokenBreakdown] = [:]
        var modelDict: [String: ClaudeUsageManager.TokenBreakdown] = [:]

        for dailyActivity in allResults {
            // 1. Process Monthly Data
            let monthKey = String(dailyActivity.date.prefix(7)) // Get yyyy-MM

            var monthBreakdown = monthlyDict[monthKey] ?? ClaudeUsageManager.TokenBreakdown()
            monthBreakdown.inputTokens += dailyActivity.metrics.prompt_tokens
            monthBreakdown.cacheCreationTokens += dailyActivity.metrics.cache_creation_input_tokens
            monthBreakdown.cacheReadTokens += dailyActivity.metrics.cache_read_input_tokens
            monthBreakdown.outputTokens += dailyActivity.metrics.completion_tokens
            monthBreakdown.accumulatedCost += dailyActivity.metrics.spend
            monthlyDict[monthKey] = monthBreakdown
            
            // 2. Process Model Data
            if let models = dailyActivity.breakdown?.models {
                for (modelName, activity) in models {
                    // Clean up model name (remove vertex_ai/ prefix etc if needed, but maybe keep full for clarity)
                    // Let's simplify only if it has prefixes like "vertex_ai/"
                    var cleanModelName = modelName
                    if cleanModelName.hasPrefix("vertex_ai/") {
                         cleanModelName = String(cleanModelName.dropFirst("vertex_ai/".count))
                    }
                    // Remove @date suffix if present
                    if let atIndex = cleanModelName.firstIndex(of: "@") {
                        cleanModelName = String(cleanModelName[..<atIndex])
                    }
                    
                    var modelBreakdown = modelDict[cleanModelName] ?? ClaudeUsageManager.TokenBreakdown()
                    modelBreakdown.inputTokens += activity.metrics.prompt_tokens
                    modelBreakdown.cacheCreationTokens += activity.metrics.cache_creation_input_tokens
                    modelBreakdown.cacheReadTokens += activity.metrics.cache_read_input_tokens
                    modelBreakdown.outputTokens += activity.metrics.completion_tokens
                    modelBreakdown.accumulatedCost += activity.metrics.spend
                    
                    // Since we have exact cost from API, we can set estimated costs to match
                    // This helps with the UI display which relies on estimated costs sometimes
                    modelBreakdown.estimatedInputCost = 0 // We don't know breakdown, but total is correct
                    
                    modelDict[cleanModelName] = modelBreakdown
                }
            }
        }

        // Process Monthly Data (Calculate estimates)
        let mappedMonthlyData: [(month: String, cost: Double, details: ClaudeUsageManager.TokenBreakdown)] = monthlyDict.map { (month, breakdown) in
            var finalBreakdown = breakdown

            // Calculate theoretical cost using standard pricing (as reference)
            let theoreticalInputCost = Double(breakdown.inputTokens) * 0.000003
            let theoreticalCacheCreationCost = Double(breakdown.cacheCreationTokens) * 0.00000375
            let theoreticalCacheReadCost = Double(breakdown.cacheReadTokens) * 0.0000003
            let theoreticalOutputCost = Double(breakdown.outputTokens) * 0.000015
            let theoreticalTotalCost = theoreticalInputCost + theoreticalCacheCreationCost + theoreticalCacheReadCost + theoreticalOutputCost

            // Calculate adjustment factor to match real API cost
            let adjustmentFactor = theoreticalTotalCost > 0 ? breakdown.accumulatedCost / theoreticalTotalCost : 1.0

            // Apply adjustment factor
            finalBreakdown.estimatedInputCost = theoreticalInputCost * adjustmentFactor
            finalBreakdown.estimatedCacheCreationCost = theoreticalCacheCreationCost * adjustmentFactor
            finalBreakdown.estimatedCacheReadCost = theoreticalCacheReadCost * adjustmentFactor
            finalBreakdown.estimatedOutputCost = theoreticalOutputCost * adjustmentFactor

            print("📊 [API] Month \(month): API Cost = $\(String(format: "%.2f", finalBreakdown.accumulatedCost)), Theoretical = $\(String(format: "%.2f", theoreticalTotalCost)), Factor = \(String(format: "%.4f", adjustmentFactor))")

            return (month: month, cost: finalBreakdown.accumulatedCost, details: finalBreakdown)
        }

        let monthlyData = mappedMonthlyData.sorted { $0.month > $1.month }

        // Log total API cost
        let totalAPICost = monthlyData.reduce(0.0) { $0 + $1.cost }
        print("💰 [API] Total Cost from API: $\(String(format: "%.2f", totalAPICost))")
        
        // Process Model Data (filter out models with 0 cost)
        let mappedModelData: [(model: String, cost: Double, details: ClaudeUsageManager.TokenBreakdown)] = modelDict.compactMap { (model, breakdown) in
            // Only include models with actual spend
            guard breakdown.accumulatedCost > 0 else { return nil }
            return (model: model, cost: breakdown.accumulatedCost, details: breakdown)
        }

        let modelData = mappedModelData.sorted { $0.cost > $1.cost }

        return (monthlyData, modelData)
    }

    func fetchKeyInfo() async throws -> Double {
        guard hasValidAPIKey() else {
            throw LiteLLMError.missingAPIKey
        }

        guard let url = URL(string: "\(apiBaseURL)/key/info") else {
            throw LiteLLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LiteLLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LiteLLMError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let keyInfoResponse = try decoder.decode(KeyInfoResponse.self, from: data)

        let spend = keyInfoResponse.info.spend
        print("🔑 [API] /key/info - Spend: $\(String(format: "%.2f", spend))")

        await MainActor.run {
            self.totalKeySpend = spend
        }

        return spend
    }

    func fetchUserInfo() async throws {
        guard hasValidAPIKey() else {
            throw LiteLLMError.missingAPIKey
        }

        // Fetch user info
        guard let url = URL(string: "\(apiBaseURL)/user/info") else {
            throw LiteLLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LiteLLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LiteLLMError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let userInfoResponse = try decoder.decode(UserInfoResponse.self, from: data)

        print("👤 [API] /user/info - Spend: $\(String(format: "%.2f", userInfoResponse.user_info.spend))")
        print("User info - budget_reset_at: \(userInfoResponse.user_info.budget_reset_at ?? "nil")")

        // Parse budget reset date
        if let resetDateString = userInfoResponse.user_info.budget_reset_at {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let resetDate = isoFormatter.date(from: resetDateString) {
                print("Parsed reset date: \(resetDate)")
                await MainActor.run {
                    self.budgetResetDate = resetDate
                    print("Budget reset date set to: \(self.budgetResetDate!)")
                }
            } else {
                print("Failed to parse reset date string: \(resetDateString)")
            }
        } else {
            print("No budget_reset_at in response")
        }
    }

    func fetchTodaySpend() async throws {
        guard hasValidAPIKey() else {
            throw LiteLLMError.missingAPIKey
        }

        // Get today's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        // Fetch today's activity
        guard let url = URL(string: "\(apiBaseURL)/user/daily/activity?start_date=\(todayString)&end_date=\(todayString)") else {
            throw LiteLLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LiteLLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LiteLLMError.apiError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(APIResponse.self, from: data)

        // Get today's spend
        let todaySpendValue = apiResponse.results.first?.metrics.spend ?? 0.0

        await MainActor.run {
            self.todaySpend = todaySpendValue
        }
    }

    enum LiteLLMError: LocalizedError {
        case missingAPIKey
        case invalidURL
        case invalidResponse
        case apiError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "API key is missing or invalid"
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid API response"
            case .apiError(let statusCode):
                return "API error with status code: \(statusCode)"
            }
        }
    }
}
