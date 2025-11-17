import SwiftUI

@main
struct ClaudeUsageTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var manager = ClaudeUsageManager()
    var localizationManager = LocalizationManager()
    var pricingManager = PricingManager()
    private var timer: Timer?
    private var observation: NSKeyValueObservation?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Vincular managers con el manager de datos
        manager.pricingManager = pricingManager
        manager.localizationManager = localizationManager
        
        // Crear item en la barra de menú
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "💰 ..."
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Observar cambios en el manager para actualizar la barra de menú
        manager.onDataUpdated = { [weak self] in
            self?.updateMenuBarTitle()
        }
        
        manager.onLoadingStateChanged = { [weak self] isLoading in
            if isLoading {
                self?.showLoading()
            }
        }
        
        // Cargar datos iniciales
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.manager.loadData()
        }
        
        // Actualizar cada 1 minuto
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.manager.loadData()
        }
    }
    
    @objc func togglePopover() {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 450, height: 600)
        popover.behavior = .semitransient
        popover.contentViewController = NSHostingController(
            rootView: MainView()
                .environmentObject(manager)
                .environmentObject(localizationManager)
                .environmentObject(pricingManager)
        )
        self.popover = popover
        
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func updateMenuBarTitle() {
        if let button = statusItem?.button {
            let cost = manager.currentMonthCost
            button.title = String(format: "💰 $%.2f", cost)
        }
    }
    
    func showLoading() {
        if let button = statusItem?.button {
            button.title = "💰 ..."
        }
    }
}
