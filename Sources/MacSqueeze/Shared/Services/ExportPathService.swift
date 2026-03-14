import Foundation

enum ExportPathService {
    enum ExportError: LocalizedError {
        case fileExists(URL)

        var errorDescription: String? {
            switch self {
            case .fileExists(let url):
                return "File already exists: \(url.lastPathComponent)"
            }
        }
    }

    static func destinationURL(
        for asset: InputAsset,
        settings: ProcessingSettings,
        directory: URL
    ) throws -> URL {
        let baseName = asset.fileURL.deletingPathExtension().lastPathComponent
        let suffix = settings.filenameSuffix.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = suffix.isEmpty ? baseName : baseName + suffix
        let candidate = directory.appendingPathComponent(finalName).appendingPathExtension(settings.outputFormat.fileExtension)

        switch settings.conflictPolicy {
        case .overwrite:
            return candidate
        case .keepBoth:
            return uniqueURL(startingAt: candidate)
        case .ask:
            if FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
                throw ExportError.fileExists(candidate)
            }
            return candidate
        }
    }

    static func uniqueURL(startingAt url: URL) -> URL {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path(percentEncoded: false)) == false {
            return url
        }

        let directory = url.deletingLastPathComponent()
        let ext = url.pathExtension
        let base = url.deletingPathExtension().lastPathComponent

        for index in 2...9_999 {
            var candidate = directory.appendingPathComponent("\(base)-\(index)")
            if ext.isEmpty == false {
                candidate.appendPathExtension(ext)
            }
            if fm.fileExists(atPath: candidate.path(percentEncoded: false)) == false {
                return candidate
            }
        }

        return url
    }
}
