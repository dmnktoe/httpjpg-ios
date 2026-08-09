/// StoryblokCore is its own target so the watch app can share the API client
/// and the decoded payloads without linking the blok renderers, which are
/// built on the iOS-only half of the design system. Re-exported so
/// `import StoryblokContent` still reaches the client and the models.
@_exported import StoryblokCore
