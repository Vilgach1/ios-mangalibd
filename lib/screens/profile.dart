import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = LibApi.instance;
  Map<String, dynamic>? _me;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_api.isLoggedIn) _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _api.me();
      setState(() => _me = me);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final token = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const LoginWebView()),
    );
    if (token != null && token.isNotEmpty) {
      await _api.setToken(token);
      _loadMe();
    }
  }

  Future<void> _logout() async {
    await _api.setToken(null);
    setState(() => _me = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : !_api.isLoggedIn
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_off, size: 64),
                      const SizedBox(height: 16),
                      const Text('Вы не авторизованы'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _login,
                        icon: const Icon(Icons.login),
                        label: const Text('Войти через lib.social'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _me?['avatar']?['url'] != null
                            ? NetworkImage(_me!['avatar']['url'])
                            : null,
                        child: _me?['avatar']?['url'] == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _me?['username'] ?? 'Авторизован',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Выйти'),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Opens the real mangalib.me login page in a WebView and, once the user
/// logs in, pulls the Bearer token the site stores in localStorage.
class LoginWebView extends StatefulWidget {
  const LoginWebView({super.key});

  @override
  State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
  late final WebViewController _controller;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _startPolling(),
      ))
      ..loadRequest(Uri.parse('https://mangalib.me/ru/front/auth'));
  }

  void _startPolling() {
    _poll ??= Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  Future<void> _check() async {
    try {
      final raw = await _controller
          .runJavaScriptReturningResult("localStorage.getItem('auth')");
      var s = raw.toString();
      if (s == 'null' || s.isEmpty) return;
      // iOS returns a JSON-quoted string — unwrap it.
      if (s.startsWith('"')) s = jsonDecode(s);
      final auth = jsonDecode(s);
      final token = auth is Map
          ? (auth['token']?['access_token'] ?? auth['access_token'])
          : null;
      if (token is String && token.isNotEmpty && mounted) {
        _poll?.cancel();
        Navigator.pop(context, token);
      }
    } catch (_) {
      // not logged in yet — keep polling
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход — mangalib.me')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
