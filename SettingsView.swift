import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var pricingManager: PricingManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var standardInput: String
    @State private var standardOutput: String
    @State private var standardCacheCreation: String
    @State private var standardCacheRead: String
    
    @State private var longInput: String
    @State private var longOutput: String
    @State private var longCacheCreation: String
    @State private var longCacheRead: String
    
    init() {
        let pricing = PricingManager()
        _standardInput = State(initialValue: String(format: "%.2f", pricing.standardContext.inputTokens))
        _standardOutput = State(initialValue: String(format: "%.2f", pricing.standardContext.outputTokens))
        _standardCacheCreation = State(initialValue: String(format: "%.2f", pricing.standardContext.cacheCreation))
        _standardCacheRead = State(initialValue: String(format: "%.2f", pricing.standardContext.cacheRead))
        
        _longInput = State(initialValue: String(format: "%.2f", pricing.longContext.inputTokens))
        _longOutput = State(initialValue: String(format: "%.2f", pricing.longContext.outputTokens))
        _longCacheCreation = State(initialValue: String(format: "%.2f", pricing.longContext.cacheCreation))
        _longCacheRead = State(initialValue: String(format: "%.2f", pricing.longContext.cacheRead))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEnglish ? "Pricing Settings" : "Configuración de Precios")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Model info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isEnglish ? "Model: Claude Sonnet 4.5" : "Modelo: Claude Sonnet 4.5")
                            .font(.subheadline)
                            .bold()
                        Text(isEnglish ? "Prices per million tokens" : "Precios por millón de tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    // Standard Context
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isEnglish ? "📄 Standard Context (≤ 200K tokens)" : "📄 Contexto Estándar (≤ 200K tokens)")
                            .font(.subheadline)
                            .bold()
                        
                        PriceField(
                            label: isEnglish ? "Input tokens" : "Tokens de entrada",
                            value: $standardInput
                        )
                        PriceField(
                            label: isEnglish ? "Output tokens" : "Tokens de salida",
                            value: $standardOutput
                        )
                        PriceField(
                            label: isEnglish ? "Cache creation" : "Creación de caché",
                            value: $standardCacheCreation
                        )
                        PriceField(
                            label: isEnglish ? "Cache read" : "Lectura de caché",
                            value: $standardCacheRead
                        )
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Long Context
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isEnglish ? "📚 Long Context (> 200K tokens)" : "📚 Contexto Largo (> 200K tokens)")
                            .font(.subheadline)
                            .bold()
                        
                        PriceField(
                            label: isEnglish ? "Input tokens" : "Tokens de entrada",
                            value: $longInput
                        )
                        PriceField(
                            label: isEnglish ? "Output tokens" : "Tokens de salida",
                            value: $longOutput
                        )
                        PriceField(
                            label: isEnglish ? "Cache creation" : "Creación de caché",
                            value: $longCacheCreation
                        )
                        PriceField(
                            label: isEnglish ? "Cache read" : "Lectura de caché",
                            value: $longCacheRead
                        )
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
            
            Divider()
            
            // Footer buttons
            HStack(spacing: 12) {
                Button(action: resetToDefaults) {
                    Text(isEnglish ? "Reset to Defaults" : "Restaurar Valores")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: saveSettings) {
                    Text(isEnglish ? "Save" : "Guardar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 450, height: 600)
        .onAppear {
            loadCurrentValues()
        }
    }
    
    private var isEnglish: Bool {
        localizationManager.currentLanguage == .english
    }
    
    private func loadCurrentValues() {
        standardInput = String(format: "%.2f", pricingManager.standardContext.inputTokens)
        standardOutput = String(format: "%.2f", pricingManager.standardContext.outputTokens)
        standardCacheCreation = String(format: "%.2f", pricingManager.standardContext.cacheCreation)
        standardCacheRead = String(format: "%.2f", pricingManager.standardContext.cacheRead)
        
        longInput = String(format: "%.2f", pricingManager.longContext.inputTokens)
        longOutput = String(format: "%.2f", pricingManager.longContext.outputTokens)
        longCacheCreation = String(format: "%.2f", pricingManager.longContext.cacheCreation)
        longCacheRead = String(format: "%.2f", pricingManager.longContext.cacheRead)
    }
    
    private func saveSettings() {
        pricingManager.standardContext.inputTokens = Double(standardInput) ?? 3.00
        pricingManager.standardContext.outputTokens = Double(standardOutput) ?? 15.00
        pricingManager.standardContext.cacheCreation = Double(standardCacheCreation) ?? 3.75
        pricingManager.standardContext.cacheRead = Double(standardCacheRead) ?? 0.30
        
        pricingManager.longContext.inputTokens = Double(longInput) ?? 6.00
        pricingManager.longContext.outputTokens = Double(longOutput) ?? 22.50
        pricingManager.longContext.cacheCreation = Double(longCacheCreation) ?? 7.50
        pricingManager.longContext.cacheRead = Double(longCacheRead) ?? 0.60
        
        pricingManager.save()
        dismiss()
    }
    
    private func resetToDefaults() {
        pricingManager.reset()
        loadCurrentValues()
    }
}

struct PriceField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text("$")
                .foregroundColor(.secondary)
            
            TextField("0.00", text: $value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
            
            Text("/ 1M")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
