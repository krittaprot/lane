import AppKit
import SwiftUI

/// A small floating window, shown at the pointer, that asks which browser should open a link.
final class PickerController: NSObject {
    private var panel: NSPanel?
    private var keyMonitor: Any?
    private var outsideClickMonitor: Any?
    private var urls: [URL] = []
    private var browsers: [Browser] = []

    func show(urls: [URL], browsers: [Browser]) {
        close()
        self.urls = urls
        self.browsers = browsers

        let view = PickerView(
            urls: urls,
            browsers: browsers,
            choose: { [weak self] in self?.choose($0) },
            copy: { [weak self] in self?.copyLinks() }
        )
        let hosting = NSHostingView(rootView: view)
        hosting.frame.size = hosting.fittingSize

        let panel = KeyPanel(
            contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
            // Non-activating, like Spotlight: it takes the keyboard without macOS having to
            // bring Lane forward, which macOS 14+ may refuse for a background app.
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.setFrameOrigin(origin(for: panel.frame.size))
        self.panel = panel

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event) == true ? nil : event
        }
        // Clicks in other apps never reach Lane's own event queue, so watch for them globally.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }

        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        for monitor in [keyMonitor, outsideClickMonitor].compactMap({ $0 }) {
            NSEvent.removeMonitor(monitor)
        }
        keyMonitor = nil
        outsideClickMonitor = nil
        panel?.orderOut(nil)
        panel = nil
    }

    private func choose(_ browser: Browser) {
        let urls = self.urls
        close()
        Browsers.open(urls, in: browser)
    }

    private func copyLinks() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(urls.map(\.absoluteString).joined(separator: "\n"), forType: .string)
        close()
    }

    /// Esc cancels, 1–9 pick a browser, Return picks the first one, ⌘C copies the link.
    private func handleKey(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 { close(); return true }
        if event.keyCode == 36 || event.keyCode == 76, let first = browsers.first { choose(first); return true }
        let characters = event.charactersIgnoringModifiers ?? ""
        if event.modifierFlags.contains(.command), characters == "c" { copyLinks(); return true }
        if let digit = Int(characters), (1...9).contains(digit), digit <= browsers.count {
            choose(browsers[digit - 1])
            return true
        }
        return false
    }

    /// Just below the pointer, kept fully on the pointer's screen.
    private func origin(for size: NSSize) -> NSPoint {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? NSRect(origin: .zero, size: size)
        let x = min(max(mouse.x - size.width / 2, bounds.minX + 8), bounds.maxX - size.width - 8)
        let y = min(max(mouse.y - size.height - 12, bounds.minY + 8), bounds.maxY - size.height - 8)
        return NSPoint(x: x, y: y)
    }
}

private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

private struct PickerView: View {
    let urls: [URL]
    let browsers: [Browser]
    let choose: (Browser) -> Void
    let copy: () -> Void

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(84), spacing: 4), count: max(1, min(browsers.count, 5)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).lineLimit(1)
                Text(urls.first?.absoluteString ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: 420, alignment: .leading)

            if browsers.isEmpty {
                Text("No browsers found.").foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                        Button { choose(browser) } label: {
                            BrowserTile(browser: browser, shortcut: index < 9 ? index + 1 : nil)
                        }
                        .buttonStyle(TileButtonStyle())
                    }
                }
            }

            HStack {
                Text("1–9 to pick · esc to cancel")
                Spacer()
                Button("Copy Link", action: copy).buttonStyle(.link)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.12)))
    }

    private var title: String {
        let host = urls.first?.host ?? urls.first?.lastPathComponent ?? "Link"
        return urls.count > 1 ? "\(host) and \(urls.count - 1) more" : host
    }
}

private struct BrowserTile: View {
    let browser: Browser
    let shortcut: Int?

    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: browser.icon).resizable().frame(width: 48, height: 48)
            Text(browser.name).font(.caption).lineLimit(1)
            Text(shortcut.map(String.init) ?? " ")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(width: 80)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct TileButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.16 : hovering ? 0.08 : 0))
            )
            .onHover { hovering = $0 }
    }
}
