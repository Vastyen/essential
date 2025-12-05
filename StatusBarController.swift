import AppKit
import SwiftUI

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover
    private var eventMonitor: Any?
    private let clipboardStore: ClipboardStore
    
    init(clipboardStore: ClipboardStore) {
        self.clipboardStore = clipboardStore
        self.popover = NSPopover()
        
        super.init()
        
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        updateIcon()
        
        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        
        let iconText = UserDefaults.standard.string(forKey: "menuBarIcon") ?? "</>"
        
        let fontSize: CGFloat = (iconText == "</>") ? 12 : 19
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
        
        let attributedString = NSMutableAttributedString(string: iconText)
        let range = NSRange(location: 0, length: iconText.utf16.count)
        attributedString.addAttribute(.font, value: font, range: range)
        
        if iconText != "</>" {
            attributedString.addAttribute(.baselineOffset, value: -2.3, range: range)
        }
        
        button.attributedTitle = attributedString
        button.alignment = .center
        button.imagePosition = .noImage
    }
    
    private func setupPopover() {
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.behavior = .transient
        popover.animates = true
        
        let clipboardView = ClipboardView(store: clipboardStore) { [weak self] in
            self?.closePopover()
        }
        popover.contentViewController = NSHostingController(rootView: clipboardView)
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.popover.isShown else { return }
            self.closePopover()
        }
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }
    
    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    private func closePopover() {
        popover.performClose(nil)
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        // Abrir directorio de screenshots
        let openScreenshotsItem = NSMenuItem(
            title: "Open Screenshot Folder",
            action: #selector(openScreenshotsDirectory),
            keyEquivalent: ""
        )
        openScreenshotsItem.target = self
        menu.addItem(openScreenshotsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let iconSubmenu = NSMenu()
        let currentIcon = UserDefaults.standard.string(forKey: "menuBarIcon") ?? "</>"
        let iconOptions = ["</>", "⌘", "⌥"]
        
        for icon in iconOptions {
            let item = NSMenuItem(title: icon, action: #selector(changeIcon(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = icon
            if icon == currentIcon {
                item.state = .on
            }
            iconSubmenu.addItem(item)
        }
        
        let iconMenuItem = NSMenuItem(title: "Change Icon", action: nil, keyEquivalent: "")
        iconMenuItem.submenu = iconSubmenu
        menu.addItem(iconMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Essential", action: #selector(quitApp), keyEquivalent: "q"))
        
        for item in menu.items where item.action != nil {
            item.target = self
        }
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func openScreenshotsDirectory() {
        let screenshotPath = UserDefaults.standard.string(forKey: "screenshotPath") ?? ""
        var directoryURL: URL
        
        if screenshotPath.isEmpty {
            // Usar la ruta por defecto
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            directoryURL = documentsURL.appendingPathComponent("Screenshots")
        } else {
            directoryURL = URL(fileURLWithPath: screenshotPath)
        }
        
        // Crear el directorio si no existe
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Abrir el directorio en Finder
        NSWorkspace.shared.open(directoryURL)
    }
    
    @objc private func changeIcon(_ sender: NSMenuItem) {
        guard let icon = sender.representedObject as? String else { return }
        
        UserDefaults.standard.set(icon, forKey: "menuBarIcon")
        
        updateIcon()
    }
    
    @objc private func clearHistory() {
        clipboardStore.clearHistory()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
