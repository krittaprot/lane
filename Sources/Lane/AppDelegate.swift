import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let picker = PickerController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "Lane")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    /// Links clicked anywhere arrive here once Lane is the default browser.
    func application(_ application: NSApplication, open urls: [URL]) {
        route(urls)
    }

    private func route(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let forcePicker = NSEvent.modifierFlags.contains(.option)
        if !forcePicker, let id = Settings.browserID, let browser = Browsers.browser(withID: id) {
            Browsers.open(urls, in: browser)
        } else {
            picker.show(urls: urls, browsers: Browsers.installed())
        }
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let header = NSMenuItem(title: "Open Links In", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        let ask = NSMenuItem(title: "Ask Every Time", action: #selector(chooseBrowser(_:)), keyEquivalent: "")
        ask.target = self
        ask.state = Settings.browserID == nil ? .on : .off
        menu.addItem(ask)

        for browser in Browsers.installed() {
            let item = NSMenuItem(title: browser.name, action: #selector(chooseBrowser(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = browser.id
            item.state = Settings.browserID == browser.id ? .on : .off
            let icon = browser.icon
            icon.size = NSSize(width: 16, height: 16)
            item.image = icon
            menu.addItem(item)
        }

        menu.addItem(.separator())

        if Browsers.laneIsSystemDefault {
            let done = NSMenuItem(title: "Lane Is Your Default Browser", action: nil, keyEquivalent: "")
            done.isEnabled = false
            menu.addItem(done)
        } else {
            let make = NSMenuItem(title: "Make Lane the Default Browser…", action: #selector(makeDefault), keyEquivalent: "")
            make.target = self
            menu.addItem(make)
        }

        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        let tip = NSMenuItem(title: "Hold ⌥ while clicking a link to pick a browser", action: nil, keyEquivalent: "")
        tip.isEnabled = false
        menu.addItem(tip)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Lane", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func chooseBrowser(_ sender: NSMenuItem) {
        Settings.browserID = sender.representedObject as? String
    }

    @objc private func makeDefault() {
        Browsers.makeLaneSystemDefault()
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Lane: login item not changed: \(error)")
        }
    }
}
