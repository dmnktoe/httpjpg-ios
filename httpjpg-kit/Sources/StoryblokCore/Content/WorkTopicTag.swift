import Foundation

/// One entry in the CMS work-tag vocabulary. The stored `value` is what
/// Storyblok keeps on the story; `label` is what a visitor reads.
public struct WorkTopicTag: Hashable, Sendable {
    public enum Group: String, Sendable, CaseIterable {
        case discipline
        case language
        case framework
        case platform
        case tooling
        case kind
    }

    public let value: String
    public let label: String
    public let group: Group

    public static let catalog: [WorkTopicTag] = [
        .discipline("frontend", "Frontend"),
        .discipline("backend", "Backend"),
        .discipline("full-stack", "Full Stack"),
        .discipline("ui-design", "UI Design"),
        .discipline("ux-design", "UX Design"),
        .discipline("art-direction", "Art Direction"),
        .discipline("branding", "Branding"),
        .discipline("typography", "Typography"),
        .discipline("editorial", "Editorial"),
        .discipline("motion", "Motion"),
        .discipline("3d", "3D"),
        .discipline("illustration", "Illustration"),
        .discipline("photography", "Photography"),
        .discipline("sound-design", "Sound Design"),
        .discipline("accessibility", "Accessibility"),
        .discipline("performance", "Performance"),

        .language("typescript", "TypeScript"),
        .language("javascript", "JavaScript"),
        .language("swift", "Swift"),
        .language("python", "Python"),
        .language("php", "PHP"),
        .language("rust", "Rust"),
        .language("go", "Go"),
        .language("css", "CSS"),
        .language("html", "HTML"),
        .language("sql", "SQL"),
        .language("shell", "Shell"),
        .language("glsl", "GLSL"),

        .framework("react", "React"),
        .framework("next-js", "Next.js"),
        .framework("react-native", "React Native"),
        .framework("swiftui", "SwiftUI"),
        .framework("node-js", "Node.js"),
        .framework("astro", "Astro"),
        .framework("vue", "Vue"),
        .framework("svelte", "Svelte"),
        .framework("tailwind-css", "Tailwind CSS"),
        .framework("panda-css", "Panda CSS"),
        .framework("three-js", "Three.js"),
        .framework("gsap", "GSAP"),
        .framework("framer-motion", "Framer Motion"),

        .platform("web", "Web"),
        .platform("ios", "iOS"),
        .platform("macos", "macOS"),
        .platform("android", "Android"),
        .platform("desktop", "Desktop"),
        .platform("cli", "CLI"),
        .platform("print", "Print"),
        .platform("installation", "Installation"),

        .tooling("figma", "Figma"),
        .tooling("storyblok", "Storyblok"),
        .tooling("sanity", "Sanity"),
        .tooling("contentful", "Contentful"),
        .tooling("vercel", "Vercel"),
        .tooling("docker", "Docker"),
        .tooling("postgres", "PostgreSQL"),
        .tooling("supabase", "Supabase"),
        .tooling("cloudflare", "Cloudflare"),
        .tooling("github-actions", "GitHub Actions"),
        .tooling("playwright", "Playwright"),
        .tooling("storybook", "Storybook"),
        .tooling("turborepo", "Turborepo"),
        .tooling("ableton", "Ableton"),

        .kind("client-work", "Client Work"),
        .kind("personal", "Personal"),
        .kind("open-source", "Open Source"),
        .kind("experiment", "Experiment"),
        .kind("case-study", "Case Study"),
        .kind("collaboration", "Collaboration"),
        .kind("student-work", "Student Work"),
    ]

    private static let byValue: [String: WorkTopicTag] = {
        Dictionary(uniqueKeysWithValues: catalog.map { ($0.value, $0) })
    }()

    private static let catalogIndex: [String: Int] = {
        Dictionary(uniqueKeysWithValues: catalog.enumerated().map { ($0.element.value, $0.offset) })
    }()

    private static let groupOrder: [Group: Int] = {
        Dictionary(uniqueKeysWithValues: Group.allCases.enumerated().map { ($0.element, $0.offset) })
    }()

    public static func named(_ value: String) -> WorkTopicTag? {
        byValue[value]
    }

    /// Values outside the vocabulary are dropped rather than rendered as a raw
    /// slug, which is what makes retiring a tag safe.
    public static func resolve(_ values: [String]) -> [WorkTopicTag] {
        var seen = Set<String>()
        var resolved: [WorkTopicTag] = []
        for value in values {
            guard let tag = byValue[value], seen.insert(tag.value).inserted else { continue }
            resolved.append(tag)
        }
        return resolved.sorted { lhs, rhs in
            let groupDelta = (groupOrder[lhs.group] ?? 0) - (groupOrder[rhs.group] ?? 0)
            if groupDelta != 0 { return groupDelta < 0 }
            return (catalogIndex[lhs.value] ?? 0) < (catalogIndex[rhs.value] ?? 0)
        }
    }

    public static func labels(for values: [String]) -> [String] {
        resolve(values).map(\.label)
    }

    private static func discipline(_ value: String, _ label: String) -> WorkTopicTag {
        WorkTopicTag(value: value, label: label, group: .discipline)
    }

    private static func language(_ value: String, _ label: String) -> WorkTopicTag {
        WorkTopicTag(value: value, label: label, group: .language)
    }

    private static func framework(_ value: String, _ label: String) -> WorkTopicTag {
        WorkTopicTag(value: value, label: label, group: .framework)
    }

    private static func platform(_ value: String, _ label: String) -> WorkTopicTag {
        WorkTopicTag(value: value, label: label, group: .platform)
    }

    private static func tooling(_ value: String, _ label: String) -> WorkTopicTag {
        WorkTopicTag(value: value, label: label, group: .tooling)
    }

    private static func kind(_ value: String, _ label: String) -> WorkTopicTag {
        WorkTopicTag(value: value, label: label, group: .kind)
    }
}
