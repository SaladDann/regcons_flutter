import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la barra de estado
import 'package:url_launcher/url_launcher.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<NewsModel>> _newsFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _newsFuture = NewsService.getNews();
  }

  Future<void> _refreshNews() async {
    setState(() => _isRefreshing = true);
    try {
      final refreshedNews = await NewsService.getNews(forceRefresh: true);
      setState(() {
        _newsFuture = Future.value(refreshedNews);
      });
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _openNewsUrl(String? url) async {
    if (url == null || url.isEmpty) {
      _notificar('No hay enlace disponible', Colors.orange);
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _notificar('No se pudo abrir la noticia', Colors.red);
    }
  }

  void _notificar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // cambiar el color de la hora/iconos de la barra superior
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF10121D),
        body: RefreshIndicator(
          color: Colors.orange,
          edgeOffset: 100,
          onRefresh: _refreshNews,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // Contenido de noticias
              FutureBuilder<List<NewsModel>>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return _buildErrorState();
                  }

                  final news = snapshot.data!;
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildNewsItem(news[index]),
                        childCount: news.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _refreshNews,
          backgroundColor: Colors.orange,
          child: _isRefreshing
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNewsItem(NewsModel news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130).withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openNewsUrl(news.link),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con gradiente superior
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.network(
                    news.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 200,
                      color: const Color(0xFF25283D),
                      child: const Icon(Icons.broken_image, color: Colors.white24, size: 50),
                    ),
                  ),
                ),
                // Badge de la fuente sobre la imagen
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      news.source.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    news.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            news.pubDate != null ? _formatDate(news.pubDate!) : 'Reciente',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rss_feed, color: Colors.white12, size: 80),
            const SizedBox(height: 16),
            const Text('Sin noticias por ahora', style: TextStyle(color: Colors.white70, fontSize: 16)),
            TextButton(onPressed: _refreshNews, child: const Text('REINTENTAR', style: TextStyle(color: Colors.orange))),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }
}