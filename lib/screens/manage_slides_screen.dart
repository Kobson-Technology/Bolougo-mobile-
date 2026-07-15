import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../models/slide.dart';

class ManageSlidesScreen extends StatefulWidget {
  const ManageSlidesScreen({super.key});

  @override
  State<ManageSlidesScreen> createState() => _ManageSlidesScreenState();
}

class _ManageSlidesScreenState extends State<ManageSlidesScreen> {
  Future<List<Slide>> _fetchSlides() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final response = await api.client.get('/slides/all');
    final List data = response.data;
    return data.map((e) => Slide.fromJson(e)).toList();
  }

  Future<void> _deleteSlide(int id) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.client.delete('/slides/$id');
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Diaporama', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Slide>>(
        future: _fetchSlides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final slides = snapshot.data ?? [];
          if (slides.isEmpty) {
            return const Center(child: Text('Aucun slide actif.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildImage(slide.imageUrl),
                    ListTile(
                      title: Text(slide.title ?? 'Slide ${slide.id}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSlide(slide.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF4444),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddSlideDialog(context),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('data:image')) {
      final base64String = url.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        height: 150, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(height: 150, color: Colors.grey),
      );
    }
    return Image.network(
      url,
      height: 150, width: double.infinity, fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => Container(height: 150, color: Colors.grey),
    );
  }

  Future<void> _showAddSlideDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    String? imageData;
    bool isUploading = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nouveau Slide'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre (Optionnel)')),
                const SizedBox(height: 16),
                imageData != null
                    ? SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: Image.memory(base64Decode(imageData!.split(',').last), fit: BoxFit.cover),
                      )
                    : Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                TextButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Choisir une image'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      setDialogState(() {
                        imageData = 'data:image/jpeg;base64,' + base64Encode(bytes);
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: isUploading || imageData == null
                    ? null
                    : () async {
                        setDialogState(() => isUploading = true);
                        final api = Provider.of<ApiService>(context, listen: false);
                        try {
                          await api.client.post('/slides', data: {
                            'title': titleCtrl.text,
                            'imageUrl': imageData,
                            'order': 0,
                            'isActive': true,
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            setState(() {}); // refresh list
                          }
                        } catch (e) {
                          setDialogState(() => isUploading = false);
                        }
                      },
                child: isUploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()) : const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }
}
