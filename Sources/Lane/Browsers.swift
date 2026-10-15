import AppKit

struct Browser: Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL

    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
}

enum Browsers {
    /// Apps that claim https links but aren't browsers: other link pickers, and chat apps.
    private static let notBrowsers: Set<String> = [
        "com.sindresorhus.Velja",
        "net.kassett.finicky",
        "com.choosyosx.Choosy",
        "com.browserosaurus",
        "com.openai.codex",
        "com.openai.chat",
    ]

    /// Every app that says it can open https links, minus Lane, non-browsers,
    /// and tool-bundled copies tucked inside hidden folders (like ~/.hermes).
    static func installed() -> [Browser] {
        let probe = URL(string: "https://example.com")!
        var seen = Set<String>()
        return NSWorkspace.shared.urlsForApplications(toOpen: probe)
            .compactMap { url -> Browser? in
                guard let id = Bundle(url: url)?.bundleIdentifier,
                      id != Bundle.main.bundleIdentifier,
                      !notBrowsers.contains(id),
                      !url.pathComponents.contains(where: { $0.hasPrefix(".") }),
                      seen.insert(id).inserted
                else { return nil }
                let name = FileManager.default.displayName(atPath: url.path)
                    .replacingOccurrences(of: ".app", with: "")
                return Browser(id: id, name: name, url: url)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func browser(withID id: String) -> Browser? {
        installed().first { $0.id == id }
    }

    static func open(_ urls: [URL], in browser: Browser) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(urls, withApplicationAt: browser.url, configuration: configuration) { _, error in
            if let error { NSLog("Lane: could not open links in \(browser.name): \(error)") }
        }
    }

    // MARK: System default browser

    static var laneIsSystemDefault: Bool {
        guard let handler = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) else {
            return false
        }
        return handler.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL
    }

    /// macOS asks the user to confirm this change.
    static func makeLaneSystemDefault() {
        let lane = Bundle.main.bundleURL
        NSWorkspace.shared.setDefaultApplication(at: lane, toOpenURLsWithScheme: "http") { error in
            if let error { NSLog("Lane: http default not changed: \(error)"); return }
            NSWorkspace.shared.setDefaultApplication(at: lane, toOpenURLsWithScheme: "https") { error in
                if let error { NSLog("Lane: https default not changed: \(error)") }
            }
        }
    }
}
