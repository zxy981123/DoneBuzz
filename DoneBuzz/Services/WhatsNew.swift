import Foundation

/// Decides when the What's New sheet appears on its own.
///
/// Each batch of new features gets a release number. Bump `currentRelease` (and update the list in
/// `Strings.whatsNewItems`) whenever you ship features worth announcing. The App Store version is left
/// alone, so bug-fix updates do not pop the sheet.
enum WhatsNew {
    static let currentRelease = 2
    static let storageKey = "whatsNewSeenRelease"

    enum LaunchAction: Equatable {
        /// Show the sheet now.
        case show
        /// Brand-new install: nothing is "new" yet, so just remember this release.
        case recordSilently
        /// Already seen.
        case nothing
    }

    /// `seenRelease` is 0 when the sheet has never been seen. Someone who used the app before this
    /// screen existed has items saved, so they count as updating rather than installing fresh.
    static func launchAction(seenRelease: Int, hasExistingData: Bool, current: Int = currentRelease) -> LaunchAction {
        if seenRelease >= current { return .nothing }
        if seenRelease == 0 && !hasExistingData { return .recordSilently }
        return .show
    }
}
