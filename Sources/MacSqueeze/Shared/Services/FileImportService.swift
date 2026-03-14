import Foundation
import ImageIO

enum FileImportService {
    static func makeAssets(from urls: [URL]) throws -> [InputAsset] {
        let fileURLs = try collectImageFiles(from: urls)
        var assets: [InputAsset] = []

        for url in fileURLs {
            if let asset = try makeAsset(from: url) {
                assets.append(asset)
            }
        }

        return assets.sorted { $0.filename.localizedStandardCompare($1.filename) == .orderedAscending }
    }

    private static func collectImageFiles(from urls: [URL]) throws -> [URL] {
        var collected: [URL] = []
        var seen = Set<String>()
        let fm = FileManager.default

        for url in urls {
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
                continue
            }

            if isDirectory.boolValue {
                let enumerator = fm.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )

                while let child = enumerator?.nextObject() as? URL {
                    if ImageFormat.from(url: child) != nil {
                        let key = child.standardizedFileURL.path(percentEncoded: false)
                        if seen.insert(key).inserted {
                            collected.append(child)
                        }
                    }
                }
            } else if ImageFormat.from(url: url) != nil {
                let key = url.standardizedFileURL.path(percentEncoded: false)
                if seen.insert(key).inserted {
                    collected.append(url)
                }
            }
        }

        return collected
    }

    private static func makeAsset(from url: URL) throws -> InputAsset? {
        guard let format = ImageFormat.from(url: url) else {
            return nil
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }

        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Int64(values.fileSize ?? 0)

        return InputAsset(
            fileURL: url,
            filename: url.lastPathComponent,
            format: format,
            fileSize: fileSize,
            pixelWidth: width,
            pixelHeight: height
        )
    }
}
