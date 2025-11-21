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

    private let apiBaseURL = "https://llm.tools.cloud.masorange.es"
    private let userDefaultsKey = "litellm_api_key"

    struct DailyActivity: Codable {
        let date: String
        let metrics: Metrics

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
    }

    struct APIResponse: Codable {
        let results: [DailyActivity]
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

    func fetchUsageData() async throws -> [(month: String, cost: Double, details: ClaudeUsageManager.TokenBreakdown)] {
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

        // Build URL
        guard let url = URL(string: "\(apiBaseURL)/user/daily/activity?start_date=\(startDateString)&end_date=\(endDateString)") else {
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

        // Group by month
        var monthlyDict: [String: ClaudeUsageManager.TokenBreakdown] = [:]

        for dailyActivity in apiResponse.results {
            // Extract month from date (format: yyyy-MM-dd)
            let monthKey = String(dailyActivity.date.prefix(7)) // Get yyyy-MM

            var monthBreakdown = monthlyDict[monthKey] ?? ClaudeUsageManager.TokenBreakdown()

            // Accumulate tokens
            monthBreakdown.inputTokens += dailyActivity.metrics.prompt_tokens
            monthBreakdown.cacheCreationTokens += dailyActivity.metrics.cache_creation_input_tokens
            monthBreakdown.cacheReadTokens += dailyActivity.metrics.cache_read_input_tokens
            monthBreakdown.outputTokens += dailyActivity.metrics.completion_tokens

            // Accumulate REAL cost from API (not calculated)
            monthBreakdown.accumulatedCost += dailyActivity.metrics.spend

            monthlyDict[monthKey] = monthBreakdown
        }

        // Calculate estimated individual costs proportionally for each month
        for (monthKey, var breakdown) in monthlyDict {
            // Calculate theoretical cost using standard pricing (as reference)
            let theoreticalInputCost = Double(breakdown.inputTokens) * 0.000003
            let theoreticalCacheCreationCost = Double(breakdown.cacheCreationTokens) * 0.00000375
            let theoreticalCacheReadCost = Double(breakdown.cacheReadTokens) * 0.0000003
            let theoreticalOutputCost = Double(breakdown.outputTokens) * 0.000015
            let theoreticalTotalCost = theoreticalInputCost + theoreticalCacheCreationCost + theoreticalCacheReadCost + theoreticalOutputCost

            // Calculate adjustment factor to match real API cost
            let adjustmentFactor = theoreticalTotalCost > 0 ? breakdown.accumulatedCost / theoreticalTotalCost : 1.0

            // Apply adjustment factor to get estimated costs that sum to real API cost
            breakdown.estimatedInputCost = theoreticalInputCost * adjustmentFactor
            breakdown.estimatedCacheCreationCost = theoreticalCacheCreationCost * adjustmentFactor
            breakdown.estimatedCacheReadCost = theoreticalCacheReadCost * adjustmentFactor
            breakdown.estimatedOutputCost = theoreticalOutputCost * adjustmentFactor

            monthlyDict[monthKey] = breakdown
        }

        // Convert to array and sort by month (newest first)
        let monthlyData = monthlyDict.map { (month, breakdown) in
            return (month: month, cost: breakdown.accumulatedCost, details: breakdown)
        }.sorted { $0.month > $1.month }

        return monthlyData
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
