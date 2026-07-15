import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/membre.dart'; // From members feature

class AddBureauScreen extends StatefulWidget {
  const AddBureauScreen({super.key});

  @override
  State<AddBureauScreen> createState() => _AddBureauScreenState();
}

class _AddBureauScreenState extends State<AddBureauScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  int? _selectedMembreId;
  final _roleCtrl = TextEditingController();
  String? _roleSelectionne;
  final List<String> _roles = ['Président', 'Vice-Président', 'Secrétaire Général', 'Trésorier', 'Commissaire aux Comptes', 'Conseiller', 'Autre'];
  final _anneeDebutCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _motCtrl = TextEditingController();
  String _statut = 'Actif';

  List<Membre> _membresDisponibles = [];
  bool _isLoadingMembres = true;

  @override
  void initState() {
    super.initState();
    _fetchMembres();
  }

  Future<void> _fetchMembres() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final res = await api.client.get('/membres');
      if (mounted) {
        setState(() {
          _membresDisponibles = (res.data as List).map((e) => Membre.fromJson(e)).toList();
          _isLoadingMembres = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMembres = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedMembreId == null) return;
    setState(() => _isLoading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.client.post('/bureau', data: {
        'membreId': _selectedMembreId,
        'role': _roleSelectionne == 'Autre' ? _roleCtrl.text.trim() : _roleSelectionne,
        'anneeDebut': int.parse(_anneeDebutCtrl.text.trim()),
        'motDuMembre': _motCtrl.text.trim().isEmpty ? null : _motCtrl.text.trim(),
        'statut': _statut,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membre ajouté au bureau !'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Ajouter au Bureau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFFEF4444),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingMembres
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            value: _selectedMembreId,
                            decoration: const InputDecoration(labelText: 'Sélectionner un membre *', border: InputBorder.none),
                            items: _membresDisponibles.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.prenoms} ${m.nom}'))).toList(),
                            onChanged: (val) => setState(() => _selectedMembreId = val),
                            validator: (v) => v == null ? 'Veuillez sélectionner un membre' : null,
                          ),
                          const Divider(height: 1),
                          DropdownButtonFormField<String>(
                            value: _roleSelectionne,
                            decoration: const InputDecoration(labelText: 'Rôle *', border: InputBorder.none),
                            items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: (val) => setState(() {
                              _roleSelectionne = val;
                              if (val != 'Autre') _roleCtrl.clear();
                            }),
                            validator: (v) => v == null ? 'Veuillez sélectionner un rôle' : null,
                          ),
                          if (_roleSelectionne == 'Autre') ...[
                            const Divider(height: 1),
                            TextFormField(
                              controller: _roleCtrl,
                              decoration: const InputDecoration(labelText: 'Précisez le rôle *', border: InputBorder.none),
                              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                            ),
                          ],
                          const Divider(height: 1),
                          TextFormField(
                            controller: _anneeDebutCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Année de début *', border: InputBorder.none),
                            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                          ),
                          const Divider(height: 1),
                          DropdownButtonFormField<String>(
                            initialValue: _statut,
                            decoration: const InputDecoration(labelText: 'Statut', border: InputBorder.none),
                            items: ['Actif', 'Ancien'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setState(() => _statut = val!),
                          ),
                          const Divider(height: 1),
                          TextFormField(
                            controller: _motCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Mot du membre (Optionnel)', border: InputBorder.none),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
