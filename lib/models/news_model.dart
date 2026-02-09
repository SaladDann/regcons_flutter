/// Modelo de datos para representar noticias
class NewsModel {
  final String title;
  final String description;
  final String imageUrl;
  final String source;
  final String? link;
  final DateTime? pubDate;

  NewsModel({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.source,
    this.link,
    this.pubDate,
  });

  /// Serializa el modelo para almacenamiento persistente en SharedPreferences o SQLite.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'source': source,
      'link': link,
      'pubDate': pubDate?.millisecondsSinceEpoch,
    };
  }

  /// Reconstruye el modelo desde un mapa, garantizando valores por defecto ante datos nulos.
  factory NewsModel.fromMap(Map<String, dynamic> map) {
    return NewsModel(
      title: (map['title'] as String?) ?? 'Sin título',
      description: (map['description'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      source: (map['source'] as String?) ?? 'Fuente desconocida',
      link: map['link'] as String?,
      pubDate: map['pubDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['pubDate'] as int)
          : null,
    );
  }

  // --- Helpers ---

  /// Retorna una versión amigable del tiempo transcurrido desde la publicación.
  String get tiempoRelativo {
    if (pubDate == null) return '';
    final difference = DateTime.now().difference(pubDate!);

    if (difference.inDays > 0) return 'Hace ${difference.inDays} d';
    if (difference.inHours > 0) return 'Hace ${difference.inHours} h';
    if (difference.inMinutes > 0) return 'Hace ${difference.inMinutes} min';
    return 'Reciente';
  }

  /// Indica si la noticia tiene un enlace válido para ser abierta en el navegador.
  bool get esNavegable => link != null && Uri.tryParse(link!) != null;
}