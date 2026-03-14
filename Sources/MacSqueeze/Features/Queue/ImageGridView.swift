import AppKit
import SwiftUI

struct ImageGridView: View {
    @ObservedObject var model: AppModel
    private enum Layout {
        static let horizontalPadding: CGFloat = 24
        static let columnSpacing: CGFloat = 18
        static let rowSpacing: CGFloat = 16
        static let topInset: CGFloat = 48
        static let bottomInset: CGFloat = 24
        static let minTileWidth: CGFloat = 168
        static let maxTileWidth: CGFloat = 224
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = gridMetrics(for: proxy.size.width)

            ScrollView {
                LazyVGrid(columns: metrics.columns, spacing: Layout.rowSpacing) {
                    ForEach(model.items) { item in
                        ImageGridTile(
                            item: item,
                            isProcessing: model.isProcessing,
                            onRemove: { model.removeItem(withID: item.id) }
                        )
                        .frame(width: metrics.itemWidth, height: metrics.itemHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.topInset)
                .padding(.bottom, Layout.bottomInset)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomStats
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, 16)
                .background(AppTheme.canvas)
        }
    }

    private var bottomStats: some View {
        HStack(spacing: 12) {
            Text("\(model.items.count) files")
            Text(Formatters.fileSize(model.totalOriginalSize))
            Text("\(model.completedCount) completed")
            if model.failedCount > 0 {
                Text("\(model.failedCount) failed")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private func gridMetrics(for containerWidth: CGFloat) -> (columns: [GridItem], itemWidth: CGFloat, itemHeight: CGFloat) {
        let availableWidth = max(containerWidth - (Layout.horizontalPadding * 2), Layout.minTileWidth)
        let columnCount = max(Int((availableWidth + Layout.columnSpacing) / (Layout.minTileWidth + Layout.columnSpacing)), 1)
        let resolvedWidth = min(
            Layout.maxTileWidth,
            floor((availableWidth - (CGFloat(columnCount - 1) * Layout.columnSpacing)) / CGFloat(columnCount))
        )
        let columns = Array(repeating: GridItem(.fixed(resolvedWidth), spacing: Layout.columnSpacing), count: columnCount)
        return (columns, resolvedWidth, floor(resolvedWidth * 0.75))
    }
}

private struct ImageGridTile: View {
    let item: QueueItem
    let isProcessing: Bool
    let onRemove: () -> Void
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let contentPadding: CGFloat = 12
        static let infoHeight: CGFloat = 104
        static let removeButtonSize: CGFloat = 24
    }

    var body: some View {
        GeometryReader { proxy in
            let tileShape = RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)

            ZStack {
                tileShape
                    .fill(AppTheme.tileFill)

                imageLayer(size: proxy.size)
            }
            .clipShape(tileShape)
            .overlay(alignment: .top) {
                topControls
                    .padding(Layout.contentPadding)
            }
            .overlay(alignment: .bottomLeading) {
                bottomInfo
            }
            .overlay(tileShape.strokeBorder(AppTheme.subtleStroke, lineWidth: 1))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func imageLayer(size: CGSize) -> some View {
        Group {
            if let image = NSImage(contentsOf: item.asset.fileURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipped()
        .allowsHitTesting(false)
    }

    private var statusColor: Color {
        switch item.status {
        case .pending:
            return .secondary
        case .processing:
            return .orange
        case .done:
            return .secondary
        case .failed:
            return .red
        case .cancelled:
            return .secondary
        }
    }

    private var topControls: some View {
        HStack(alignment: .top, spacing: 8) {
            statusBadge

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: Layout.removeButtonSize, height: Layout.removeButtonSize)
                    .background(.regularMaterial, in: Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(isProcessing)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .processing:
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.75)
                .frame(width: 10, height: 10)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.regularMaterial, in: Capsule(style: .continuous))
        default:
            Text(item.status.label)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.regularMaterial, in: Capsule(style: .continuous))
                .foregroundStyle(statusColor)
        }
    }

    private var bottomInfo: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.45),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.asset.filename)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(item.asset.pixelWidth) × \(item.asset.pixelHeight)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.9))

                Text(footerDetail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .padding(Layout.contentPadding)
        }
        .frame(maxWidth: .infinity, minHeight: Layout.infoHeight, maxHeight: Layout.infoHeight, alignment: .bottom)
    }

    private var footerDetail: String {
        let base = "\(item.asset.format.displayName) • \(Formatters.fileSize(item.asset.fileSize))"

        guard case let .done(bytesWritten) = item.status,
              let bytesWritten,
              item.asset.fileSize > 0
        else {
            return base
        }

        let delta = Double(item.asset.fileSize - bytesWritten) / Double(item.asset.fileSize)
        let percent = Int((abs(delta) * 100).rounded())

        if delta >= 0 {
            return "\(base) • \(percent)% smaller"
        } else {
            return "\(base) • \(percent)% larger"
        }
    }
}
