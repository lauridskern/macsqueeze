import Foundation
import UniformTypeIdentifiers

enum ImageFormat: String, CaseIterable, Codable, Identifiable {
    case jpeg
    case png
    case heic
    case webp
    case tiff

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jpeg:
            return "JPEG"
        case .png:
            return "PNG"
        case .heic:
            return "HEIC"
        case .webp:
            return "WebP"
        case .tiff:
            return "TIFF"
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        case .webp:
            return "webp"
        case .tiff:
            return "tiff"
        }
    }

    var utType: UTType {
        switch self {
        case .jpeg:
            return .jpeg
        case .png:
            return .png
        case .heic:
            return .heic
        case .webp:
            return .webP
        case .tiff:
            return .tiff
        }
    }

    var supportsLossyCompression: Bool {
        switch self {
        case .jpeg, .heic, .webp:
            return true
        case .png, .tiff:
            return false
        }
    }

    var supportsLosslessCompression: Bool {
        switch self {
        case .png, .tiff, .webp:
            return true
        case .jpeg, .heic:
            return false
        }
    }

    var isOutputFormat: Bool {
        switch self {
        case .jpeg, .png, .heic, .webp:
            return true
        case .tiff:
            return false
        }
    }

    static let supportedOutputFormats = allCases.filter(\.isOutputFormat)

    static func from(url: URL) -> ImageFormat? {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "jpg", "jpeg":
            return .jpeg
        case "png":
            return .png
        case "heic", "heif":
            return .heic
        case "webp":
            return .webp
        case "tif", "tiff":
            return .tiff
        default:
            return nil
        }
    }
}
