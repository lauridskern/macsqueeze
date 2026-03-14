import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var items: [QueueItem] = []
    @Published var settings = ProcessingSettings()
    @Published var exportDirectory: URL?
    @Published var isTargeted = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private var processingTask: Task<Void, Never>?

    var hasItems: Bool {
        items.isEmpty == false
    }

    var canExport: Bool {
        hasItems && isProcessing == false
    }

    var totalOriginalSize: Int64 {
        items.reduce(0) { $0 + $1.asset.fileSize }
    }

    var completedCount: Int {
        items.reduce(into: 0) { count, item in
            if case .done = item.status {
                count += 1
            }
        }
    }

    var failedCount: Int {
        items.reduce(into: 0) { count, item in
            if case .failed = item.status {
                count += 1
            }
        }
    }

    func chooseFiles() {
        guard let urls = FilePanelService.chooseImportURLs() else { return }

        Task {
            await importURLs(urls)
        }
    }

    func chooseExportDirectory() {
        exportDirectory = FilePanelService.chooseExportDirectory()
    }

    func importProviders(_ providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = try? await provider.loadFileURL() {
                    urls.append(url)
                }
            }

            guard urls.isEmpty == false else {
                errorMessage = "No readable image files were dropped."
                return
            }

            await importURLs(urls)
        }
    }

    func importURLs(_ urls: [URL]) async {
        do {
            let newAssets = try await Task.detached(priority: .userInitiated) {
                try FileImportService.makeAssets(from: urls)
            }.value

            let existingPaths = Set(items.map { $0.asset.fileURL.standardizedFileURL.path(percentEncoded: false) })
            let freshItems = newAssets
                .filter { !existingPaths.contains($0.fileURL.standardizedFileURL.path(percentEncoded: false)) }
                .map(QueueItem.init)

            items.append(contentsOf: freshItems)

            if freshItems.isEmpty, urls.isEmpty == false {
                errorMessage = "No new supported image files were added."
            } else {
                errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeItem(withID id: UUID) {
        items.removeAll { $0.id == id }
    }

    func clearQueue() {
        cancelProcessing()
        items.removeAll()
    }

    func exportBatch() {
        guard canExport else { return }
        settings.normalize()

        if exportDirectory == nil {
            exportDirectory = FilePanelService.chooseExportDirectory()
        }

        guard let exportDirectory else { return }

        errorMessage = nil
        isProcessing = true
        resetStatusesForExport()

        processingTask = Task {
            defer {
                Task { @MainActor in
                    self.isProcessing = false
                }
            }

            for index in items.indices {
                if Task.isCancelled {
                    markRemainingCancelled(startingAt: index)
                    return
                }

                setStatus(.processing, at: index)

                let asset = items[index].asset
                let settings = self.settings
                do {
                    let result = try await Task.detached(priority: .userInitiated) {
                        try ImageProcessingService.process(
                            asset: asset,
                            settings: settings,
                            outputDirectory: exportDirectory
                        )
                    }.value

                    setStatus(.done(bytesWritten: result.outputFileSize), at: index)
                } catch {
                    setStatus(.failed(message: error.localizedDescription), at: index)
                }
            }
        }
    }

    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
    }

    private func resetStatusesForExport() {
        for index in items.indices {
            items[index].status = .pending
        }
    }

    private func setStatus(_ status: QueueItemStatus, at index: Int) {
        guard items.indices.contains(index) else { return }
        items[index].status = status
    }

    private func markRemainingCancelled(startingAt start: Int) {
        guard start < items.count else { return }
        for index in start..<items.count where items[index].status == .pending {
            items[index].status = .cancelled
        }
    }
}

private extension NSItemProvider {
    func loadFileURL() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            if hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        continuation.resume(returning: url)
                        return
                    }

                    if let url = item as? URL {
                        continuation.resume(returning: url)
                        return
                    }

                    continuation.resume(throwing: CocoaError(.fileReadUnknown))
                }
            } else {
                continuation.resume(throwing: CocoaError(.fileReadUnsupportedScheme))
            }
        }
    }
}
