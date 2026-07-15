import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/groupe_membre.dart';

class GroupesScreen extends StatefulWidget {
  const GroupesScreen({super.key});

  @override
  State<GroupesScreen> createState() => _GroupesScreenState();
}

class _GroupesScreenState extends State<GroupesScreen> {
  Future<List<GroupeMembre>> _fetchGroupes() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final response = await api.client.get('/groupes');
    final List data = response.data;
    return data.map((e) => GroupeMembre.fromJson(e)).toList();
  }

  Future<void> _deleteGroupe(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce groupe ?'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce groupe ? Cela n\'effacera pas les membres.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = Provider.of<ApiService>(context, listen: false);
        await api.client.delete('/groupes/$id');
        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _showAddGroupeDialog() async {
    final nomCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Groupe'),
        content: TextField(
          controller: nomCtrl,
          decoration: const InputDecoration(labelText: 'Nom du groupe'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nomCtrl.text.trim().isNotEmpty) Navigator.pop(context, true);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = Provider.of<ApiService>(context, listen: false);
        await api.client.post('/groupes', data: {'nom': nomCtrl.text.trim()});
        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Gestion des Groupes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<GroupeMembre>>(
        future: _fetchGroupes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final groupes = snapshot.data ?? [];
          if (groupes.isEmpty) {
            return const Center(child: Text('Aucun groupe trouvé.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupes.length,
            itemBuilder: (context, index) {
              final groupe = groupes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE5E7EB), child: Icon(Icons.group, color: Color(0xFF6B7280))),
                  title: Text(groupe.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteGroupe(groupe.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF4444),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddGroupeDialog,
      ),
    );
  }
}
