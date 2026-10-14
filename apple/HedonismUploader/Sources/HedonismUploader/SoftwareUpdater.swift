import AppKit

#if SPARKLE
import Sparkle

/// Sparkle updates for the Developer ID build. The Mac App Store build compiles without
/// SPARKLE and gets updates from the App Store instead.
@MainActor
final class SoftwareUpdater: ObservableObject {
    private let controller = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    @Published private(set) var canCheckForUpdates = false

    init() {
        controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        NSApplication.shared.activate()
        controller.checkForUpdates(nil)
    }
}
#endif
