import SwiftUI

struct MainView: View {
    @EnvironmentObject var manager: ClaudeUsageManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var pricingManager: PricingManager
    @EnvironmentObject var currencyManager: CurrencyManager
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("💰 \(localizationManager.localized(.title))")
                    .font(.headline)
                Spacer()
                
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
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(manager.monthlyData, id: \.month) { item in
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
                
                Divider()
                    .padding(.vertical)
                
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
            }
            .padding()
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
