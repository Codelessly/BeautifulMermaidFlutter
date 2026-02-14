import 'dart:convert';
import 'dart:ui';

/// Position of the pan/zoom control buttons.
enum MermaidControlsPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Color configuration for a Mermaid diagram.
///
/// Only [bg] and [fg] are required — they produce a clean mono diagram.
/// Optional enrichment colors ([line], [accent], [muted], [surface], [border])
/// add richer visual hierarchy.
class MermaidColors {
  final Color bg;
  final Color fg;
  final Color? line;
  final Color? accent;
  final Color? muted;
  final Color? surface;
  final Color? border;

  const MermaidColors({
    required this.bg,
    required this.fg,
    this.line,
    this.accent,
    this.muted,
    this.surface,
    this.border,
  });

  /// Serialize as a JS object literal string: `bg: "#fff", fg: "#000"`.
  String toJsObjectEntries() {
    final entries = toMap().entries
        .map((e) => '${e.key}: ${jsonEncode(e.value)}')
        .join(', ');
    return entries;
  }

  /// Convert to a map of hex color strings.
  Map<String, String> toMap() {
    return {
      'bg': colorToHex(bg),
      'fg': colorToHex(fg),
      if (line != null) 'line': colorToHex(line!),
      if (accent != null) 'accent': colorToHex(accent!),
      if (muted != null) 'muted': colorToHex(muted!),
      if (surface != null) 'surface': colorToHex(surface!),
      if (border != null) 'border': colorToHex(border!),
    };
  }

  /// Convert a [Color] to a hex string like `#1a1b26`.
  static String colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MermaidColors &&
          bg == other.bg &&
          fg == other.fg &&
          line == other.line &&
          accent == other.accent &&
          muted == other.muted &&
          surface == other.surface &&
          border == other.border;

  @override
  int get hashCode => Object.hash(bg, fg, line, accent, muted, surface, border);
}

/// Built-in themes matching beautiful-mermaid's 15 theme presets.
abstract final class MermaidTheme {
  static const zincLight = MermaidColors(
    bg: Color(0xFFFFFFFF),
    fg: Color(0xFF27272A),
  );

  static const zincDark = MermaidColors(
    bg: Color(0xFF18181B),
    fg: Color(0xFFFAFAFA),
  );

  static const tokyoNight = MermaidColors(
    bg: Color(0xFF1a1b26),
    fg: Color(0xFFa9b1d6),
    line: Color(0xFF3d59a1),
    accent: Color(0xFF7aa2f7),
    muted: Color(0xFF565f89),
  );

  static const tokyoNightStorm = MermaidColors(
    bg: Color(0xFF24283b),
    fg: Color(0xFFa9b1d6),
    line: Color(0xFF3d59a1),
    accent: Color(0xFF7aa2f7),
    muted: Color(0xFF565f89),
  );

  static const tokyoNightLight = MermaidColors(
    bg: Color(0xFFd5d6db),
    fg: Color(0xFF343b58),
    line: Color(0xFF34548a),
    accent: Color(0xFF34548a),
    muted: Color(0xFF9699a3),
  );

  static const catppuccinMocha = MermaidColors(
    bg: Color(0xFF1e1e2e),
    fg: Color(0xFFcdd6f4),
    line: Color(0xFF585b70),
    accent: Color(0xFFcba6f7),
    muted: Color(0xFF6c7086),
  );

  static const catppuccinLatte = MermaidColors(
    bg: Color(0xFFeff1f5),
    fg: Color(0xFF4c4f69),
    line: Color(0xFF9ca0b0),
    accent: Color(0xFF8839ef),
    muted: Color(0xFF9ca0b0),
  );

  static const nord = MermaidColors(
    bg: Color(0xFF2e3440),
    fg: Color(0xFFd8dee9),
    line: Color(0xFF4c566a),
    accent: Color(0xFF88c0d0),
    muted: Color(0xFF616e88),
  );

  static const nordLight = MermaidColors(
    bg: Color(0xFFeceff4),
    fg: Color(0xFF2e3440),
    line: Color(0xFFaab1c0),
    accent: Color(0xFF5e81ac),
    muted: Color(0xFF7b88a1),
  );

  static const dracula = MermaidColors(
    bg: Color(0xFF282a36),
    fg: Color(0xFFf8f8f2),
    line: Color(0xFF6272a4),
    accent: Color(0xFFbd93f9),
    muted: Color(0xFF6272a4),
  );

  static const githubLight = MermaidColors(
    bg: Color(0xFFffffff),
    fg: Color(0xFF1f2328),
    line: Color(0xFFd1d9e0),
    accent: Color(0xFF0969da),
    muted: Color(0xFF59636e),
  );

  static const githubDark = MermaidColors(
    bg: Color(0xFF0d1117),
    fg: Color(0xFFe6edf3),
    line: Color(0xFF3d444d),
    accent: Color(0xFF4493f8),
    muted: Color(0xFF9198a1),
  );

  static const solarizedLight = MermaidColors(
    bg: Color(0xFFfdf6e3),
    fg: Color(0xFF657b83),
    line: Color(0xFF93a1a1),
    accent: Color(0xFF268bd2),
    muted: Color(0xFF93a1a1),
  );

  static const solarizedDark = MermaidColors(
    bg: Color(0xFF002b36),
    fg: Color(0xFF839496),
    line: Color(0xFF586e75),
    accent: Color(0xFF268bd2),
    muted: Color(0xFF586e75),
  );

  static const oneDark = MermaidColors(
    bg: Color(0xFF282c34),
    fg: Color(0xFFabb2bf),
    line: Color(0xFF4b5263),
    accent: Color(0xFFc678dd),
    muted: Color(0xFF5c6370),
  );

  /// All built-in themes indexed by name.
  static const Map<String, MermaidColors> all = {
    'zinc-light': zincLight,
    'zinc-dark': zincDark,
    'tokyo-night': tokyoNight,
    'tokyo-night-storm': tokyoNightStorm,
    'tokyo-night-light': tokyoNightLight,
    'catppuccin-mocha': catppuccinMocha,
    'catppuccin-latte': catppuccinLatte,
    'nord': nord,
    'nord-light': nordLight,
    'dracula': dracula,
    'github-light': githubLight,
    'github-dark': githubDark,
    'solarized-light': solarizedLight,
    'solarized-dark': solarizedDark,
    'one-dark': oneDark,
  };
}
