import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/membre.dart';
import 'add_membre_screen.dart';
import 'membre_detail_screen.dart';

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> {
  List<Membre> _membres = [];
  List<Membre> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMembres();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _membres.where((m) =>
        m.nomComplet.toLowerCase().contains(q) ||
        (m.telephone ?? '').contains(q) ||
        (m.ville ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _onAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddMembreScreen()),
    );
    if (result == true) {
      setState(() { _isLoading = true; _membres = []; _filtered = []; });
      await _fetchMembres();
    }
  }

  Future<void> _fetchMembres() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.client.get('/membres');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _membres = data.map((json) => Membre.fromJson(json)).toList();
          _filtered = _membres;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger la liste des membres.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEF4444),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        backgroundColor: const Color(0xFFEF4444),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _errorMessage != null
              ? _buildError()
              : _filtered.isEmpty
                  ? const Center(child: Text('Aucun résultat trouvé.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final m = _filtered[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              child: Text(
                                m.nom.isNotEmpty ? m.nom[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 20),
                              ),
                            ),
                            title: Text(m.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (m.telephone != null) Row(children: [const Icon(Icons.phone, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(m.telephone!, style: const TextStyle(fontSize: 13))]),
                                if (m.ville != null) Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(m.ville!, style: const TextStyle(fontSize: 13))]),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFFEF4444)),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => MembreDetailScreen(membreId: m.id, nomComplet: m.nomComplet)),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () { setState(() { _isLoading = true; _errorMessage = null; }); _fetchMembres(); }, child: const Text('Réessayer')),
    ]),
  );
}
