import Foundation
import Combine

class PricingManager: ObservableObject {
    @Published var standardContext: ContextPricing
    @Published var longContext: ContextPricing
    
    private let defaults = UserDefaults.standard
    
    struct ContextPricing: Codable {
        var inputTokens: Double
        var outputTokens: Double
        var cacheCreation: Double
        var cacheRead: Double
        
        static let standardDefault = ContextPricing(
            inputTokens: 3.00,
            outputTokens: 15.00,
            cacheCreation: 3.75,
            cacheRead: 0.30
        )
        
        static let longDefault = ContextPricing(
            inputTokens: 6.00,
            outputTokens: 22.50,
            cacheCreation: 7.50,
            cacheRead: 0.60
        )
    }
    
    init() {
        // Load saved pricing or use defaults
        if let standardData = defaults.data(forKey: "standardContextPricing"),
           let standard = try? JSONDecoder().decode(ContextPricing.self, from: standardData) {
            self.standardContext = standard
        } else {
            self.standardContext = .standardDefault
        }
        
        if let longData = defaults.data(forKey: "longContextPricing"),
           let long = try? JSONDecoder().decode(ContextPricing.self, from: longData) {
            self.longContext = long
        } else {
            self.longContext = .longDefault
        }
    }
    
    func save() {
        if let standardData = try? JSONEncoder().encode(standardContext) {
            defaults.set(standardData, forKey: "standardContextPricing")
        }
        if let longData = try? JSONEncoder().encode(longContext) {
            defaults.set(longData, forKey: "longContextPricing")
        }
    }
    
    func reset() {
        standardContext = .standardDefault
        longContext = .longDefault
        save()
    }
    
    func getPricing(contextSize: Int) -> ContextPricing {
        return contextSize > 200_000 ? longContext : standardContext
    }
    
    // Helper to convert to price per token (from price per million)
    func pricePerToken(_ pricePerMillion: Double) -> Double {
        return pricePerMillion / 1_000_000
    }
}
