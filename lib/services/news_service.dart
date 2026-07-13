import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_model.dart';

class NewsService {
  static const String _cacheKey = 'cached_news';
  static const Duration _cacheDuration = Duration(hours: 1);

  static final Map<String, String> _rssSources = {
    'ArchDaily': 'https://www.archdaily.mx/mx/rss',
    'El Universo': 'https://www.eluniverso.com/arc/outboundfeeds/rss/?outputType=xml',
  };

  /// Obtiene noticias combinadas de todas las fuentes con soporte para caché local
  static Future<List<NewsModel>> getNews({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedNews = await _getCachedNews();
      if (cachedNews.isNotEmpty) return cachedNews;
    }

    final allNews = <NewsModel>[];

    for (var entry in _rssSources.entries) {
      try {
        final news = await _fetchFromRss(entry.value, entry.key);
        allNews.addAll(news);
      } catch (e) { }
    }

    allNews.sort((a, b) => (b.pubDate ?? DateTime(2000)).compareTo(a.pubDate ?? DateTime(2000)));
    await _saveToCache(allNews);
    return allNews;
  }

  /// Realiza la petición HTTP y parsea el XML/RSS extrayendo metadatos y multimedia
  static Future<List<NewsModel>> _fetchFromRss(String url, String sourceName) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item').isNotEmpty
          ? document.findAllElements('item')
          : document.findAllElements('entry');

      return items.map((item) {
        final title = item.getElement('title')?.innerText ?? 'Sin título';
        final link = item.getElement('link')?.innerText ?? item.getElement('link')?.getAttribute('href');

        final rawDescription = item.getElement('description')?.innerText ??
            item.getElement('content')?.innerText ??
            item.getElement('summary')?.innerText ?? '';

        final description = _cleanHtml(rawDescription);
        final imageUrl = _extractImageUrl(item, rawDescription);

        final dateStr = item.getElement('pubDate')?.innerText ??
            item.getElement('published')?.innerText ??
            item.getElement('updated')?.innerText;

        return NewsModel(
          title: title.trim(),
          description: description.length > 150 ? '${description.substring(0, 150)}...' : description,
          imageUrl: imageUrl,
          source: sourceName,
          link: link,
          pubDate: dateStr != null ? _tryParseDate(dateStr) : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Lógica de extracción de imágenes priorizando etiquetas media y cayendo en regex HTML
  static String _extractImageUrl(XmlElement item, String rawDescription) {
    // Etiquetas de media especializadas
    final media = item.findElements('media:content').firstOrNull ??
        item.findElements('media:thumbnail').firstOrNull;
    if (media != null) return media.getAttribute('url') ?? '';

    // Adjuntos
    final enclosure = item.getElement('enclosure');
    if (enclosure != null) return enclosure.getAttribute('url') ?? '';

    // Extracción de src en el cuerpo HTML
    if (rawDescription.contains('<img')) {
      final imgMatch = RegExp(r'src="([^"]+)"').firstMatch(rawDescription);
      if (imgMatch != null) return imgMatch.group(1)!;
    }

    // Imagen por defecto para construcción/noticias
    return 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800';
  }

  /// Elimina etiquetas HTML y normaliza espacios en blanco del texto
  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Intenta parsear fechas bajo múltiples formatos comunes en feeds RSS y Atom
  static DateTime? _tryParseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        return DateFormat("EEE, dd MMM yyyy HH:mm:ss Z", "en_US").parse(dateStr);
      } catch (_) {
        try {
          return DateFormat("yyyy-MM-dd'T'HH:mm:ss", "en_US").parse(dateStr);
        } catch (_) {
          return null;
        }
      }
    }
  }

  /// Persiste la lista de noticias en el almacenamiento local con marca de tiempo
  static Future<void> _saveToCache(List<NewsModel> news) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'news': news.map((n) => n.toMap()).toList(),
    };
    await prefs.setString(_cacheKey, jsonEncode(cacheData));
  }

  /// Recupera noticias del caché si no han excedido la duración de validez
  static Future<List<NewsModel>> _getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        final cacheData = jsonDecode(cachedJson);
        final timestamp = cacheData['timestamp'] as int;
        final difference = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));

        if (difference < _cacheDuration) {
          return (cacheData['news'] as List).map((item) => NewsModel.fromMap(item)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
