import Foundation
import SwiftUI

class PreferencesManager: ObservableObject {
    private let showCostKey = "showCostInStatusBar"

    @Published var showCostInStatusBar: Bool {
        didSet {
            UserDefaults.standard.set(showCostInStatusBar, forKey: showCostKey)
        }
    }

    init() {
        // Default to true (showing cost) if not set
        if UserDefaults.standard.object(forKey: showCostKey) != nil {
            self.showCostInStatusBar = UserDefaults.standard.bool(forKey: showCostKey)
        } else {
            self.showCostInStatusBar = true
        }
    }
}
