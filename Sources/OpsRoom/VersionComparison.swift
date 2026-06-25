import Foundation

/// Semver-style comparison aligned with `packages/shared-types` `compareVersions`.
enum VersionComparison {
    /// Returns negative if `lhs` &lt; `rhs`, zero if equal, positive if `lhs` &gt; `rhs`.
    static func compare(_ lhs: String, _ rhs: String) -> Int {
        let a = parse(lhs)
        let b = parse(rhs)
        if a.major != b.major { return a.major - b.major }
        if a.minor != b.minor { return a.minor - b.minor }
        if a.patch != b.patch { return a.patch - b.patch }
        if a.prerelease == b.prerelease { return 0 }
        if a.prerelease.isEmpty { return 1 }
        if b.prerelease.isEmpty { return -1 }
        return a.prerelease.localizedStandardCompare(b.prerelease).rawValue
    }

    private struct Parts {
        let major: Int
        let minor: Int
        let patch: Int
        let prerelease: String
    }

    private static func parse(_ version: String) -> Parts {
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z.-]+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: trimmed,
                  range: NSRange(trimmed.startIndex..., in: trimmed)
              ),
              let majorRange = Range(match.range(at: 1), in: trimmed)
        else {
            return Parts(major: 0, minor: 0, patch: 0, prerelease: "")
        }
        let major = Int(trimmed[majorRange]) ?? 0
        let minor: Int = {
            guard match.numberOfRanges > 2,
                  let range = Range(match.range(at: 2), in: trimmed)
            else { return 0 }
            return Int(trimmed[range]) ?? 0
        }()
        let patch: Int = {
            guard match.numberOfRanges > 3,
                  let range = Range(match.range(at: 3), in: trimmed)
            else { return 0 }
            return Int(trimmed[range]) ?? 0
        }()
        let prerelease: String = {
            guard match.numberOfRanges > 4,
                  let range = Range(match.range(at: 4), in: trimmed)
            else { return "" }
            return String(trimmed[range])
        }()
        return Parts(major: major, minor: minor, patch: patch, prerelease: prerelease)
    }
}
