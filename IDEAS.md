# Ideen: nativer werden

Merkliste, noch nichts davon umgesetzt. Sortiert in der Reihenfolge, in der
man sie am besten abarbeitet: erst das Fundament, dann kleine sichtbare
Gewinne, dann die großen Brocken.

## 1. Mindestziel iOS 27

iOS 27 (und watchOS 27?) als Mindestziel. Damit fallen alle `#available`-Checks
weg (aktuell ~35), und alles Folgende kann neue APIs ohne Weichen nutzen.
Betrifft `Package.swift` (Platforms + swift-tools-version),
`Config/Shared.xcconfig`, `project.yml`, CLAUDE.md-Stack-Zeile, CI-Xcode.

## 2. Play/Pause-Wechsel

`.contentTransition(.symbolEffect(.replace))` im Mini-Player und im
Player-Screen. Ein paar Zeilen, sofort sichtbar.

## 3. Scroll-Effekte in der Work-Liste

`.scrollTransition` (Karten blenden beim Rein- und Rausscrollen leicht ein) und
`.visualEffect` (Bild-Parallax in der Karte). Reduce Motion beachten.

## 4. Übersetzen

`.translationPresentation` als System-Übersetzungsblatt über Work-Texten,
on-device, ohne API-Key. Klein und unabhängig; lohnt nur, wenn die Texte nicht
schon zweisprachig sind.

## 5. IndexedEntity

`WorkEntity` direkt in Spotlight; ersetzt die eigene `CSSearchableItem`-Logik in
`WorkSpotlightIndex`. Grundlage für Punkt 7 und dafür, dass Siri Works kennt.

## 6. Widgets: Feed mit Next-Button, StandBy

- `Button(intent:)` im Feed-Widget, blättert ohne App-Start zum nächsten Work.
- Dabei gleich prüfen, wie die Widgets in StandBy (Querformat am Ladegerät)
  wirken.

## 7. Apple Intelligence

Baut auf Punkt 5 auf.

- On-Screen-Awareness: `appEntityIdentifier` an der `NSUserActivity` der
  Detailseite („Schick das an …“).
- Visual Intelligence: per `IntentValueQuery` passende Works zu einem
  Bildschirmfoto finden.
- Foundation Models (on-device) als Offline-Fallback für die Ask-Suche oder für
  Kurz-Zusammenfassungen.

## 8. iPad

Läuft schon (`TARGETED_DEVICE_FAMILY = 1,2`), aber ohne eigenes Layout.
`NavigationSplitView` mit der Sidebar, freie Fenstergrößen, mehrere Fenster
(`UIApplicationSupportsMultipleScenes` ist aktuell `false`). Das adaptive Layout
ist die Grundlage für Punkt 9 und 10.

## 9. iPhone Duo

Foldable, außen ~5,4", innen ~7,6–7,8". Auf- und Zuklappen wechselt die Größe
live; das Layout muss das ohne State-Verlust überstehen. Innen das
iPad-mini-Layout aus Punkt 8 (Sidebar + Detail). Pencil-Support auf dem Duo.

## 10. Mac

„Designed for iPad“ auf Apple Silicon fast gratis, sobald das iPad-Layout steht;
sonst Mac Catalyst.

## 11. Apple TV

Der größte Brocken: neuer tvOS-Target, `DesignSystem` ist UIKit-gestützt und
müsste in Teilen tvOS-fähig werden. Etwas Eigenes aus unseren Daten statt einer
kleinen iPhone-App:

- **Top Shelf**: neueste Works als Karussell, Deeplink in die Detailseite.
- **Galerie-/Ambient-Modus**: langsamer Ken-Burns-Durchlauf durch alle
  Work-Bilder, Frame of the Day im Vollbild, dazu ASCII-Motive und
  Site-Status-Ticker.
- **Contact Sheet** als fokussierbares Raster mit Parallax-Postern.
- Musik-Player mit Video im Hintergrund.
