import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: AppModel
    private enum Layout {
        static let sidebarWidth: CGFloat = 350
        static let titlebarInset: CGFloat = 10
        static let minimumContentWidth: CGFloat = 620
    }

    var body: some View {
        ZStack {
            AppTheme.canvas
                .ignoresSafeArea()

            if model.hasItems {
                queueScreen
            } else {
                EmptyStateView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
            }
        }
        .frame(minWidth: 980, minHeight: 640)
        .ignoresSafeArea(.container, edges: .top)
        .onDrop(of: [.fileURL], isTargeted: $model.isTargeted) { providers in
            model.importProviders(providers)
            return true
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if $0 == false { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var queueScreen: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                ImageGridView(model: model)
                    .frame(minWidth: Layout.minimumContentWidth, maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                SettingsSidebarView(model: model)
                    .frame(width: Layout.sidebarWidth)
            }

            titlebarActions
        }
    }

    private var titlebarActions: some View {
        HStack(spacing: 8) {
            Button("Add Images") {
                model.chooseFiles()
            }
            .buttonStyle(.bordered)

            Button("Clear") {
                model.clearQueue()
            }
            .buttonStyle(.bordered)
            .disabled(model.hasItems == false || model.isProcessing)
        }
        .padding(.top, Layout.titlebarInset)
        .padding(.trailing, Layout.sidebarWidth + Layout.titlebarInset)
    }
}

private struct EmptyStateView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Image(systemName: "photo.stack")
                    .opacity(model.isTargeted ? 0 : 1)
                    .foregroundStyle(.secondary)

                Image(systemName: "arrow.down.circle.fill")
                    .opacity(model.isTargeted ? 1 : 0)
                    .foregroundStyle(AppTheme.tint)
            }
            .font(.system(size: 38))
            .frame(width: 44, height: 44)

            Text("Drop images to start")
                .font(.title)
                .fontWeight(.semibold)

            Text("Import JPEG, PNG, HEIC, TIFF, or WebP and export the whole batch with one shared setup.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button("Add Images") {
                model.chooseFiles()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
