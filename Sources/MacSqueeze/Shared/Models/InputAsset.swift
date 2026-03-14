import Foundation

struct InputAsset: Identifiable, Equatable {
    let id: UUID
    let fileURL: URL
    let filename: String
    let format: ImageFormat
    let fileSize: Int64
    let pixelWidth: Int
    let pixelHeight: Int

    init(
        id: UUID = UUID(),
        fileURL: URL,
        filename: String,
        format: ImageFormat,
        fileSize: Int64,
        pixelWidth: Int,
        pixelHeight: Int
    ) {
        self.id = id
        self.fileURL = fileURL
        self.filename = filename
        self.format = format
        self.fileSize = fileSize
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}
