import Foundation

/// App-scoped bookmarks persist grants; implicit bookmarks transfer a live grant to XPC.
struct FolderPermissions {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private func key(_ url: URL) -> String { "folderGrant." + url.standardizedFileURL.path }

    func remember(_ url: URL) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let data = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                                        includingResourceValuesForKeys: nil, relativeTo: nil)
        defaults.set(data, forKey: key(url))
    }

    func resolve(_ url: URL) throws -> URL {
        guard let data = defaults.data(forKey: key(url)) else {
            throw NSError(domain: "Cogsworth", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Select this folder with Upload now to grant access."])
        }
        var stale = false
        let resolved = try URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                               relativeTo: nil, bookmarkDataIsStale: &stale)
        if stale { try remember(resolved) }
        return resolved
    }
}
