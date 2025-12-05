import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleClipboard = Self("toggleClipboard", default: .init(.v, modifiers: [.shift, .command]))
    static let screenshotFull = Self("screenshotFull", default: .init(.three, modifiers: [.shift, .command]))
    static let screenshotSelection = Self("screenshotSelection", default: .init(.four, modifiers: [.shift, .command]))
}

final class HotkeyManager {
    private let onScreenshotSelection: () -> Void
    private let onScreenshotFullScreen: () -> Void
    private let onToggleClipboard: () -> Void
    
    init(
        onScreenshotSelection: @escaping () -> Void,
        onScreenshotFullScreen: @escaping () -> Void,
        onToggleClipboard: @escaping () -> Void
    ) {
        self.onScreenshotSelection = onScreenshotSelection
        self.onScreenshotFullScreen = onScreenshotFullScreen
        self.onToggleClipboard = onToggleClipboard
        
        setupHotKeys()
    }
    
    private func setupHotKeys() {
        KeyboardShortcuts.onKeyDown(for: .toggleClipboard) { [weak self] in
            print("⌨️ CMD+SHIFT+V pressed")
            DispatchQueue.main.async {
                self?.onToggleClipboard()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .screenshotFull) { [weak self] in
            print("⌨️ CMD+SHIFT+3 pressed - Taking full screen screenshot")
            self?.onScreenshotFullScreen()
        }
        
        KeyboardShortcuts.onKeyDown(for: .screenshotSelection) { [weak self] in
            print("⌨️ CMD+SHIFT+4 pressed - Taking selection screenshot")
            self?.onScreenshotSelection()
        }
        
        print("✅ Hotkeys registered: ⌘⇧V, ⌘⇧3, ⌘⇧4")
    }
}


