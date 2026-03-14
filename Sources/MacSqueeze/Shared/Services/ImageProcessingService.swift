import CoreGraphics
import Foundation
import ImageIO
import WebP

enum ImageProcessingService {
    enum ProcessingError: LocalizedError {
        case unreadableSource
        case unreadableImage
        case unsupportedDestination
        case failedToCreateContext
        case failedToFinalize
        case invalidResizeValue

        var errorDescription: String? {
            switch self {
            case .unreadableSource:
                return "Could not read the source image."
            case .unreadableImage:
                return "Could not decode the image."
            case .unsupportedDestination:
                return "Could not create an encoder for the selected format."
            case .failedToCreateContext:
                return "Could not create a graphics context for resizing."
            case .failedToFinalize:
                return "Could not write the output image."
            case .invalidResizeValue:
                return "Resize value must be greater than zero."
            }
        }
    }

    static func process(
        asset: InputAsset,
        settings: ProcessingSettings,
        outputDirectory: URL
    ) throws -> ProcessedAsset {
        var normalized = settings
        normalized.normalize()

        guard let source = CGImageSourceCreateWithURL(asset.fileURL as CFURL, nil) else {
            throw ProcessingError.unreadableSource
        }

        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ProcessingError.unreadableImage
        }

        let originalSize = CGSize(width: image.width, height: image.height)
        let targetSize = try targetSize(from: originalSize, settings: normalized)
        let renderedImage = try renderImage(image, to: targetSize)
        let destinationURL = try ExportPathService.destinationURL(for: asset, settings: normalized, directory: outputDirectory)

        if normalized.conflictPolicy == .overwrite,
           FileManager.default.fileExists(atPath: destinationURL.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        if normalized.outputFormat == .webp {
            let data = try encodeWebP(from: renderedImage, settings: normalized)
            try data.write(to: destinationURL, options: .atomic)

            let values = try destinationURL.resourceValues(forKeys: [.fileSizeKey])
            return ProcessedAsset(
                outputFileSize: Int64(values.fileSize ?? 0)
            )
        }

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            normalized.outputFormat.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ProcessingError.unsupportedDestination
        }

        var properties: [CFString: Any] = [:]
        if normalized.outputFormat.supportsLossyCompression, normalized.compressionMode == .lossy {
            properties[kCGImageDestinationLossyCompressionQuality] = normalized.quality
        }

        CGImageDestinationAddImage(destination, renderedImage, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.failedToFinalize
        }

        let values = try destinationURL.resourceValues(forKeys: [.fileSizeKey])
        return ProcessedAsset(
            outputFileSize: Int64(values.fileSize ?? 0)
        )
    }

    static func targetSize(from original: CGSize, settings: ProcessingSettings) throws -> CGSize {
        guard settings.resizeMode != .none else {
            return original
        }

        guard settings.resizeValue > 0 else {
            throw ProcessingError.invalidResizeValue
        }

        let width = original.width
        let height = original.height
        let aspectRatio = width / max(height, 1)

        switch settings.resizeMode {
        case .none:
            return original
        case .width:
            let newWidth = settings.resizeValue
            let newHeight = settings.preserveAspectRatio ? newWidth / aspectRatio : height
            return CGSize(width: newWidth, height: newHeight)
        case .height:
            let newHeight = settings.resizeValue
            let newWidth = settings.preserveAspectRatio ? newHeight * aspectRatio : width
            return CGSize(width: newWidth, height: newHeight)
        case .longestEdge:
            let longest = max(width, height)
            let scale = settings.resizeValue / longest
            return CGSize(width: width * scale, height: height * scale)
        case .percentage:
            let scale = settings.resizeValue / 100
            return CGSize(width: width * scale, height: height * scale)
        }
    }

    private static func renderImage(_ image: CGImage, to targetSize: CGSize) throws -> CGImage {
        let width = max(Int(targetSize.width.rounded(.toNearestOrEven)), 1)
        let height = max(Int(targetSize.height.rounded(.toNearestOrEven)), 1)

        if width == image.width, height == image.height {
            return image
        }

        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = image.bitmapInfo.rawValue == 0
            ? CGImageAlphaInfo.premultipliedLast.rawValue
            : image.bitmapInfo.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ProcessingError.failedToCreateContext
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let scaledImage = context.makeImage() else {
            throw ProcessingError.failedToCreateContext
        }

        return scaledImage
    }

    private static func encodeWebP(from image: CGImage, settings: ProcessingSettings) throws -> Data {
        let encoder = WebPEncoder()
        var config = WebPEncoderConfig.preset(.picture, quality: Float(settings.quality * 100))
        if settings.compressionMode == .lossless {
            config.lossless = 1
            config.quality = 100
        }

        return try encoder.encode(RGBA: image, config: config)
    }
}
