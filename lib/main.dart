import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const LibApp());

const _sites = {
  'MangaLib': 'https://mangalib.me',
  'SlashLib': 'https://v2.slashlib.me',
};

class LibApp extends StatelessWidget {
  const LibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MangaLib',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A2B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WebShell(),
    );
  }
}

class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  late WebViewController _controller;
  String _site = 'MangaLib';
  bool _loading = true;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(_sites[_site]!);
  }

  WebViewController _buildController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) '
          'Version/17.0 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) async {
          final canBack = await _controller.canGoBack();
          setState(() {
            _loading = false;
            _canGoBack = canBack;
          });
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  void _switchSite(String site) {
    if (site == _site) return;
    setState(() {
      _site = site;
      _controller = _buildController(_sites[site]!);
    });
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _controller.goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_site),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz),
              onSelected: _switchSite,
              itemBuilder: (_) => _sites.keys
                  .map((s) => PopupMenuItem(value: s, child: Text(s)))
                  .toList(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
