import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import 'reader.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key, required this.manga});
  final Manga manga;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  final _api = LibApi.instance;
  Manga? _details;
  List<Chapter> _chapters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final details = await _api.mangaDetails(widget.manga.slugUrl);
      final chapters = await _api.chapters(widget.manga.slugUrl);
      setState(() {
        _details = details;
        _chapters = chapters;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _openChapter(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          slugUrl: widget.manga.slugUrl,
          chapters: _chapters,
          index: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _details ?? widget.manga;
    return Scaffold(
      appBar: AppBar(title: Text(m.displayName)),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                  FilledButton(
                      onPressed: _load, child: const Text('Повторить')),
                ],
              ),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: m.cover.isEmpty
                            ? const SizedBox(width: 110, height: 160)
                            : CachedNetworkImage(
                                imageUrl: m.cover,
                                width: 110,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            if (m.name.isNotEmpty && m.name != m.displayName)
                              Text(m.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            if (m.rating != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(m.rating!),
                                ]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (m.summary != null && m.summary!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(m.summary!),
                  ),
                const Divider(height: 24),
                if (_chapters.isEmpty && _details == null)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ))
                else
                  ..._chapters.reversed.toList().asMap().entries.map((e) {
                    // reversed: newest first; map back to original index
                    final originalIndex = _chapters.length - 1 - e.key;
                    return ListTile(
                      dense: true,
                      title: Text(e.value.label),
                      onTap: () => _openChapter(originalIndex),
                    );
                  }),
              ],
            ),
    );
  }
}
