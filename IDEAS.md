# Ideen: nativer werden

Merkliste, noch nichts davon umgesetzt.

## Plattform

- **Mindestziel iOS 27** (und watchOS 27?). Damit fallen alle `#available`-Checks
  weg (aktuell ~35). Betrifft `Package.swift` (Platforms + swift-tools-version),
  `Config/Shared.xcconfig`, `project.yml`, CLAUDE.md-Stack-Zeile, CI-Xcode.

## Geräte

- **iPhone Duo** (Foldable, außen ~5,4", innen ~7,6–7,8"): Auf- und Zuklappen
  wechselt die Größe live. Layout muss das ohne State-Verlust überstehen, innen
  eher iPad-mini-Layout (Sidebar + Detail). Pencil-Support auf dem Duo.
- **iPad**: läuft schon (`TARGETED_DEVICE_FAMILY = 1,2`), aber ohne eigenes Layout.
  `NavigationSplitView` mit der Sidebar, freie Fenstergrößen (iPadOS 26),
  mehrere Fenster (`UIApplicationSupportsMultipleScenes` ist aktuell `false`).
- **Mac**: „Designed for iPad“ auf Apple Silicon fast gratis, sonst Mac Catalyst.
- **Vision Pro**: iPad-App läuft als Fenster; nativ später.
- **CarPlay**: passt zum Audio-Player (Audio-App-Entitlement, braucht Freigabe
  von Apple).
- **StandBy**: die Widgets prüfen, wie sie im Querformat am Ladegerät wirken.

## Apple TV

Etwas Eigenes aus unseren Daten statt einer kleinen iPhone-App:

- **Top Shelf**: neueste Works als Karussell, Deeplink in die Detailseite.
- **Galerie-/Ambient-Modus**: langsamer Ken-Burns-Durchlauf durch alle Work-Bilder,
  Frame of the Day im Vollbild, dazu ASCII-Motive und Site-Status-Ticker.
- **Contact Sheet** als fokussierbares Raster mit Parallax-Postern.
- Musik-Player mit Video im Hintergrund.

Neuer tvOS-Target; `DesignSystem` ist UIKit-gestützt und müsste in Teilen
tvOS-fähig werden.

## Apple Intelligence

- `IndexedEntity` für `WorkEntity` (siehe unten), damit Siri Works kennt.
- On-Screen-Awareness: `appEntityIdentifier` an der `NSUserActivity` der
  Detailseite („Schick das an …“).
- Visual Intelligence: per `IntentValueQuery` passende Works zu einem
  Bildschirmfoto finden.
- Foundation Models (on-device) als Offline-Fallback für die Ask-Suche oder für
  Kurz-Zusammenfassungen.

## Einzelne Punkte

- **Feed-Widget mit Next-Button**: `Button(intent:)` im Widget, blättert ohne
  App-Start zum nächsten Work.
- **IndexedEntity**: `WorkEntity` direkt in Spotlight; ersetzt die eigene
  `CSSearchableItem`-Logik in `WorkSpotlightIndex`.
- **Play/Pause-Wechsel**: `.contentTransition(.symbolEffect(.replace))` im
  Mini-Player und im Player-Screen.
- **Scroll-Effekte** in der Work-Liste: `.scrollTransition` (Karten blenden beim
  Rein- und Rausscrollen leicht ein) und `.visualEffect` (Bild-Parallax in der
  Karte). Reduce Motion beachten.
- **Accessibility-Rotor**: in VoiceOver nach Jahren in der Work-Liste und nach
  Abschnitten auf langen Seiten springen.
- **Übersetzen**: `.translationPresentation` als System-Übersetzungsblatt über
  Work-Texten, on-device, ohne API-Key.
