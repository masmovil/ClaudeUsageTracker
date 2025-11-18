import Foundation

class ClaudeUsageManager: ObservableObject {
    @Published var monthlyData: [(month: String, cost: Double, details: TokenBreakdown)] = []
    @Published var projectData: [(project: String, cost: Double, details: TokenBreakdown)] = []
    @Published var currentMonthCost: Double = 0.0
    @Published var totalCost: Double = 0.0
    @Published var lastUpdate: Date = Date()
    @Published var isLoading: Bool = false

    var onDataUpdated: (() -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var pricingManager: PricingManager?
    var localizationManager: LocalizationManager?
    
    struct TokenBreakdown {
        var inputTokens: Int = 0
        var cacheCreationTokens: Int = 0
        var cacheReadTokens: Int = 0
        var outputTokens: Int = 0
        var maxContextSize: Int = 0 // Maximum context size of any single message (for reference only)
        var accumulatedCost: Double = 0.0 // Cost calculated message by message with correct pricing tier
    }
    
    // Process a turn (group of consecutive assistant messages) and count it as ONE billable event
    private func processTurn(_ turnMessages: [(timestamp: String?, monthKey: String?, input: Int, cacheCreation: Int, cacheRead: Int, output: Int, contextSize: Int)],
                             monthlyDict: inout [String: TokenBreakdown],
                             projectBreakdown: inout TokenBreakdown) {

        // Take only the LAST message of the turn (contains final response)
        guard let lastMessage = turnMessages.last else { return }

        let input = lastMessage.input
        let cacheCreation = lastMessage.cacheCreation
        let cacheRead = lastMessage.cacheRead
        let output = lastMessage.output
        let contextSize = lastMessage.contextSize

        // Calculate cost for this turn
        let turnCost = calculateMessageCost(
            input: input,
            cacheCreation: cacheCreation,
            cacheRead: cacheRead,
            output: output,
            contextSize: contextSize
        )

        // Update monthly data
        if let monthKey = lastMessage.monthKey {
            var monthBreakdown = monthlyDict[monthKey] ?? TokenBreakdown()
            monthBreakdown.inputTokens += input
            monthBreakdown.cacheCreationTokens += cacheCreation
            monthBreakdown.cacheReadTokens += cacheRead
            monthBreakdown.outputTokens += output
            monthBreakdown.maxContextSize = max(monthBreakdown.maxContextSize, contextSize)
            monthBreakdown.accumulatedCost += turnCost
            monthlyDict[monthKey] = monthBreakdown
        }

        // Update project data
        projectBreakdown.inputTokens += input
        projectBreakdown.cacheCreationTokens += cacheCreation
        projectBreakdown.cacheReadTokens += cacheRead
        projectBreakdown.outputTokens += output
        projectBreakdown.maxContextSize = max(projectBreakdown.maxContextSize, contextSize)
        projectBreakdown.accumulatedCost += turnCost
    }

    func loadData() {
        // Notificar que está cargando
        isLoading = true
        onLoadingStateChanged?(true)

        let claudeProjectsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
        
        var monthlyDict: [String: TokenBreakdown] = [:]
        var projectDict: [String: TokenBreakdown] = [:]
        
        guard let projects = try? FileManager.default.contentsOfDirectory(atPath: claudeProjectsPath.path) else {
            return
        }
        
        for project in projects {
            let projectPath = claudeProjectsPath.appendingPathComponent(project)
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: projectPath.path) else {
                continue
            }
            
            var projectBreakdown = TokenBreakdown()
            
            for file in files where file.hasSuffix(".jsonl") {
                let filePath = projectPath.appendingPathComponent(file)
                guard let content = try? String(contentsOf: filePath) else { continue }

                let lines = content.components(separatedBy: .newlines)

                // Track consecutive assistant messages (same turn)
                var currentTurnMessages: [(timestamp: String?, monthKey: String?, input: Int, cacheCreation: Int, cacheRead: Int, output: Int, contextSize: Int)] = []
                var lastTimestamp: Date?

                for line in lines where !line.isEmpty {
                    guard let data = line.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let message = json["message"] as? [String: Any] else {
                        continue
                    }

                    let role = message["role"] as? String
                    let usage = message["usage"] as? [String: Any]

                    // If no usage data, this message ends the current turn
                    guard let usage = usage else {
                        // Process accumulated turn messages
                        if !currentTurnMessages.isEmpty {
                            processTurn(currentTurnMessages, monthlyDict: &monthlyDict, projectBreakdown: &projectBreakdown)
                            currentTurnMessages.removeAll()
                        }
                        lastTimestamp = nil
                        continue
                    }

                    let input = usage["input_tokens"] as? Int ?? 0
                    let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0
                    let output = usage["output_tokens"] as? Int ?? 0

                    // Cache creation - intentar ambos formatos (viejo y nuevo)
                    var cacheCreation = usage["cache_creation_input_tokens"] as? Int ?? 0
                    if cacheCreation == 0, let cacheCreationDict = usage["cache_creation"] as? [String: Any] {
                        cacheCreation = cacheCreationDict["ephemeral_5m_input_tokens"] as? Int ?? 0
                        cacheCreation += cacheCreationDict["ephemeral_1h_input_tokens"] as? Int ?? 0
                    }

                    let contextSize = input + cacheCreation + cacheRead
                    let timestamp = json["timestamp"] as? String
                    let monthKey = timestamp.map { String($0.prefix(7)) }

                    // Check if this is part of the same turn (assistant role, within 10 seconds)
                    var isNewTurn = false
                    if let timestamp = timestamp {
                        // Configure formatter to handle fractional seconds
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                        if let currentDate = formatter.date(from: timestamp) {
                            if let lastDate = lastTimestamp {
                                let timeDiff = currentDate.timeIntervalSince(lastDate)
                                // If more than 10 seconds apart or role is not assistant, start new turn
                                if timeDiff > 10 || role != "assistant" {
                                    isNewTurn = true
                                }
                            }

                            lastTimestamp = currentDate
                        } else {
                            isNewTurn = true
                        }
                    } else {
                        isNewTurn = true
                    }

                    // If new turn starts, process the previous turn
                    if isNewTurn && !currentTurnMessages.isEmpty {
                        processTurn(currentTurnMessages, monthlyDict: &monthlyDict, projectBreakdown: &projectBreakdown)
                        currentTurnMessages.removeAll()
                    }

                    // Add current message to the turn
                    currentTurnMessages.append((
                        timestamp: timestamp,
                        monthKey: monthKey,
                        input: input,
                        cacheCreation: cacheCreation,
                        cacheRead: cacheRead,
                        output: output,
                        contextSize: contextSize
                    ))
                }

                // Process any remaining turn messages at the end of file
                if !currentTurnMessages.isEmpty {
                    processTurn(currentTurnMessages, monthlyDict: &monthlyDict, projectBreakdown: &projectBreakdown)
                }
            }
            
            if projectBreakdown.inputTokens > 0 || projectBreakdown.cacheCreationTokens > 0 ||
               projectBreakdown.cacheReadTokens > 0 || projectBreakdown.outputTokens > 0 {
                projectDict[project] = projectBreakdown
            }
        }
        
        // Convert to arrays and calculate costs
        DispatchQueue.main.async {
            self.monthlyData = monthlyDict.map { (month, breakdown) in
                let cost = self.calculateCost(breakdown)
                return (month: month, cost: cost, details: breakdown)
            }.sorted { $0.month > $1.month }
            
            self.projectData = projectDict.map { (project, breakdown) in
                let cost = self.calculateCost(breakdown)
                let simplifiedName = self.simplifyProjectName(project)
                return (project: simplifiedName, cost: cost, details: breakdown)
            }.sorted { $0.cost > $1.cost }
            
            // Calculate current month cost
            let currentMonth = self.getCurrentMonthKey()
            self.currentMonthCost = self.monthlyData.first(where: { $0.month == currentMonth })?.cost ?? 0.0
            
            // Calculate total
            self.totalCost = self.monthlyData.reduce(0) { $0 + $1.cost }
            
            self.lastUpdate = Date()

            // Finalizar carga
            self.isLoading = false

            // Notificar que los datos se actualizaron
            self.onDataUpdated?()
        }
    }
    
    private func calculateCost(_ breakdown: TokenBreakdown) -> Double {
        // Return the accumulated cost that was calculated message by message
        return breakdown.accumulatedCost
    }

    // Calculate cost for a single message based on its context size
    private func calculateMessageCost(input: Int, cacheCreation: Int, cacheRead: Int, output: Int, contextSize: Int) -> Double {
        // Get pricing based on THIS message's context size
        let pricing: PricingManager.ContextPricing
        if let pricingManager = pricingManager {
            pricing = pricingManager.getPricing(contextSize: contextSize)
        } else {
            pricing = .standardDefault
        }

        let inputCost = Double(input) * (pricing.inputTokens / 1_000_000)
        let cacheCreationCost = Double(cacheCreation) * (pricing.cacheCreation / 1_000_000)
        let cacheReadCost = Double(cacheRead) * (pricing.cacheRead / 1_000_000)
        let outputCost = Double(output) * (pricing.outputTokens / 1_000_000)

        return inputCost + cacheCreationCost + cacheReadCost + outputCost
    }
    
    private func getCurrentMonthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    private func simplifyProjectName(_ name: String) -> String {
        // Extract the actual project name from the path
        // Format: -Users-username-Documents-PERSONAL-ProjectName or similar
        let components = name.components(separatedBy: "-")
        
        // Find the last meaningful component (after PERSONAL, Documents, etc.)
        if let personalIndex = components.lastIndex(where: { $0 == "PERSONAL" || $0 == "Documents" }) {
            let projectComponents = components.suffix(from: personalIndex + 1)
            if !projectComponents.isEmpty {
                return projectComponents.joined(separator: "-")
            }
        }
        
        // Fallback: return last component if it's not a UUID pattern
        if let lastComponent = components.last, !lastComponent.isEmpty {
            // Check if it looks like a UUID (contains numbers and letters in a specific pattern)
            let uuidPattern = #"^[0-9a-fA-F]{8}$"#
            if lastComponent.range(of: uuidPattern, options: .regularExpression) == nil {
                return lastComponent
            }
        }
        
        return name
    }
    
    func formatMonth(_ monthKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: monthKey) {
            formatter.dateFormat = "MMMM yyyy"

            // Use the current app language
            if let localizationManager = localizationManager {
                let localeIdentifier = localizationManager.currentLanguage == .english ? "en_US" : "es_ES"
                formatter.locale = Locale(identifier: localeIdentifier)
            } else {
                // Fallback to system locale if localizationManager is not set
                formatter.locale = Locale.current
            }

            return formatter.string(from: date)
        }
        return monthKey
    }
}
