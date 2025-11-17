import Foundation

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language = .english
    
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .spanish: return "🇪🇸"
            }
        }
        
        var name: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            }
        }
    }
    
    func localized(_ key: LocalizationKey) -> String {
        return key.localized(for: currentLanguage)
    }
}

enum LocalizationKey {
    case title
    case byMonth
    case byProject
    case lastUpdate
    case total
    case inputTokens
    case cacheCreation
    case cacheRead
    case outputTokens
    case input
    case output
    
    func localized(for language: LocalizationManager.Language) -> String {
        switch language {
        case .english:
            return englishValue
        case .spanish:
            return spanishValue
        }
    }
    
    private var englishValue: String {
        switch self {
        case .title: return "Claude Usage Tracker"
        case .byMonth: return "By Month"
        case .byProject: return "By Project"
        case .lastUpdate: return "Last update:"
        case .total: return "TOTAL"
        case .inputTokens: return "Input tokens"
        case .cacheCreation: return "Cache creation"
        case .cacheRead: return "Cache read"
        case .outputTokens: return "Output tokens"
        case .input: return "Input"
        case .output: return "Output"
        }
    }
    
    private var spanishValue: String {
        switch self {
        case .title: return "Seguimiento de Uso de Claude"
        case .byMonth: return "Por Mes"
        case .byProject: return "Por Proyecto"
        case .lastUpdate: return "Última actualización:"
        case .total: return "TOTAL"
        case .inputTokens: return "Tokens de entrada"
        case .cacheCreation: return "Creación de caché"
        case .cacheRead: return "Lectura de caché"
        case .outputTokens: return "Tokens de salida"
        case .input: return "Entrada"
        case .output: return "Salida"
        }
    }
}
