import Foundation

class CurrencyManager: ObservableObject {
    @Published var exchangeRate: Double = 1.0
    @Published var lastUpdate: Date?
    @Published var isLoading: Bool = false

    private let apiURL = "https://open.er-api.com/v6/latest/USD"
    private let cacheKey = "lastExchangeRate"
    private let cacheTimeKey = "lastExchangeRateUpdate"

    init() {
        loadCachedRate()
    }

    // Load cached rate from UserDefaults
    private func loadCachedRate() {
        if let cached = UserDefaults.standard.object(forKey: cacheKey) as? Double,
           let cacheTime = UserDefaults.standard.object(forKey: cacheTimeKey) as? Date {
            self.exchangeRate = cached
            self.lastUpdate = cacheTime
        }
    }

    // Save rate to cache
    private func saveToCache(rate: Double) {
        UserDefaults.standard.set(rate, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimeKey)
    }

    // Check if cache is still valid (less than 24 hours old)
    private func isCacheValid() -> Bool {
        guard let lastUpdate = lastUpdate else { return false }
        let hoursSinceUpdate = Date().timeIntervalSince(lastUpdate) / 3600
        return hoursSinceUpdate < 24
    }

    // Fetch exchange rate from API
    func fetchExchangeRate(completion: @escaping (Bool) -> Void = { _ in }) {
        // If cache is valid, don't fetch
        if isCacheValid() {
            completion(true)
            return
        }

        guard let url = URL(string: apiURL) else {
            completion(false)
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                guard let data = data, error == nil else {
                    print("Error fetching exchange rate: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let rates = json["rates"] as? [String: Double],
                       let eurRate = rates["EUR"] {
                        self?.exchangeRate = eurRate
                        self?.lastUpdate = Date()
                        self?.saveToCache(rate: eurRate)
                        completion(true)
                    } else {
                        print("Invalid JSON structure")
                        completion(false)
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }.resume()
    }

    // Convert USD to EUR
    func convertToEUR(_ usdAmount: Double) -> Double {
        return usdAmount * exchangeRate
    }

    // Get formatted amount based on language
    func formatAmount(_ amount: Double, language: LocalizationManager.Language) -> String {
        if language == .spanish {
            let eurAmount = convertToEUR(amount)
            return String(format: "€%.2f", eurAmount)
        } else {
            return String(format: "$%.2f", amount)
        }
    }
}
