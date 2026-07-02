import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Sites of the lib.social family supported by the app.
enum LibSite {
  mangalib(1, 'MangaLib', 'mangalib.me'),
  slashlib(2, 'SlashLib (yaoi)', 'v2.slashlib.me');

  const LibSite(this.id, this.title, this.host);
  final int id;
  final String title;
  final String host;
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'API $statusCode: $message';
}

/// Thin client for api.cdnlibs.org (the shared API of mangalib/slashlib).
class LibApi {
  LibApi._();
  static final LibApi instance = LibApi._();

  static const _base = 'https://api.cdnlibs.org/api';

  String? _token;
  LibSite site = LibSite.mangalib;
  List<String> _imageServers = [];

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final siteId = prefs.getInt('site') ?? LibSite.mangalib.id;
    site = LibSite.values.firstWhere((s) => s.id == siteId,
        orElse: () => LibSite.mangalib);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('token');
    } else {
      await prefs.setString('token', token);
    }
  }

  Future<void> setSite(LibSite s) async {
    site = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('site', s.id);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Site-Id': '${site.id}',
        'User-Agent': 'MangalibApp/1.0 (iOS)',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    final uri = Uri.parse('$_base$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 401) {
      throw ApiException(401, 'Нужна авторизация');
    }
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Image CDN servers for current site (cached).
  Future<String> imageServer() async {
    if (_imageServers.isEmpty) {
      final data = await _get('/constants', {'fields[]': 'imageServers'});
      final servers = (data['data']['imageServers'] as List)
          .where((s) => (s['site_ids'] as List).contains(site.id))
          .map((s) => s['url'] as String)
          .toList();
      _imageServers = servers;
    }
    return _imageServers.isNotEmpty ? _imageServers.first : '';
  }

  void clearServerCache() => _imageServers = [];

  /// Catalog / search. [q] optional search query, [page] starts at 1.
  Future<List<Manga>> catalog({String? q, int page = 1}) async {
    final data = await _get('/manga', {
      'site_id[]': site.id,
      'page': page,
      if (q != null && q.isNotEmpty) 'q': q,
      'fields[]': 'rate_avg',
    });
    return (data['data'] as List).map((j) => Manga.fromJson(j)).toList();
  }

  Future<Manga> mangaDetails(String slugUrl) async {
    final data = await _get('/manga/$slugUrl',
        {'fields[]': 'summary'});
    return Manga.fromJson(data['data']);
  }

  Future<List<Chapter>> chapters(String slugUrl) async {
    final data = await _get('/manga/$slugUrl/chapters');
    return (data['data'] as List).map((j) => Chapter.fromJson(j)).toList();
  }

  Future<List<String>> chapterPages(
      String slugUrl, String volume, String number) async {
    final data = await _get('/manga/$slugUrl/chapter', {
      'volume': volume,
      'number': number,
    });
    final server = await imageServer();
    return ((data['data']['pages'] ?? []) as List)
        .map((p) => '$server${p['url']}')
        .toList();
  }

  Future<Map<String, dynamic>?> me() async {
    if (!isLoggedIn) return null;
    final data = await _get('/auth/me');
    return data['data'] as Map<String, dynamic>?;
  }

  /// User bookmarks ("Читаю" etc.) — requires auth.
  Future<List<Manga>> bookmarks(int userId) async {
    final data = await _get('/bookmarks', {
      'user_id': userId,
      'site_id[]': site.id,
      'page': 1,
    });
    return (data['data'] as List)
        .map((j) => Manga.fromJson(j['media'] ?? j))
        .toList();
  }
}

class Manga {
  Manga({
    required this.slugUrl,
    required this.name,
    required this.rusName,
    required this.cover,
    this.summary,
    this.rating,
  });

  final String slugUrl;
  final String name;
  final String rusName;
  final String cover;
  final String? summary;
  final String? rating;

  String get displayName => rusName.isNotEmpty ? rusName : name;

  factory Manga.fromJson(Map<String, dynamic> j) => Manga(
        slugUrl: j['slug_url'] ?? j['slug'] ?? '',
        name: j['name'] ?? '',
        rusName: j['rus_name'] ?? '',
        cover: (j['cover'] is Map ? j['cover']['thumbnail'] : null) ?? '',
        summary: j['summary'],
        rating: j['rating'] is Map ? j['rating']['average']?.toString() : null,
      );
}

class Chapter {
  Chapter({required this.volume, required this.number, required this.name});
  final String volume;
  final String number;
  final String name;

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        volume: j['volume']?.toString() ?? '1',
        number: j['number']?.toString() ?? '',
        name: j['name'] ?? '',
      );

  String get label =>
      'Том $volume Глава $number${name.isNotEmpty ? ' — $name' : ''}';
}
