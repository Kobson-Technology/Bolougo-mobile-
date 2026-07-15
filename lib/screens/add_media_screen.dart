import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class AddMediaScreen extends StatefulWidget {
  final String type; // 'photos', 'videos', or 'musiques'

  const AddMediaScreen({super.key, required this.type});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController(); // Only for musique

  String get _title {
    if (widget.type == 'photos') return 'Ajouter une Photo';
    if (widget.type == 'videos') return 'Ajouter une Vidéo';
    return 'Ajouter une Musique';
  }

  String get _urlLabel {
    if (widget.type == 'videos') return 'Lien YouTube *';
    if (widget.type == 'musiques') return 'Lien du fichier Audio *';
    return 'Lien de l\'image (URL) *';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    
    Map<String, dynamic> data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    };

    if (widget.type == 'videos') {
      data['youtubeUrl'] = _urlCtrl.text.trim();
    } else {
      data['url'] = _urlCtrl.text.trim();
      if (widget.type == 'musiques' && _coverUrlCtrl.text.trim().isNotEmpty) {
        data['coverUrl'] = _coverUrlCtrl.text.trim();
      }
    }

    try {
      await api.client.post('/medias/${widget.type}', data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ajouté avec succès !'), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFFEF4444),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        prefixIcon: Icon(Icons.title, color: Color(0xFFEF4444)),
                        border: InputBorder.none,
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                    const Divider(height: 1),
                    TextFormField(
                      controller: _urlCtrl,
                      decoration: InputDecoration(
                        labelText: _urlLabel,
                        prefixIcon: const Icon(Icons.link, color: Color(0xFFEF4444)),
                        border: InputBorder.none,
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                    if (widget.type == 'musiques') ...[
                      const Divider(height: 1),
                      TextFormField(
                        controller: _coverUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Lien de la pochette (Optionnel)',
                          prefixIcon: Icon(Icons.image, color: Color(0xFFEF4444)),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optionnel)',
                        prefixIcon: Icon(Icons.description, color: Color(0xFFEF4444)),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save, color: Colors.white),
                label: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
