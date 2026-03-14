import CoreGraphics
import Foundation
import Testing
@testable import MacSqueeze

struct MacSqueezeTests {
    @Test
    func imageFormatFromURL() {
        #expect(ImageFormat.from(url: URL(fileURLWithPath: "/tmp/demo.jpg")) == .jpeg)
        #expect(ImageFormat.from(url: URL(fileURLWithPath: "/tmp/demo.png")) == .png)
        #expect(ImageFormat.from(url: URL(fileURLWithPath: "/tmp/demo.heic")) == .heic)
        #expect(ImageFormat.from(url: URL(fileURLWithPath: "/tmp/demo.webp")) == .webp)
        #expect(ImageFormat.from(url: URL(fileURLWithPath: "/tmp/demo.gif")) == nil)
    }

    @Test
    func targetSizeForWidthResize() throws {
        var settings = ProcessingSettings()
        settings.resizeMode = .width
        settings.resizeValue = 1000
        settings.preserveAspectRatio = true

        let size = try ImageProcessingService.targetSize(
            from: CGSize(width: 2000, height: 1000),
            settings: settings
        )

        #expect(size.width == 1000)
        #expect(size.height == 500)
    }

    @Test
    func keepBothCreatesUniqueURL() {
        let url = URL(fileURLWithPath: "/tmp/sample.jpg")
        let unique = ExportPathService.uniqueURL(startingAt: url)
        #expect(unique.pathExtension == "jpg")
    }

    @Test
    func settingsNormalizeSwitchesCompressionMode() {
        var settings = ProcessingSettings()
        settings.outputFormat = .png
        settings.compressionMode = .lossy

        settings.normalize()

        #expect(settings.compressionMode == .lossless)
    }

    @Test
    func webPExposesBothCompressionModes() {
        var settings = ProcessingSettings()
        settings.outputFormat = .webp

        #expect(settings.availableCompressionModes == [.lossy, .lossless])
    }
}
