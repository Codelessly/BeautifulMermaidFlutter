import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import 'mermaid_theme.dart';
import 'shell_html.dart';

/// Renders a Mermaid diagram using beautiful-mermaid via a WebView.
///
/// Creates the WebView once and reuses it for all subsequent source/theme
/// changes by calling JavaScript directly — no page reloads, no flashing.
///
/// Supports all 5 diagram types: flowcharts, sequence diagrams, state diagrams,
/// class diagrams, and ER diagrams.
///
/// ```dart
/// MermaidDiagram(
///   source: 'graph TD; A --> B --> C',
///   colors: MermaidTheme.tokyoNight,
/// )
/// ```
class MermaidDiagram extends StatefulWidget {
  /// The Mermaid source text to render.
  final String source;

  /// Color theme for the diagram. Defaults to zinc light.
  final MermaidColors colors;

  /// Font family for diagram text. Defaults to `'Inter'`.
  final String font;

  /// Padding around the diagram in pixels. Defaults to `40`.
  final double padding;

  /// Whether to render with a transparent background.
  final bool transparent;

  /// When `true`, the diagram's own inline `style` directives and
  /// `%%{ init: { 'theme': ... } }%%` are preserved instead of being
  /// overridden by the [colors] theme. The [colors.bg] is still used for
  /// the page background. Defaults to `false`.
  final bool useSourceTheme;

  /// Whether to enable pan and zoom controls. Defaults to `true`.
  ///
  /// When enabled, the diagram supports:
  /// - **Mouse wheel / trackpad scroll** to zoom in/out
  /// - **Click and drag** to pan
  /// - **Pinch to zoom** on touch devices
  /// - **Double-click / double-tap** to fit view
  /// - **Floating +/−/fit buttons**
  final bool panZoom;

  /// Position of the pan/zoom control buttons.
  /// Defaults to [MermaidControlsPosition.bottomRight].
  final MermaidControlsPosition controlsPosition;

  /// Called when the diagram has finished rendering.
  final VoidCallback? onRendered;

  /// Called when an error occurs during rendering.
  final ValueChanged<String>? onError;

  /// Widget to show while the diagram is loading.
  final Widget? loading;

  /// Widget to show when an error occurs.
  final Widget Function(String error)? errorBuilder;

  const MermaidDiagram({
    super.key,
    required this.source,
    this.colors = MermaidTheme.zincLight,
    this.font = 'Inter',
    this.padding = 40,
    this.transparent = false,
    this.useSourceTheme = false,
    this.panZoom = true,
    this.controlsPosition = MermaidControlsPosition.bottomRight,
    this.onRendered,
    this.onError,
    this.loading,
    this.errorBuilder,
  });

  @override
  State<MermaidDiagram> createState() => _MermaidDiagramState();
}

class _MermaidDiagramState extends State<MermaidDiagram> {
  late final WebViewController _controller;
  bool _webViewReady = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _onMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _webViewReady = true;
            _renderViaJs();
          },
        ),
      );

    _trySetBackground();
    _loadAndInjectHtml();
  }

  Future<void> _loadAndInjectHtml() async {
    final jsContent = await rootBundle.loadString(jsAssetPath);
    if (!mounted) return;
    _controller.loadHtmlString(
      buildShellHtml(
        jsContent: jsContent,
        colors: widget.colors,
        panZoom: widget.panZoom,
        controlsPosition: widget.controlsPosition,
        usePostMessage: false,
      ),
    );
  }

  void _trySetBackground() async {
    try {
      await _controller.setBackgroundColor(widget.colors.bg);
    } on UnimplementedError catch (_) {}
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.colors != widget.colors ||
        oldWidget.font != widget.font ||
        oldWidget.padding != widget.padding ||
        oldWidget.transparent != widget.transparent) {
      _renderViaJs();
    }
  }

  Future<void> _renderViaJs() async {
    if (!_webViewReady) return;

    if (mounted) setState(() => _isLoading = true);

    final source = jsonEncode(widget.source);
    final bgHex = MermaidColors.colorToHex(widget.colors.bg);
    final String options;
    if (widget.useSourceTheme) {
      // Only pass bg (for page background) and non-color options.
      // Color styling comes from the diagram's own inline style directives.
      options =
          '{ bg: ${jsonEncode(bgHex)}, font: ${jsonEncode(widget.font)}, padding: ${widget.padding.toInt()}, transparent: ${widget.transparent} }';
    } else {
      options =
          '{ ${widget.colors.toJsObjectEntries()}, font: ${jsonEncode(widget.font)}, padding: ${widget.padding.toInt()}, transparent: ${widget.transparent} }';
    }

    final js = [
      'document.body.style.background = ${jsonEncode(bgHex)};',
      'render($source, $options);',
    ].join('\n');

    await _controller.runJavaScript(js);
  }

  void _onMessage(JavaScriptMessage message) {
    final data = jsonDecode(message.message) as Map<String, dynamic>;
    final type = data['type'] as String;

    switch (type) {
      case 'rendered':
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = null;
          });
        }
        widget.onRendered?.call();
      case 'error':
        final error = data['message'] as String;
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = error;
          });
        }
        widget.onError?.call(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: _controller),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: widget.colors.bg,
              child: widget.loading ??
                  Center(
                    child: CircularProgressIndicator(
                      color: widget.colors.accent ?? widget.colors.fg,
                    ),
                  ),
            ),
          ),
      ],
    );
  }
}
