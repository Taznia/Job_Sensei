import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../../core/constants/app_colors.dart';

/// YouTube lesson player that stays inside the app.
///
/// Uses a first-party WebView embed with a YouTube origin so Android can
/// attach a Referer header (the iframe API often renders a blank frame).
class YoutubeEmbedPlayer extends StatefulWidget {
  const YoutubeEmbedPlayer({super.key, required this.videoId});

  final String videoId;

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  late final WebViewController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = _createController()..loadHtmlString(
      _embedHtml(widget.videoId),
      baseUrl: 'https://www.youtube.com',
    );
  }

  WebViewController _createController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            if (error.isForMainFrame != true) return;
            setState(() => _error = 'Could not load this lesson.');
          },
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host ?? '';
            final allowed = host.isEmpty ||
                host.contains('youtube') ||
                host.contains('ytimg') ||
                host.contains('google') ||
                host.contains('gstatic') ||
                host.contains('ggpht');
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      platform.setMediaPlaybackRequiresUserGesture(false);
    } else if (platform is WebKitWebViewController) {
      platform.setAllowsBackForwardNavigationGestures(false);
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_error == null)
            WebViewWidget(controller: _controller)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          if (!_ready && _error == null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
        ],
      ),
    );
  }
}

String _embedHtml(String videoId) {
  final id = videoId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <style>
    html, body { margin: 0; padding: 0; background: #000; width: 100%; height: 100%; overflow: hidden; }
    iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe
    src="https://www.youtube.com/embed/$id?playsinline=1&rel=0&modestbranding=1&controls=1&fs=1"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
    allowfullscreen
    referrerpolicy="strict-origin-when-cross-origin"></iframe>
</body>
</html>
''';
}
