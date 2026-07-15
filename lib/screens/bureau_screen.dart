import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/bureau.dart';
import 'add_bureau_screen.dart';

class BureauScreen extends StatefulWidget {
  const BureauScreen({super.key});

  @override
  State<BureauScreen> createState() => _BureauScreenState();
}

class _BureauScreenState extends State<BureauScreen> {
  Future<List<Bureau>> _fetchBureau() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final response = await api.client.get('/bureau');
    final List data = response.data;
    return data.map((e) => Bureau.fromJson(e)).toList();
  }

  Future<void> _deleteMembre(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer du bureau ?'),
        content: const Text('Êtes-vous sûr de vouloir retirer ce membre du bureau ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = Provider.of<ApiService>(context, listen: false);
        await api.client.delete('/bureau/$id');
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
        title: const Text('Bureau Exécutif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Bureau>>(
        future: _fetchBureau(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final membres = snapshot.data ?? [];
          if (membres.isEmpty) {
            return const Center(child: Text('Aucun membre dans le bureau.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: membres.length,
            itemBuilder: (context, index) {
              final b = membres[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: b.membrePhoto != null ? NetworkImage(b.membrePhoto!) : null,
                    child: b.membrePhoto == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text('${b.membrePrenom} ${b.membreNom}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(b.role, style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${b.anneeDebut} - ${b.anneeFin ?? "Présent"} | Statut: ${b.statut}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteMembre(b.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF4444),
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBureauScreen()));
          if (result == true) {
            setState(() {});
          }
        },
      ),
    );
  }
}
