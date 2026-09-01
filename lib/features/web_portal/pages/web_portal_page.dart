import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../shared/components/error_view.dart';

class WebPortalPage extends ConsumerStatefulWidget {
  final String title;
  final String initialUrl;

  const WebPortalPage({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  @override
  ConsumerState<WebPortalPage> createState() => _WebPortalPageState();
}

class _WebPortalPageState extends ConsumerState<WebPortalPage> {
  late final WebViewController _controller;
  final _progress = ValueNotifier<int>(0);
  final _errorMessage = ValueNotifier<String?>(null);
  final _canExit = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _errorMessage.value = null;
            _progress.value = 0;
          },
          onProgress: (progress) => _progress.value = progress,
          onPageFinished: (_) => _progress.value = 100,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _progress.value = 100;
              _errorMessage.value = '${widget.title} sayfası yüklenemedi.';
            }
          },
          onNavigationRequest: _handleNavigation,
        ),
      );
      await _controller.loadRequest(Uri.parse(widget.initialUrl));
    } on PlatformException catch (error) {
      _showPlatformError(error);
    }
  }

  Future<NavigationDecision> _handleNavigation(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.scheme == 'https') return NavigationDecision.navigate;

    if (uri.scheme != 'http') {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // WebView tarafından desteklenmeyen bağlantı sessizce engellenir.
      }
    }
    return NavigationDecision.prevent;
  }

  Future<void> _handleBack() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        return;
      }
    } on PlatformException {
      // Yerel WebView bağlantısı koptuysa sayfadan güvenle çıkılır.
    }

    _exitPage();
  }

  void _exitPage() {
    if (_canExit.value) return;
    _canExit.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _reload() async {
    _errorMessage.value = null;
    _progress.value = 0;
    try {
      await _controller.reload();
    } on PlatformException catch (error) {
      _showPlatformError(error);
    }
  }

  void _showPlatformError(PlatformException error) {
    if (!mounted) return;
    _progress.value = 100;
    _errorMessage.value = error.code == 'channel-error'
        ? 'Web görünümü başlatılamadı. Uygulamayı tamamen kapatıp yeniden açın.'
        : '${widget.title} sayfası yüklenemedi.';
  }

  @override
  void dispose() {
    _progress.dispose();
    _errorMessage.dispose();
    _canExit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Geri',
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          ValueListenableBuilder<String?>(
            valueListenable: _errorMessage,
            builder: (context, message, _) {
              if (message == null) return const SizedBox.shrink();
              return ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: ErrorView(message: message, onRetry: _reload),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: _progress,
            builder: (context, progress, _) {
              if (progress >= 100) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(value: progress / 100),
              );
            },
          ),
        ],
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: _canExit,
      child: page,
      builder: (context, canExit, child) {
        return PopScope(
          canPop: canExit,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack();
          },
          child: child!,
        );
      },
    );
  }
}
