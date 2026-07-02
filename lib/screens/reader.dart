import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.slugUrl,
    required this.chapters,
    required this.index,
  });

  final String slugUrl;
  final List<Chapter> chapters;
  final int index;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _api = LibApi.instance;
  late int _index = widget.index;
  List<String> _pages = [];
  bool _loading = true;
  String? _error;
  bool _showBar = true;

  Chapter get _chapter => widget.chapters[_index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _pages = [];
    });
    try {
      final pages = await _api.chapterPages(
          widget.slugUrl, _chapter.volume, _chapter.number);
      setState(() => _pages = pages);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.chapters.length) return;
    setState(() => _index = next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showBar
          ? AppBar(
              title: Text(_chapter.label,
                  style: const TextStyle(fontSize: 15)),
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showBar = !_showBar),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child:
                              Text(_error!, textAlign: TextAlign.center),
                        ),
                        FilledButton(
                            onPressed: _load,
                            child: const Text('Повторить')),
                      ],
                    ),
                  )
                : InteractiveViewer(
                    maxScale: 4,
                    child: ListView.builder(
                      itemCount: _pages.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: _pages[i],
                        httpHeaders: const {
                          'Referer': 'https://mangalib.me/',
                        },
                        placeholder: (_, __) => const SizedBox(
                          height: 400,
                          child: Center(
                              child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(
                          height: 200,
                          child: Center(
                              child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: _showBar
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _index > 0 ? () => _go(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Пред.'),
                  ),
                  Text('${_index + 1} / ${widget.chapters.length}'),
                  TextButton.icon(
                    onPressed: _index < widget.chapters.length - 1
                        ? () => _go(1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('След.'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
