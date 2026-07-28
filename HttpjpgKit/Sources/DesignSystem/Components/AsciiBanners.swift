import Foundation

/// ASCII furniture, ported verbatim from
/// `packages/ui/src/components/ascii-art/banners.ts`.
///
/// These strings *are* the brand. Keep them byte-identical to the web so the
/// two surfaces read as the same site.
public enum Ascii {
    public static let sparkles = "·°•. ⋆ ✦ ⋆ .•°·"
    public static let tape = "▰▰▰▱▱▱▰▰▰▱▱▱▰▰▰"

    public static let dividerStars = "*ੈ✩‧₊˚༺☆༻*ੈ✩‧₊˚"
    public static let dividerDots = "· ─ · ─ · ─ · ─ ·"
    public static let dividerWave = "～～～～～～～～"
    public static let dividerArrows = "»»»»»———»»»»»"
    public static let dividerMusic = "･ﾟ⋆ ♪ ♫ ･ﾟ⋆"

    public static let notFound = """
        /\\___/\\
       ( o   o )
       (  =^=  )    404
        (--m-m-)   not_found
    """

    public static let error = """
       ___________
      | _________ |
      ||  500    ||
      ||  ERROR  ||
      ||_________||
      |___________|
      /::::::::::::\\
     /::=========::\\
     ~~~~~~~~~~~~~~~
    """

    public static let offline = """
      ┌─[ no signal ]─┐
      │ · · · · · · · │
      │ · . · · . · · │
      │ . · · · · . · │
      └───────────────┘
    """

    public static let ghost = """
       .-.
      ( o.o )
       > ^ <
    """

    public static let empty = """
      ·°•. ⋆ ✦ ⋆ .•°·

           .-.
          ( ∅.∅ )
           > ^ <

      nothing to see here

      ·°•. ⋆ ✦ ⋆ .•°·
    """
}
