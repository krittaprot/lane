import Foundation

enum Settings {
    private static let browserKey = "browserID"

    /// The browser every link goes to. `nil` means show the picker for every link.
    static var browserID: String? {
        get { UserDefaults.standard.string(forKey: browserKey) }
        set { UserDefaults.standard.set(newValue, forKey: browserKey) }
    }
}
