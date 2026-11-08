import XCTest
import CardTestSupport
@testable import HedonismUploader

/// Card detection against real mounts, using attached disk images in place of SD cards.
@MainActor
final class VolumeWatcherTests: XCTestCase {
    private var cards: [DiskImageCard] = []
    private var defaults: UserDefaults!
    private var permissions: FolderPermissions!
    private var watcher: VolumeWatcher!

    override func setUpWithError() throws {
        let suite = "VolumeWatcherTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: suite) }
        permissions = FolderPermissions(defaults: defaults)
        watcher = VolumeWatcher(permissions: permissions)
    }

    override func tearDownWithError() throws {
        watcher.stop()
        for card in cards { try card.detach(force: true) }
        cards = []
    }

    private func insertCard(format: DiskImageCard.Format = .fat32, options: DiskImageCard.AttachOptions = []) throws -> DiskImageCard {
        let card = try DiskImageCard(format: format, options: options)
        cards.append(card)
        return card
    }

    func testRecognisesAGrantedCardWithDCIMAndNothingElse() throws {
        let card = try insertCard()
        let blank = try insertCard()
        try FileManager.default.removeItem(at: try blank.root().appendingPathComponent("DCIM"))
        try permissions.remember(try card.root())
        try permissions.remember(try blank.root())

        XCTAssertTrue(VolumeWatcher.isRemovableCameraCard(try card.root(), permissions: permissions))
        XCTAssertFalse(VolumeWatcher.isRemovableCameraCard(try blank.root(), permissions: permissions), "a removable volume without DCIM is not a camera card")
        XCTAssertFalse(VolumeWatcher.isRemovableCameraCard(URL(fileURLWithPath: "/"), permissions: permissions), "the boot volume is never a card")
    }

    func testIgnoresACardTheUserHasNotGrantedYet() throws {
        let card = try insertCard()
        XCTAssertFalse(VolumeWatcher.isRemovableCameraCard(try card.root(), permissions: permissions))
        try permissions.remember(try card.root())
        XCTAssertTrue(VolumeWatcher.isRemovableCameraCard(try card.root(), permissions: permissions))
    }

    func testRecognisesALockedCard() throws {
        let card = try insertCard()
        try card.add("DSC00001.ARW")
        try permissions.remember(try card.root())
        try card.reattach(options: .readOnly)
        XCTAssertTrue(VolumeWatcher.isRemovableCameraCard(try card.root(), permissions: permissions))
    }

    func testListsMountedCardsAndSkipsHiddenVolumes() throws {
        let visible = try insertCard(format: .exFAT)
        let hidden = try insertCard(options: .hidden)
        try permissions.remember(try visible.root())
        try permissions.remember(try hidden.root())

        let mounted = VolumeWatcher.mountedCards(permissions: permissions)
        XCTAssertTrue(mounted.contains(try visible.root()))
        XCTAssertFalse(mounted.contains(try hidden.root()), "volumes mounted nobrowse stay out of the card list")
    }

    func testReportsAGrantedCardWhenItIsInserted() throws {
        let card = try insertCard()
        try card.add("DSC00001.ARW")
        try permissions.remember(try card.root())
        try card.detach()

        let reported = expectation(description: "card reported")
        var volumes: [URL] = []
        watcher.start { volume in
            volumes.append(volume)
            reported.fulfill()
        }
        let root = try card.attach()

        wait(for: [reported], timeout: 10)
        XCTAssertEqual(volumes, [root])
    }

    func testStaysQuietForAnInsertedVolumeWithoutDCIM() throws {
        let card = try insertCard()
        try FileManager.default.removeItem(at: try card.root().appendingPathComponent("DCIM"))
        try permissions.remember(try card.root())
        try card.detach()

        let reported = expectation(description: "card reported")
        reported.isInverted = true
        watcher.start { _ in reported.fulfill() }
        try card.attach()

        wait(for: [reported], timeout: 3)
    }

    func testEjectUnmountsTheCard() throws {
        let card = try insertCard()
        let root = try card.root()

        try VolumeWatcher.eject(root)

        XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
        XCTAssertFalse(card.isAttached)
    }
}
