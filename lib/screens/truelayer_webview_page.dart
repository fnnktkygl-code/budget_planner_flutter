import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/colors.dart';

class TrueLayerWebViewPage extends StatefulWidget {
  final String authUrl;
  final String bankName;

  const TrueLayerWebViewPage({
    super.key,
    required this.authUrl,
    required this.bankName,
  });

  @override
  State<TrueLayerWebViewPage> createState() => _TrueLayerWebViewPageState();
}

class _TrueLayerWebViewPageState extends State<TrueLayerWebViewPage> {
  late final WebViewController _controller;
  double _loadingProgress = 0.0;
  bool _codeIntercepted = false;

  void _tryInterceptCode(String url) {
    if (_codeIntercepted) return;
    if (!url.contains('code=')) return;

    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    debugPrint('[WebView] Code detected in URL: $code');
    if (code != null && code.isNotEmpty && mounted) {
      _codeIntercepted = true;
      Navigator.of(context).pop(code);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            debugPrint('[WebView] Page started: $url');
            _tryInterceptCode(url);
          },
          onPageFinished: (String url) {
            debugPrint('[WebView] Page finished: $url');
            _tryInterceptCode(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('[WebView] Navigation request to: ${request.url}');
            if (!_codeIntercepted && request.url.contains('code=')) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              debugPrint('[WebView] Code intercepted via navigation: $code');
              if (code != null && code.isNotEmpty && mounted) {
                _codeIntercepted = true;
                Navigator.of(context).pop(code);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            debugPrint('[WebView] URL changed to: ${change.url}');
            if (change.url != null) {
              _tryInterceptCode(change.url!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Connexion ${widget.bankName}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          if (_loadingProgress < 1.0)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
              minHeight: 3,
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
