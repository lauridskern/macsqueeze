import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let window = notification.object as? NSWindow else { return }
            Task { @MainActor in
                self.configure(window)
            }
        }

        Task { @MainActor in
            NSApp.windows.forEach { self.configure($0) }
        }
    }

    private func configure(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unifiedCompact

        guard
            let closeButton = window.standardWindowButton(.closeButton),
            let minimizeButton = window.standardWindowButton(.miniaturizeButton),
            let zoomButton = window.standardWindowButton(.zoomButton),
            let container = closeButton.superview
        else {
            return
        }

        let buttons = [closeButton, minimizeButton, zoomButton]
        let startX: CGFloat = 16
        let spacing: CGFloat = 8
        let centeredY = round((container.bounds.height - closeButton.frame.height) / 2) - 5

        for (index, button) in buttons.enumerated() {
            button.setFrameOrigin(
                NSPoint(
                    x: startX + CGFloat(index) * (closeButton.frame.width + spacing),
                    y: centeredY
                )
            )
        }
    }
}

@main
struct MacSqueezeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .tint(AppTheme.tint)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Images") {
                    model.chooseFiles()
                }
                .keyboardShortcut("o")
            }

            CommandMenu("Batch") {
                Button("Export Batch") {
                    model.exportBatch()
                }
                .keyboardShortcut("e")
                .disabled(model.canExport == false)

                Button("Choose Export Folder") {
                    model.chooseExportDirectory()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button("Cancel Processing") {
                    model.cancelProcessing()
                }
                .disabled(model.isProcessing == false)

                Button("Clear Queue") {
                    model.clearQueue()
                }
                .disabled(model.hasItems == false)
            }
        }
    }
}
