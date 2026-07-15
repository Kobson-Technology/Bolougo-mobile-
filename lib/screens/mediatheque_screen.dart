import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/media.dart';
import 'add_media_screen.dart';

class MediathequeScreen extends StatefulWidget {
  const MediathequeScreen({super.key});

  @override
  State<MediathequeScreen> createState() => _MediathequeScreenState();
}

class _MediathequeScreenState extends State<MediathequeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médiathèque', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFEF4444),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFEF4444),
          tabs: const [
            Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
            Tab(icon: Icon(Icons.video_library), text: 'Vidéos'),
            Tab(icon: Icon(Icons.library_music), text: 'Musiques'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MediaTab<Photo>(type: 'photos', icon: Icons.image),
          _MediaTab<Video>(type: 'videos', icon: Icons.play_circle_fill),
          _MediaTab<Musique>(type: 'musiques', icon: Icons.music_note),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF4444),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          String type = 'photos';
          if (_tabController.index == 1) type = 'videos';
          if (_tabController.index == 2) type = 'musiques';
          
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddMediaScreen(type: type)));
          if (result == true) {
            // Trigger rebuild
            setState(() {});
          }
        },
      ),
    );
  }
}

class _MediaTab<T> extends StatelessWidget {
  final String type;
  final IconData icon;

  const _MediaTab({required this.type, required this.icon});

  Future<List<T>> _fetchMedias(BuildContext context) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final response = await api.client.get('/medias/$type');
    final List data = response.data;

    if (type == 'photos') return data.map((e) => Photo.fromJson(e) as T).toList();
    if (type == 'videos') return data.map((e) => Video.fromJson(e) as T).toList();
    if (type == 'musiques') return data.map((e) => Musique.fromJson(e) as T).toList();
    
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _fetchMedias(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Aucun élément trouvé.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            String title = '';
            String url = '';
            
            if (item is Photo) {
              title = item.title;
              url = item.url;
            } else if (item is Video) {
              title = item.title;
              url = 'https://img.youtube.com/vi/${_extractYoutubeId(item.youtubeUrl)}/0.jpg';
            } else if (item is Musique) {
              title = item.title;
              url = item.coverUrl ?? '';
            }

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url.isNotEmpty)
                    Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(icon, size: 50, color: Colors.grey))
                  else
                    Icon(icon, size: 50, color: Colors.grey),
                  
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      ),
                    ),
                  ),
                  
                  // Text
                  Positioned(
                    bottom: 8, left: 8, right: 8,
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Type Icon
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _extractYoutubeId(String url) {
    try {
      if (url.contains('v=')) return url.split('v=')[1].split('&')[0];
      if (url.contains('youtu.be/')) return url.split('youtu.be/')[1].split('?')[0];
      return '';
    } catch (_) {
      return '';
    }
  }
}
