# beautiful_mermaid

Render beautiful [Mermaid](https://mermaid.js.org/) diagrams in Flutter. Powered by
[beautiful-mermaid](https://github.com/lukilabs/beautiful-mermaid) — a zero-DOM,
pure TypeScript Mermaid renderer that outputs clean, styled SVGs.

Supports **flowcharts**, **sequence diagrams**, **state diagrams**, **class diagrams**,
and **ER diagrams** with **15 built-in themes** and **pan/zoom controls**.

## Quickstart

### 1. Add the dependency

```yaml
dependencies:
  beautiful_mermaid: ^0.1.0
```

### 2. Drop in a diagram

```dart
import 'package:beautiful_mermaid/beautiful_mermaid.dart';

MermaidDiagram(
  source: 'graph TD; A --> B --> C',
  colors: MermaidTheme.tokyoNight,
)
```

That's it — the widget handles rendering, JS library loading, and pan/zoom automatically.

## How It Works

On **Android, iOS, and macOS**, `MermaidDiagram` embeds a lightweight WebView that loads
the beautiful-mermaid JS library once from CDN. On **web**, it uses an `HtmlElementView`
with an iframe and `dart:js_interop` — no WebView needed.

Subsequent diagram or theme changes are applied via JavaScript calls —
**no page reloads, no flashing**.

## Pan & Zoom

Pan and zoom is enabled by default. Controls include:

| Gesture | Action |
|---|---|
| **Scroll wheel / trackpad** | Zoom in/out (centered on cursor) |
| **Click and drag** | Pan the diagram |
| **Pinch** (touch) | Zoom in/out |
| **Double-click / double-tap** | Fit to screen |
| **Floating buttons** | +, −, fit-to-screen |

### Disable pan/zoom

```dart
MermaidDiagram(
  source: 'graph TD; A --> B',
  panZoom: false,
)
```

### Move the controls

```dart
MermaidDiagram(
  source: 'graph TD; A --> B',
  controlsPosition: MermaidControlsPosition.topRight,
)
```

Available positions: `topLeft`, `topCenter`, `topRight`, `centerLeft`, `centerRight`,
`bottomLeft`, `bottomCenter`, `bottomRight`.

## API Reference

### MermaidDiagram

| Parameter | Type | Default | Description |
|---|---|---|---|
| `source` | `String` | **required** | Mermaid diagram source text |
| `colors` | `MermaidColors` | `MermaidTheme.zincLight` | Color theme |
| `font` | `String` | `'Inter'` | Font family for diagram text |
| `padding` | `double` | `40` | Padding around the diagram (px) |
| `transparent` | `bool` | `false` | Transparent background |
| `panZoom` | `bool` | `true` | Enable pan/zoom controls |
| `controlsPosition` | `MermaidControlsPosition` | `bottomRight` | Position of +/−/fit buttons |
| `onRendered` | `VoidCallback?` | `null` | Called when rendering completes |
| `onError` | `ValueChanged<String>?` | `null` | Called on render error |
| `loading` | `Widget?` | `CircularProgressIndicator` | Custom loading widget |
| `errorBuilder` | `Widget Function(String)?` | `null` | Custom error widget |

### MermaidColors

Define custom color schemes:

```dart
MermaidDiagram(
  source: 'graph LR; A --> B',
  colors: MermaidColors(
    bg: Color(0xFF1a1a2e),
    fg: Color(0xFFe0e0e0),
    line: Color(0xFF404060),
    accent: Color(0xFF00d2ff),
    muted: Color(0xFF6c7086),
    surface: Color(0xFF252540),
    border: Color(0xFF353560),
  ),
)
```

Only `bg` and `fg` are required — they produce a clean monochrome diagram. The optional
colors (`line`, `accent`, `muted`, `surface`, `border`) add richer visual hierarchy.

## Themes

15 built-in themes are available via `MermaidTheme`:

| Theme | Constant |
|---|---|
| Zinc Light | `MermaidTheme.zincLight` |
| Zinc Dark | `MermaidTheme.zincDark` |
| Tokyo Night | `MermaidTheme.tokyoNight` |
| Tokyo Night Storm | `MermaidTheme.tokyoNightStorm` |
| Tokyo Night Light | `MermaidTheme.tokyoNightLight` |
| Catppuccin Mocha | `MermaidTheme.catppuccinMocha` |
| Catppuccin Latte | `MermaidTheme.catppuccinLatte` |
| Nord | `MermaidTheme.nord` |
| Nord Light | `MermaidTheme.nordLight` |
| Dracula | `MermaidTheme.dracula` |
| GitHub Light | `MermaidTheme.githubLight` |
| GitHub Dark | `MermaidTheme.githubDark` |
| Solarized Light | `MermaidTheme.solarizedLight` |
| Solarized Dark | `MermaidTheme.solarizedDark` |
| One Dark | `MermaidTheme.oneDark` |

Access all themes as a map:

```dart
// Iterate over all themes
for (final entry in MermaidTheme.all.entries) {
  print('${entry.key}: ${entry.value}');
}

// Look up by name
final colors = MermaidTheme.all['tokyo-night']!;
```

## Diagram Types

### Flowchart

```dart
MermaidDiagram(
  source: '''graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action]
    B -->|No| D[Other Action]''',
  colors: MermaidTheme.catppuccinMocha,
)
```

### Sequence Diagram

```dart
MermaidDiagram(
  source: '''sequenceDiagram
    participant A as Client
    participant B as Server
    A->>B: Request
    B-->>A: Response''',
  colors: MermaidTheme.nord,
)
```

### State Diagram

```dart
MermaidDiagram(
  source: '''stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : fetch()
    Loading --> Success : done
    Loading --> Error : fail''',
  colors: MermaidTheme.dracula,
)
```

### Class Diagram

```dart
MermaidDiagram(
  source: '''classDiagram
    class Animal {
      +String name
      +makeSound() void
    }
    class Dog {
      +fetch() void
    }
    Animal <|-- Dog''',
  colors: MermaidTheme.githubDark,
)
```

### ER Diagram

```dart
MermaidDiagram(
  source: '''erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains''',
  colors: MermaidTheme.solarizedDark,
)
```

## Platform Setup

The JS library is loaded from CDN, so **internet access is required** on first load.
Each platform has a different rendering backend:

| Platform | Backend | Notes |
|---|---|---|
| **Android** | WebView (`webview_flutter`) | Needs `INTERNET` permission |
| **iOS** | WKWebView (`webview_flutter`) | Works out of the box |
| **macOS** | WKWebView (`webview_flutter`) | Needs network entitlement |
| **Web** | `HtmlElementView` + iframe | No WebView — uses `dart:js_interop` directly |
| **Windows/Linux** | Not supported | `webview_flutter` has no implementation |

### Android

Add internet permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- ... -->
</manifest>
```

### iOS

No additional configuration needed.

### macOS

macOS apps are sandboxed. Enable outgoing network connections in **both** entitlement files:

**`macos/Runner/DebugProfile.entitlements`** and **`macos/Runner/Release.entitlements`:**
```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Web

No additional configuration needed. The package automatically uses an `HtmlElementView`
with an iframe and communicates via `postMessage` — no WebView plugin required.

## Tips

- **Avoid using `ValueKey` on `MermaidDiagram`** — this forces the widget to recreate the
  rendering context on every change. The widget already handles source/theme updates
  efficiently via JavaScript calls.

- **The first render takes slightly longer** because the JS library loads from CDN. After
  that, all updates are near-instant.

- **Custom loading widget:**
  ```dart
  MermaidDiagram(
    source: 'graph TD; A --> B',
    loading: Center(child: Text('Rendering...')),
  )
  ```

- **Error handling:**
  ```dart
  MermaidDiagram(
    source: invalidSource,
    onError: (error) => debugPrint('Mermaid error: $error'),
    errorBuilder: (error) => Center(child: Text('Failed: $error')),
  )
  ```

## License

MIT — see [LICENSE](LICENSE).
