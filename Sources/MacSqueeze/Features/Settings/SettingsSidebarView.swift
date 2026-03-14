import SwiftUI

struct SettingsSidebarView: View {
    @ObservedObject var model: AppModel
    @FocusState private var focusedField: Field?
    @State private var draftQuality = 0.82
    @State private var resizeValueText = ""

    private enum Field: Hashable {
        case resizeValue
    }

    private enum Layout {
        static let sectionSpacing: CGFloat = 10
        static let sectionPadding = EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        static let footerHeight: CGFloat = 92
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    exportSection

                    Divider()
                    resizeSection

                    Divider()
                    outputSection
                }
                .padding(.top, 2)
                .padding(.bottom, 8)
                .padding(.bottom, Layout.footerHeight)
            }

            stickyExportButton
        }
        .background(AppTheme.sidebarFill)
        .onAppear {
            syncDraftsFromModel()
        }
        .onChange(of: model.settings.quality) {
            draftQuality = model.settings.quality
        }
        .onChange(of: model.settings.resizeValue) {
            if focusedField == .resizeValue {
                return
            }
            resizeValueText = formattedResizeValue(model.settings.resizeValue)
        }
        .onChange(of: focusedField) { _, newValue in
            if newValue != .resizeValue {
                commitResizeValue()
            }
        }
    }

    private var exportSection: some View {
        sidebarSection("Format") {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                field("Format") {
                    Picker("Format", selection: $model.settings.outputFormat) {
                        ForEach(ImageFormat.supportedOutputFormats) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: model.settings.outputFormat) {
                        model.settings.normalize()
                    }
                }

                if model.settings.availableCompressionModes.count > 1 {
                    field("Compression") {
                        Picker("Compression", selection: $model.settings.compressionMode) {
                            ForEach(model.settings.availableCompressionModes) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if model.settings.outputFormat.supportsLossyCompression,
                   model.settings.compressionMode == .lossy {
                    VStack(alignment: .leading, spacing: 6) {
                        sidebarRow("Quality", "\(Int(draftQuality * 100))%")
                        Slider(
                            value: Binding(
                                get: { draftQuality },
                                set: { draftQuality = $0 }
                            ),
                            in: 0.1...1.0,
                            onEditingChanged: commitQuality
                        )
                    }
                }
            }
        }
    }

    private var resizeSection: some View {
        sidebarSection("Resize") {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                field("Mode") {
                    Picker("Mode", selection: $model.settings.resizeMode) {
                        ForEach(ResizeMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                if model.settings.resizeMode != .none {
                    field("Value") {
                        HStack(spacing: 8) {
                            TextField("Value", text: $resizeValueText)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .resizeValue)
                                .onSubmit(commitResizeValue)
                            Text(resizeUnitLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .leading)
                        }
                    }

                    if model.settings.resizeMode != .percentage && model.settings.resizeMode != .longestEdge {
                        Toggle("Preserve aspect ratio", isOn: $model.settings.preserveAspectRatio)
                            .toggleStyle(.switch)
                    }
                }
            }
        }
    }

    private var outputSection: some View {
        sidebarSection("Output") {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(outputFolderLabel)
                        .font(.caption)
                        .foregroundStyle(outputFolderColor)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("Select Folder") {
                        model.chooseExportDirectory()
                    }
                }

                field("Suffix") {
                    TextField("-optimized", text: $model.settings.filenameSuffix)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var stickyExportButton: some View {
        Button {
            model.exportBatch()
        } label: {
            HStack(spacing: 8) {
                if model.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(model.isProcessing ? "Processing..." : "Export Batch")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(model.canExport == false)
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .bottom)
    }

    private func sidebarSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text(title)
                .font(.headline)

            content()
        }
        .padding(Layout.sectionPadding)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func sidebarRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }

    private var outputFolderLabel: String {
        model.exportDirectory?.lastPathComponent ?? "Not selected"
    }

    private var outputFolderColor: Color {
        model.exportDirectory == nil ? .secondary : .primary
    }

    private var resizeUnitLabel: String {
        switch model.settings.resizeMode {
        case .none:
            return ""
        case .width, .height, .longestEdge:
            return "px"
        case .percentage:
            return "%"
        }
    }

    private func syncDraftsFromModel() {
        draftQuality = model.settings.quality
        resizeValueText = formattedResizeValue(model.settings.resizeValue)
    }

    private func commitQuality(_ isEditing: Bool) {
        if isEditing {
            return
        }
        model.settings.quality = draftQuality
    }

    private func commitResizeValue() {
        let trimmed = resizeValueText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.isEmpty == false else {
            resizeValueText = formattedResizeValue(model.settings.resizeValue)
            return
        }

        guard let number = Self.resizeValueFormatter.number(from: trimmed)?.doubleValue else {
            resizeValueText = formattedResizeValue(model.settings.resizeValue)
            return
        }

        model.settings.resizeValue = number
        resizeValueText = formattedResizeValue(number)
    }

    private func formattedResizeValue(_ value: Double) -> String {
        Self.resizeValueFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static let resizeValueFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}
