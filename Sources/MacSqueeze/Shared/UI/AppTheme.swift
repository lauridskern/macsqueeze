import AppKit
import SwiftUI

enum AppTheme {
    static let tint = Color(nsColor: NSColor.systemBlue)
    static let canvas = Color(nsColor: NSColor.windowBackgroundColor)
    static let sidebarFill = Color(nsColor: NSColor.windowBackgroundColor)
    static let tileFill = Color(nsColor: NSColor.controlBackgroundColor)
    static let subtleStroke = Color(nsColor: NSColor.separatorColor).opacity(0.55)
}
