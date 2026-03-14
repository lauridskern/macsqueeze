import Foundation

enum QueueItemStatus: Equatable {
    case pending
    case processing
    case done(bytesWritten: Int64?)
    case failed(message: String)
    case cancelled

    var label: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .done:
            return "Done"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

struct QueueItem: Identifiable, Equatable {
    let id: UUID
    let asset: InputAsset
    var status: QueueItemStatus = .pending

    init(asset: InputAsset) {
        self.id = asset.id
        self.asset = asset
    }
}
