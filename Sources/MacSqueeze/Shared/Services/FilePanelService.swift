import AppKit
import Foundation

enum FilePanelService {
    @MainActor
    static func chooseImportURLs() -> [URL]? {
        let panel = NSOpenPanel()
        panel.title = "Add Images"
        panel.prompt = "Add"
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.resolvesAliases = true
        return panel.runModal() == .OK ? panel.urls : nil
    }

    @MainActor
    static func chooseExportDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Export Folder"
        panel.prompt = "Choose"
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }
}
