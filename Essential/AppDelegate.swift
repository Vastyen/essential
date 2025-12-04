import AppKit
import ApplicationServices
import CoreGraphics
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?
    private let clipboardStore = ClipboardStore()
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if hasCompletedOnboarding {
            startApp()
        } else {
            showOnboarding()
        }
    }
    
    private func showOnboarding() {
        NSApp.setActivationPolicy(.regular)
        
        let onboardingView = OnboardingView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.startApp()
        }
        
        let hostingController = NSHostingController(rootView: onboardingView)
        
        onboardingWindow = NSWindow(contentViewController: hostingController)
        onboardingWindow?.title = "Essential"
        onboardingWindow?.styleMask = [.titled, .closable]
        onboardingWindow?.isReleasedWhenClosed = false
        onboardingWindow?.delegate = self
        
        if let screen = NSScreen.main {
            let size = NSSize(width: 560, height: 660)
            let visibleFrame = screen.visibleFrame
            let x = visibleFrame.origin.x + (visibleFrame.width - size.width) / 2
            let y = visibleFrame.origin.y + (visibleFrame.height - size.height) / 2
            onboardingWindow?.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        }
        
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func startApp() {
        NSApp.setActivationPolicy(.accessory)
        
        enableLaunchAtLogin()
        requestScreenRecordingPermissions()
        checkAccessibilityPermissions()

        statusBarController = StatusBarController(clipboardStore: clipboardStore)

        hotkeyManager = HotkeyManager(
            onScreenshotSelection: { [weak self] in
                self?.captureScreenSelection()
            },
            onScreenshotFullScreen: { [weak self] in
                self?.captureFullScreen()
            },
            onToggleClipboard: { [weak statusBarController] in
                statusBarController?.togglePopover()
            }
        )
    }
    
    private func enableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                let service = SMAppService.mainApp
                if service.status == .notRegistered {
                    try service.register()
                    print("✅ Launch at Login enabled (SMAppService)")
                } else {
                    print("✅ Launch at Login already enabled")
                }
            } catch {
                print("⚠️ Failed to enable Launch at Login: \(error)")
            }
        } else {
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "open.Essential"
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, true)
            if success {
                print("✅ Launch at Login enabled (SMLoginItemSetEnabled)")
            } else {
                print("⚠️ Failed to enable Launch at Login")
            }
        }
    }
    
    private func requestScreenRecordingPermissions() {
        let hasPermission = CGPreflightScreenCaptureAccess()
        
        if !hasPermission {
            print("📹 Requesting Screen Recording permissions...")
            
            NSApp.activate(ignoringOtherApps: true)
            
            let granted = CGRequestScreenCaptureAccess()
            
            if granted {
                print("✅ Screen Recording permission granted")
            } else {
                print("⚠️ Screen Recording permission denied or dialog didn't appear")
                print("   Opening System Settings...")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if CGPreflightScreenCaptureAccess() {
                        print("✅ Screen Recording permission granted (after delay)")
                        return
                    }
                    
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        NSWorkspace.shared.open(url)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
        } else {
            print("✅ Screen Recording permission already granted")
        }
    }
    
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ Accessibility permissions required for ⌘⇧3 and ⌘⇧4")
            print("   Go to: System Settings → Privacy & Security → Accessibility")
            print("   Enable Essential")
            
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        } else {
            print("✅ Accessibility permissions granted")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager = nil
    }

    private func captureScreenSelection() {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-c", "-s"]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Error running screencapture: \(error)")
            }
        }
    }

    private func captureFullScreen() {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-c"]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Error running screencapture: \(error)")
            }
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window === onboardingWindow else { return }
        
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompleted {
            NSApp.terminate(nil)
        }
    }
}
