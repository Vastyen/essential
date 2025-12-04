import AppKit
import CoreGraphics
import SwiftUI

struct OnboardingView: View {
    @State private var screenCaptureGranted = false
    @State private var selectedIcon: String = "</>"
    @State private var permissionTimer: Timer?
    
    let onComplete: () -> Void
    
    private let iconOptions = ["</>", "⌘", "⌥"]
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    permissionSection
                    
                    Divider()
                    
                    iconSelectionSection
                    
                    Divider()
                    
                    shortcutsSection
                }
                .padding(28)
            }
            
            Divider()
            
            footerSection
        }
        .frame(width: 560, height: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            checkPermissions()
            loadSavedIcon()
            
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                let granted = CGPreflightScreenCaptureAccess()
                DispatchQueue.main.async {
                    if granted != self.screenCaptureGranted {
                        self.screenCaptureGranted = granted
                    }
                    if granted {
                        self.permissionTimer?.invalidate()
                        self.permissionTimer = nil
                    }
                }
            }
            RunLoop.current.add(permissionTimer!, forMode: .common)
        }
        .onDisappear {
            permissionTimer?.invalidate()
            permissionTimer = nil
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 72, height: 72)
                
                Text(selectedIcon)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            
            Text("Welcome to Essential")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your clipboard manager for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
    }
    
    private var permissionSection: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(screenCaptureGranted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "camera.viewfinder")
                    .font(.title3)
                    .foregroundColor(screenCaptureGranted ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Screen Recording")
                    .font(.headline)
                
                Text("Required for screenshot capture")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if screenCaptureGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Button("Open Settings") {
                    requestScreenCapture()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                    .foregroundColor(.purple)
                Text("Menu Bar Icon")
                    .font(.headline)
            }
            
            Text("Choose your preferred icon")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ForEach(iconOptions, id: \.self) { icon in
                    iconButton(icon)
                }
            }
        }
    }
    
    private func iconButton(_ icon: String) -> some View {
        Button {
            selectedIcon = icon
            saveIcon(icon)
        } label: {
            Text(icon)
                .font(.system(
                    size: icon == "</>" ? 24 : 33,
                    weight: .bold,
                    design: .monospaced
                ))
                .frame(width: 80, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .foregroundColor(.blue)
                Text("Keyboard Shortcuts")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                shortcutRow("⌘ ⇧ V", "Open clipboard history")
                shortcutRow("⌘ ⇧ 3", "Screenshot full screen")
                shortcutRow("⌘ ⇧ 4", "Screenshot selection")
            }
        }
    }
    
    private func shortcutRow(_ keys: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var footerSection: some View {
        HStack {
            Spacer()
            
            Button {
                saveIcon(selectedIcon)
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                onComplete()
            } label: {
                HStack(spacing: 6) {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
    }
    
    private func checkPermissions() {
        screenCaptureGranted = CGPreflightScreenCaptureAccess()
    }
    
    private func requestScreenCapture() {
        NSApp.activate(ignoringOtherApps: true)
        
        CGRequestScreenCaptureAccess()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if CGPreflightScreenCaptureAccess() {
                self.checkPermissions()
                return
            }
            
            let urlString: String
            if #available(macOS 13.0, *) {
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            } else {
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            }
            
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    private func loadSavedIcon() {
        if let saved = UserDefaults.standard.string(forKey: "menuBarIcon") {
            selectedIcon = saved
        }
    }
    
    private func saveIcon(_ icon: String) {
        UserDefaults.standard.set(icon, forKey: "menuBarIcon")
    }
}

struct ClipboardView: View {
    @ObservedObject var store: ClipboardStore
    let onDismiss: () -> Void
    
    @State private var hoveredEntryId: UUID?
    @State private var searchText: String = ""
    
    private var filteredEntries: [ClipboardEntry] {
        guard !searchText.isEmpty else { return store.entries }
        
        return store.entries.filter { entry in
            switch entry.content {
            case .text(let string):
                return string.localizedCaseInsensitiveContains(searchText)
            case .image:
                return "image".localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchBar
            Divider()
            contentView
        }
        .frame(width: 320, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text("Clipboard History")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(store.entries.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var contentView: some View {
        if filteredEntries.isEmpty {
            emptyStateView
        } else {
            entriesListView
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(searchText.isEmpty ? "No clipboard history" : "No results found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Text("Copy something to get started")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var entriesListView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(filteredEntries) { entry in
                    ClipboardEntryRow(
                        entry: entry,
                        isHovered: hoveredEntryId == entry.id,
                        onSelect: {
                            store.copyToClipboard(entry)
                            onDismiss()
                        },
                        onDelete: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                store.deleteEntry(entry)
                            }
                        }
                    )
                    .onHover { isHovered in
                        hoveredEntryId = isHovered ? entry.id : nil
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    let isHovered: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteButton = false
    
    var body: some View {
        HStack(spacing: 10) {
            contentPreview
            
            Spacer()
            
            if isHovered {
                deleteButton
            } else {
                timestampView
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
    
    @ViewBuilder
    private var contentPreview: some View {
        switch entry.content {
        case .text(let string):
            textPreview(string)
        case .image(let image):
            imagePreview(image)
        }
    }
    
    private func textPreview(_ string: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(entry.content.previewText)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func imagePreview(_ image: NSImage) -> some View {
        HStack(spacing: 8) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Screenshot")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var timestampView: some View {
        Text(entry.timestamp, style: .relative)
            .font(.caption2)
            .foregroundColor(.secondary)
    }
    
    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.caption)
                .foregroundColor(.red.opacity(0.8))
        }
        .buttonStyle(.plain)
        .help("Delete")
    }
}

#Preview {
    ClipboardView(store: ClipboardStore(), onDismiss: {})
}
