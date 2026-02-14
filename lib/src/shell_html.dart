import 'mermaid_theme.dart';

/// The CDN URL for the beautiful-mermaid browser bundle.
const cdnUrl =
    'https://cdn.jsdelivr.net/npm/beautiful-mermaid@0.1.3/dist/beautiful-mermaid.browser.global.js';

/// CSS position rules for each [MermaidControlsPosition].
String _ctrlPositionCss(MermaidControlsPosition pos) {
  switch (pos) {
    case MermaidControlsPosition.topLeft:
      return 'top: 12px; left: 12px;';
    case MermaidControlsPosition.topCenter:
      return 'top: 12px; left: 50%; transform: translateX(-50%);';
    case MermaidControlsPosition.topRight:
      return 'top: 12px; right: 12px;';
    case MermaidControlsPosition.centerLeft:
      return 'top: 50%; left: 12px; transform: translateY(-50%);';
    case MermaidControlsPosition.centerRight:
      return 'top: 50%; right: 12px; transform: translateY(-50%);';
    case MermaidControlsPosition.bottomLeft:
      return 'bottom: 12px; left: 12px;';
    case MermaidControlsPosition.bottomCenter:
      return 'bottom: 12px; left: 50%; transform: translateX(-50%);';
    case MermaidControlsPosition.bottomRight:
      return 'bottom: 12px; right: 12px;';
  }
}

/// Whether the controls should be laid out horizontally (for center positions).
bool _isHorizontal(MermaidControlsPosition pos) {
  switch (pos) {
    case MermaidControlsPosition.topCenter:
    case MermaidControlsPosition.bottomCenter:
      return true;
    default:
      return false;
  }
}

/// Fit-to-screen inline SVG icon (four corner brackets).
const _fitIcon =
    '<svg width="14" height="14" viewBox="0 0 14 14" fill="none" '
    'stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M1 5V1h4M9 1h4v4M13 9v4H9M5 13H1V9"/>'
    '</svg>';

/// Builds the shell HTML for the mermaid renderer.
///
/// Used by both native (WebView) and web (iframe) implementations.
/// When [usePostMessage] is true, the shell sends messages via
/// `window.parent.postMessage` and listens for render commands via
/// `window.addEventListener("message")` (for web iframe).
/// When false, it uses `FlutterBridge.postMessage` (for native WebView).
String buildShellHtml({
  required MermaidColors colors,
  required bool panZoom,
  required MermaidControlsPosition controlsPosition,
  required bool usePostMessage,
}) {
  final bgHex = MermaidColors.colorToHex(colors.bg);
  final fgHex = MermaidColors.colorToHex(colors.fg);
  final mutedHex = MermaidColors.colorToHex(colors.muted ?? colors.fg);
  final pz = panZoom;
  final ctrlPos = _ctrlPositionCss(controlsPosition);
  final horizontal = _isHorizontal(controlsPosition);
  final flexDir = horizontal ? 'row' : 'column';

  // Message bridge — native uses FlutterBridge, web uses postMessage.
  final sendMsg = usePostMessage
      ? 'window.parent.postMessage'
      : 'FlutterBridge.postMessage';
  final sendGuard =
      usePostMessage ? 'window.parent' : 'window.FlutterBridge';

  return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: $bgHex; }
    #v { width: 100%; height: 100%; overflow: hidden; position: relative; touch-action: none; }
    #t { transform-origin: 0 0; }
    #t svg { display: block; }
    #ctrl { position: absolute; $ctrlPos display: ${pz ? 'flex' : 'none'};
            flex-direction: $flexDir; gap: 4px; opacity: 0.6; transition: opacity 0.2s; z-index: 10; }
    #ctrl:hover { opacity: 1; }
    #ctrl button { width: 32px; height: 32px; border-radius: 8px;
                   border: 1px solid ${mutedHex}40; background: ${bgHex}cc;
                   color: $fgHex; font-size: 16px; cursor: pointer;
                   display: flex; align-items: center; justify-content: center;
                   backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
                   line-height: 1; font-family: system-ui, sans-serif; }
    #ctrl button:active { opacity: 0.7; }
  </style>
</head>
<body>
  <div id="v">
    <div id="t"></div>
    <div id="ctrl">
      <button onclick="zoomBy(1.4)" title="Zoom in">+</button>
      <button onclick="zoomBy(1/1.4)" title="Zoom out">&minus;</button>
      <button onclick="fitView()" title="Fit to screen">$_fitIcon</button>
    </div>
  </div>
  <script src="$cdnUrl"></script>
  <script>
    var t = document.getElementById("t");
    var v = document.getElementById("v");
    var ctrl = document.getElementById("ctrl");
    var pzEnabled = $pz;
    var sc = 1, px = 0, py = 0;
    var minSc = 0.1, maxSc = 10;
    var svgW = 0, svgH = 0;

    function applyTx() {
      var svg = t.querySelector("svg");
      if (svg && svgW > 0) {
        svg.setAttribute("width", svgW * sc);
        svg.setAttribute("height", svgH * sc);
      }
      t.style.transform = "translate(" + px + "px," + py + "px)";
    }

    function fitView() {
      if (svgW <= 0 || svgH <= 0) { sc = 1; px = 0; py = 0; applyTx(); return; }
      var vw = v.clientWidth;
      var vh = v.clientHeight;
      sc = Math.min(vw / svgW, vh / svgH, 1);
      var sw = svgW * sc;
      var sh = svgH * sc;
      px = (vw - sw) / 2;
      py = (vh - sh) / 2;
      applyTx();
    }

    function zoomBy(factor) {
      var rect = v.getBoundingClientRect();
      zoomAt(rect.width / 2, rect.height / 2, factor);
    }

    function zoomAt(cx, cy, factor) {
      var ns = Math.max(minSc, Math.min(maxSc, sc * factor));
      px = cx - (cx - px) * (ns / sc);
      py = cy - (cy - py) * (ns / sc);
      sc = ns;
      applyTx();
    }

    // Prevent pointer events on controls from triggering pan/drag.
    ctrl.addEventListener("pointerdown", function(e) { e.stopPropagation(); });
    ctrl.addEventListener("dblclick", function(e) { e.stopPropagation(); });

    if (pzEnabled) {
      // Wheel zoom (centered on cursor)
      v.addEventListener("wheel", function(e) {
        e.preventDefault();
        var rect = v.getBoundingClientRect();
        var mx = e.clientX - rect.left;
        var my = e.clientY - rect.top;
        var factor = e.deltaY < 0 ? 1.08 : 1 / 1.08;
        zoomAt(mx, my, factor);
      }, { passive: false });

      // Pointer pan (single finger / mouse drag)
      var dragging = false, lx = 0, ly = 0;
      v.addEventListener("pointerdown", function(e) {
        if (e.button !== 0) return;
        dragging = true; lx = e.clientX; ly = e.clientY;
        v.setPointerCapture(e.pointerId);
        e.preventDefault();
      });
      v.addEventListener("pointermove", function(e) {
        if (!dragging) return;
        px += e.clientX - lx; py += e.clientY - ly;
        lx = e.clientX; ly = e.clientY;
        applyTx();
      });
      v.addEventListener("pointerup", function() { dragging = false; });
      v.addEventListener("pointercancel", function() { dragging = false; });

      // Pinch zoom (two-finger touch)
      var pinchDist = 0;
      v.addEventListener("touchstart", function(e) {
        if (e.touches.length === 2) {
          dragging = false;
          var dx = e.touches[0].clientX - e.touches[1].clientX;
          var dy = e.touches[0].clientY - e.touches[1].clientY;
          pinchDist = Math.sqrt(dx * dx + dy * dy);
        }
      }, { passive: true });
      v.addEventListener("touchmove", function(e) {
        if (e.touches.length === 2) {
          e.preventDefault();
          var dx = e.touches[0].clientX - e.touches[1].clientX;
          var dy = e.touches[0].clientY - e.touches[1].clientY;
          var dist = Math.sqrt(dx * dx + dy * dy);
          if (pinchDist > 0) {
            var rect = v.getBoundingClientRect();
            var cx = (e.touches[0].clientX + e.touches[1].clientX) / 2 - rect.left;
            var cy = (e.touches[0].clientY + e.touches[1].clientY) / 2 - rect.top;
            zoomAt(cx, cy, dist / pinchDist);
          }
          pinchDist = dist;
        }
      }, { passive: false });
      v.addEventListener("touchend", function() { pinchDist = 0; }, { passive: true });

      // Double-click / double-tap to fit
      v.addEventListener("dblclick", function(e) {
        e.preventDefault();
        fitView();
      });
    }

    function render(src, opts) {
      beautifulMermaid.renderMermaid(src, opts).then(function(svg) {
        t.innerHTML = svg;
        var el = t.querySelector("svg");
        if (el) {
          svgW = parseFloat(el.getAttribute("width")) || el.getBoundingClientRect().width;
          svgH = parseFloat(el.getAttribute("height")) || el.getBoundingClientRect().height;
        }
        fitView();
        if ($sendGuard) $sendMsg(JSON.stringify({type:"rendered"}));
      }).catch(function(e) {
        if ($sendGuard) $sendMsg(JSON.stringify({type:"error",message:e.message||String(e)}));
      });
    }
${usePostMessage ? '''
    // Web: listen for render commands from parent (Dart).
    window.addEventListener("message", function(e) {
      try {
        var data = JSON.parse(e.data);
        if (data.action === "render") {
          document.body.style.background = data.bg;
          render(data.source, data.options);
        }
      } catch(ex) {}
    });

    // Signal ready once library has loaded.
    var readyCheck = setInterval(function() {
      if (window.beautifulMermaid) {
        clearInterval(readyCheck);
        window.parent.postMessage(JSON.stringify({type:"ready"}), "*");
      }
    }, 50);
''' : ''}  </script>
</body>
</html>''';
}
