import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web/web.dart' as web;

import 'mermaid_theme.dart';
import 'shell_html.dart';

/// Counter to ensure unique view type IDs for each widget instance.
int _viewIdCounter = 0;

/// Renders a Mermaid diagram using beautiful-mermaid via an iframe.
///
/// On Flutter web, this uses [HtmlElementView] with an iframe instead of a
/// WebView. The beautiful-mermaid JS library runs directly in the iframe and
/// communicates with Dart via `postMessage`.
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
  late final String _viewType;
  late final web.HTMLIFrameElement _iframe;
  late final JSFunction _messageHandler;
  bool _ready = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    final id = _viewIdCounter++;
    _viewType = 'beautiful-mermaid-$id';

    _iframe = web.HTMLIFrameElement()
      ..style.setProperty('border', 'none')
      ..style.setProperty('width', '100%')
      ..style.setProperty('height', '100%');

    // Register the platform view factory.
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    // Listen for messages from the iframe.
    _messageHandler = _onWindowMessage.toJS;
    web.window.addEventListener('message', _messageHandler);

    _loadAndInjectHtml();
  }

  Future<void> _loadAndInjectHtml() async {
    final jsContent = await rootBundle.loadString(jsAssetPath);
    if (!mounted) return;
    // Set srcdoc after a microtask to ensure the iframe is in the DOM.
    Future.microtask(() {
      (_iframe as web.HTMLElement).setAttribute(
        'srcdoc',
        buildShellHtml(
          jsContent: jsContent,
          colors: widget.colors,
          panZoom: widget.panZoom,
          controlsPosition: widget.controlsPosition,
          usePostMessage: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _messageHandler);
    super.dispose();
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.colors != widget.colors ||
        oldWidget.font != widget.font ||
        oldWidget.padding != widget.padding ||
        oldWidget.transparent != widget.transparent) {
      _renderViaPostMessage();
    }
  }

  void _onWindowMessage(web.Event event) {
    final me = event as web.MessageEvent;

    // Only handle messages from our iframe.
    if (me.source != _iframe.contentWindow) return;

    final raw = me.data;
    if (raw == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode((raw as JSString).toDart) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = data['type'] as String?;
    switch (type) {
      case 'ready':
        _ready = true;
        _renderViaPostMessage();
      case 'rendered':
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = null;
          });
        }
        widget.onRendered?.call();
      case 'error':
        final error = data['message'] as String? ?? 'Unknown error';
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = error;
          });
        }
        widget.onError?.call(error);
    }
  }

  void _renderViaPostMessage() {
    if (!_ready) return;
    if (mounted) setState(() => _isLoading = true);

    final bgHex = MermaidColors.colorToHex(widget.colors.bg);
    final Map<String, dynamic> options;
    if (widget.useSourceTheme) {
      // Only pass bg (for page background) and non-color options.
      // Color styling comes from the diagram's own inline style directives.
      options = {
        'bg': bgHex,
        'font': widget.font,
        'padding': widget.padding.toInt(),
        'transparent': widget.transparent,
      };
    } else {
      options = {
        ...widget.colors.toMap(),
        'font': widget.font,
        'padding': widget.padding.toInt(),
        'transparent': widget.transparent,
      };
    }
    final msg = jsonEncode({
      'action': 'render',
      'source': widget.source,
      'bg': bgHex,
      'options': options,
    });

    _iframe.contentWindow?.postMessage(msg.toJS, '*'.toJS);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: HtmlElementView(viewType: _viewType),
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
