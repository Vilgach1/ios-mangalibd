import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import 'title.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _api = LibApi.instance;
  final _scroll = ScrollController();
  final _search = TextEditingController();

  final List<Manga> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _end = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >
          _scroll.position.maxScrollExtent - 600) {
        _load();
      }
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (_end && !reset)) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 1;
        _end = false;
      }
    });
    try {
      final batch =
          await _api.catalog(q: _search.text.trim(), page: _page);
      setState(() {
        _items.addAll(batch);
        _page++;
        if (batch.isEmpty) _end = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _switchSite(LibSite s) async {
    await _api.setSite(s);
    _api.clearServerCache();
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _search,
          decoration: const InputDecoration(
            hintText: 'Поиск…',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(reset: true),
        ),
        actions: [
          PopupMenuButton<LibSite>(
            icon: Icon(_api.site == LibSite.mangalib
                ? Icons.menu_book
                : Icons.favorite),
            tooltip: _api.site.title,
            onSelected: _switchSite,
            itemBuilder: (_) => LibSite.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(children: [
                        if (s == _api.site)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(s.title),
                      ]),
                    ))
                .toList(),
          ),
        ],
      ),
      body: _error != null && _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                  FilledButton(
                    onPressed: () => _load(reset: true),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: GridView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(8),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _items.length,
                itemBuilder: (_, i) => _MangaCard(manga: _items[i]),
              ),
            ),
    );
  }
}

class _MangaCard extends StatelessWidget {
  const _MangaCard({required this.manga});
  final Manga manga;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TitleScreen(manga: manga)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: manga.cover.isEmpty
                  ? Container(color: Colors.grey.shade800)
                  : CachedNetworkImage(
                      imageUrl: manga.cover,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.grey.shade800),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            manga.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
