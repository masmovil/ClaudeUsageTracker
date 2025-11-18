import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @EnvironmentObject var manager: ClaudeUsageManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var pricingManager: PricingManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var selectedTab = 0
    @State private var showSettings = false

    func exportToCSV() {
        // Activate the app to bring the save panel to front
        NSApp.activate(ignoringOtherApps: true)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "claude_usage_export.csv"
        savePanel.level = .floating

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            var csvContent = ""

            if selectedTab == 0 {
                // Export Monthly Data
                csvContent += "Month,Token Type,Tokens,Cost ($)\n"

                for item in manager.monthlyData {
                    let formattedMonth = manager.formatMonth(item.month)

                    // Input tokens row
                    csvContent += "\"\(formattedMonth)\",Input,\(item.details.inputTokens),\(String(format: "%.2f", Double(item.details.inputTokens) * 0.000003))\n"

                    // Cache creation row
                    csvContent += "\"\(formattedMonth)\",Cache Creation,\(item.details.cacheCreationTokens),\(String(format: "%.2f", Double(item.details.cacheCreationTokens) * 0.00000375))\n"

                    // Cache read row
                    csvContent += "\"\(formattedMonth)\",Cache Read,\(item.details.cacheReadTokens),\(String(format: "%.2f", Double(item.details.cacheReadTokens) * 0.0000003))\n"

                    // Output tokens row
                    csvContent += "\"\(formattedMonth)\",Output,\(item.details.outputTokens),\(String(format: "%.2f", Double(item.details.outputTokens) * 0.000015))\n"

                    // Total row for the month
                    csvContent += "\"\(formattedMonth)\",TOTAL,-,\(String(format: "%.2f", item.cost))\n"

                    csvContent += "\n"
                }

                // Grand total
                csvContent += "GRAND TOTAL,-,-,\(String(format: "%.2f", manager.totalCost))\n"

            } else {
                // Export Project Data
                csvContent += "Project,Token Type,Tokens,Cost ($)\n"

                for item in manager.projectData {
                    let escapedProject = item.project

                    // Input tokens row
                    csvContent += "\"\(escapedProject)\",Input,\(item.details.inputTokens),\(String(format: "%.2f", Double(item.details.inputTokens) * 0.000003))\n"

                    // Cache creation row
                    csvContent += "\"\(escapedProject)\",Cache Creation,\(item.details.cacheCreationTokens),\(String(format: "%.2f", Double(item.details.cacheCreationTokens) * 0.00000375))\n"

                    // Cache read row
                    csvContent += "\"\(escapedProject)\",Cache Read,\(item.details.cacheReadTokens),\(String(format: "%.2f", Double(item.details.cacheReadTokens) * 0.0000003))\n"

                    // Output tokens row
                    csvContent += "\"\(escapedProject)\",Output,\(item.details.outputTokens),\(String(format: "%.2f", Double(item.details.outputTokens) * 0.000015))\n"

                    // Total row for the project
                    csvContent += "\"\(escapedProject)\",TOTAL,-,\(String(format: "%.2f", item.cost))\n"

                    csvContent += "\n"
                }

                // Grand total
                csvContent += "GRAND TOTAL,-,-,\(String(format: "%.2f", manager.totalCost))\n"
            }

            do {
                try csvContent.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Error saving CSV: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("💰 \(localizationManager.localized(.title))")
                    .font(.headline)
                Spacer()
                
                // Export button
                Button(action: {
                    exportToCSV()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .help(localizationManager.currentLanguage == .english ? "Export to CSV" : "Exportar a CSV")

                // Settings button
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(pricingManager)
                        .environmentObject(localizationManager)
                }

                // Language selector
                Menu {
                    ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                        Button(action: {
                            localizationManager.currentLanguage = language
                        }) {
                            HStack {
                                Text(language.flag)
                                Text(language.name)
                                if localizationManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(localizationManager.currentLanguage.flag)
                        .font(.title3)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                Button(action: {
                    manager.loadData()
                }) {
                    if manager.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                .disabled(manager.isLoading)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Tabs
            Picker("", selection: $selectedTab) {
                Text(localizationManager.localized(.byMonth)).tag(0)
                Text(localizationManager.localized(.byProject)).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
            
            // Content
            if selectedTab == 0 {
                MonthlyView()
            } else {
                ProjectView()
            }
            
            Divider()
            
            // Footer
            HStack {
                Text(localizationManager.localized(.lastUpdate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(manager.lastUpdate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 450, height: 600)
    }
}

struct MonthlyView: View {
    @EnvironmentObject var manager: ClaudeUsageManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var currentPage: Int = 0

    private let itemsPerPage = 2

    private var paginatedData: [(month: String, cost: Double, details: ClaudeUsageManager.TokenBreakdown)] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, manager.monthlyData.count)
        guard startIndex < manager.monthlyData.count else { return [] }
        return Array(manager.monthlyData[startIndex..<endIndex])
    }

    private var totalPages: Int {
        return (manager.monthlyData.count + itemsPerPage - 1) / itemsPerPage
    }

    private var pageTotal: Double {
        return paginatedData.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(paginatedData, id: \.month) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("📅 \(manager.formatMonth(item.month))")
                                    .font(.headline)
                                Spacer()
                                Text(currencyManager.formatAmount(item.cost, language: localizationManager.currentLanguage))
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }

                            TokenRow(
                                label: localizationManager.localized(.inputTokens),
                                count: item.details.inputTokens,
                                cost: Double(item.details.inputTokens) * 0.000003,
                                color: .blue
                            )

                            TokenRow(
                                label: localizationManager.localized(.cacheCreation),
                                count: item.details.cacheCreationTokens,
                                cost: Double(item.details.cacheCreationTokens) * 0.00000375,
                                color: .orange
                            )

                            TokenRow(
                                label: localizationManager.localized(.cacheRead),
                                count: item.details.cacheReadTokens,
                                cost: Double(item.details.cacheReadTokens) * 0.0000003,
                                color: .purple
                            )

                            TokenRow(
                                label: localizationManager.localized(.outputTokens),
                                count: item.details.outputTokens,
                                cost: Double(item.details.outputTokens) * 0.000015,
                                color: .red
                            )
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Page total
                    if totalPages > 1 {
                        HStack {
                            Text(localizationManager.currentLanguage == .english ? "Page Total" : "Total Página")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(currencyManager.formatAmount(pageTotal, language: localizationManager.currentLanguage))
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }

            // Pagination controls - abajo
            if totalPages > 1 {
                Divider()

                HStack(spacing: 12) {
                    // Botón Newer a la izquierda
                    Button(action: {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text(localizationManager.currentLanguage == .english ? "Newer" : "Recientes")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(currentPage == 0 ? .gray : .blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(currentPage == 0 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(currentPage == 0 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPage == 0)

                    Spacer()

                    // Indicador de página en el centro
                    Text("\(currentPage + 1) / \(totalPages)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.1))
                        )

                    Spacer()

                    // Botón Older a la derecha
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            currentPage += 1
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(localizationManager.currentLanguage == .english ? "Older" : "Antiguos")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(currentPage >= totalPages - 1 ? .gray : .blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(currentPage >= totalPages - 1 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(currentPage >= totalPages - 1 ? Color.gray.opacity(0.2) : Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPage >= totalPages - 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(NSColor.windowBackgroundColor))
            }

            Divider()

            // Grand total - anclado abajo
            HStack {
                Text(localizationManager.localized(.total))
                    .font(.headline)
                Spacer()
                Text(currencyManager.formatAmount(manager.totalCost, language: localizationManager.currentLanguage))
                    .font(.title2)
                    .bold()
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}

struct ProjectView: View {
    @EnvironmentObject var manager: ClaudeUsageManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(manager.projectData, id: \.project) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("📁 \(item.project)")
                                .font(.headline)
                                .lineLimit(2)
                            Spacer()
                            Text(currencyManager.formatAmount(item.cost, language: localizationManager.currentLanguage))
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        TokenRow(
                            label: localizationManager.localized(.input),
                            count: item.details.inputTokens,
                            cost: Double(item.details.inputTokens) * 0.000003,
                            color: .blue
                        )
                        
                        TokenRow(
                            label: localizationManager.localized(.cacheCreation),
                            count: item.details.cacheCreationTokens,
                            cost: Double(item.details.cacheCreationTokens) * 0.00000375,
                            color: .orange
                        )
                        
                        TokenRow(
                            label: localizationManager.localized(.cacheRead),
                            count: item.details.cacheReadTokens,
                            cost: Double(item.details.cacheReadTokens) * 0.0000003,
                            color: .purple
                        )
                        
                        TokenRow(
                            label: localizationManager.localized(.output),
                            count: item.details.outputTokens,
                            cost: Double(item.details.outputTokens) * 0.000015,
                            color: .red
                        )
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct TokenRow: View {
    let label: String
    let count: Int
    let cost: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatNumber(count))
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "$%.2f", cost))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
