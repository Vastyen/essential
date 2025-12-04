import AppKit
import Combine
import SwiftUI

struct ClipboardEntry: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let content: ClipboardContent
    
    init(content: ClipboardContent) {
        self.id = UUID()
        self.timestamp = Date()
        self.content = content
    }
    
    static func == (lhs: ClipboardEntry, rhs: ClipboardEntry) -> Bool {
        lhs.id == rhs.id
    }
}

enum ClipboardContent: Equatable {
    case text(String)
    case image(NSImage)
    
    var previewText: String {
        switch self {
        case .text(let string):
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 100 {
                return String(trimmed.prefix(100)) + "..."
            }
            return trimmed
        case .image:
            return "📷 Image"
        }
    }
    
    static func == (lhs: ClipboardContent, rhs: ClipboardContent) -> Bool {
        switch (lhs, rhs) {
        case (.text(let a), .text(let b)):
            return a == b
        case (.image(let a), .image(let b)):
            return a.tiffRepresentation == b.tiffRepresentation
        default:
            return false
        }
    }
}

final class ClipboardStore: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry] = []
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let maxHistoryCount = 50
    private let pollInterval: TimeInterval = 0.5
    
    init() {
        self.lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            addEntry(content: .image(image))
            return
        }
        
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            if case .text(let lastText) = entries.first?.content, lastText == string {
                return
            }
            addEntry(content: .text(string))
        }
    }
    
    private func addEntry(content: ClipboardContent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.entries.removeAll { entry in
                entry.content == content
            }
            
            let entry = ClipboardEntry(content: content)
            self.entries.insert(entry, at: 0)
            
            if self.entries.count > self.maxHistoryCount {
                self.entries = Array(self.entries.prefix(self.maxHistoryCount))
            }
        }
    }
    
    func copyToClipboard(_ entry: ClipboardEntry) {
        stopMonitoring()
        
        pasteboard.clearContents()
        
        switch entry.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let image):
            pasteboard.writeObjects([image])
        }
        
        lastChangeCount = pasteboard.changeCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
    }
    
    func deleteEntry(_ entry: ClipboardEntry) {
        entries.removeAll { $0.id == entry.id }
    }
    
    func clearHistory() {
        entries.removeAll()
    }
}
