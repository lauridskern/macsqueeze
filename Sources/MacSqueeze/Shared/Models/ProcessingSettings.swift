import Foundation

enum CompressionMode: String, CaseIterable, Codable, Identifiable {
    case lossy
    case lossless

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

enum ResizeMode: String, CaseIterable, Codable, Identifiable {
    case none
    case width
    case height
    case longestEdge
    case percentage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .width:
            return "Width"
        case .height:
            return "Height"
        case .longestEdge:
            return "Longest Edge"
        case .percentage:
            return "Percentage"
        }
    }
}

enum ConflictPolicy: String, CaseIterable, Codable, Identifiable {
    case keepBoth
    case overwrite
    case ask

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .keepBoth:
            return "Keep Both"
        case .overwrite:
            return "Overwrite"
        case .ask:
            return "Ask"
        }
    }
}

struct ProcessingSettings: Codable, Equatable {
    var outputFormat: ImageFormat = .jpeg
    var compressionMode: CompressionMode = .lossy
    var quality: Double = 0.82
    var resizeMode: ResizeMode = .none
    var resizeValue: Double = 1600
    var preserveAspectRatio: Bool = true
    var filenameSuffix: String = ""
    var conflictPolicy: ConflictPolicy = .keepBoth

    var availableCompressionModes: [CompressionMode] {
        if outputFormat.supportsLossyCompression && outputFormat.supportsLosslessCompression {
            return [.lossy, .lossless]
        }

        if outputFormat.supportsLossyCompression {
            return [.lossy]
        }

        return [.lossless]
    }

    mutating func normalize() {
        if availableCompressionModes.contains(compressionMode) == false {
            compressionMode = availableCompressionModes.first ?? .lossless
        }

        if resizeMode == .percentage && resizeValue <= 0 {
            resizeValue = 100
        }
    }
}
