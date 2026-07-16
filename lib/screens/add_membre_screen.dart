import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

import '../models/membre.dart';

class AddMembreScreen extends StatefulWidget {
  final Membre? membre;
  const AddMembreScreen({super.key, this.membre});

  @override
  State<AddMembreScreen> createState() => _AddMembreScreenState();
}

class _AddMembreScreenState extends State<AddMembreScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nomCtrl = TextEditingController();
  final _prenomsCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _paysCtrl = TextEditingController();
  final _profCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _familleCtrl = TextEditingController();
  String? _sexe;
  int? _groupeSelectionne;
  String? _quartierSelectionne;
  final List<String> _quartiers = ['Dissaninhouo', 'Douopeli', 'Gbadihouo', 'Glahouo', 'Autre'];
  List<dynamic> _groupes = [];
  bool _isLoadingGroupes = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupes();
    if (widget.membre != null) {
      final m = widget.membre!;
      _nomCtrl.text = m.nom;
      _prenomsCtrl.text = m.prenoms;
      _telCtrl.text = m.telephone ?? '';
      _emailCtrl.text = m.email ?? '';
      _villeCtrl.text = m.ville ?? '';
      _paysCtrl.text = m.pays ?? '';
      _profCtrl.text = m.profession ?? '';
      _familleCtrl.text = m.famille ?? '';
      _sexe = m.sexe;
      _groupeSelectionne = m.groupeId;
      
      if (m.quartier != null && m.quartier!.isNotEmpty) {
        if (_quartiers.contains(m.quartier)) {
          _quartierSelectionne = m.quartier;
        } else {
          _quartierSelectionne = 'Autre';
          _quartierCtrl.text = m.quartier!;
        }
      }
    }
  }

  Future<void> _fetchGroupes() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.client.get('/Groupes');
      if (mounted) {
        setState(() {
          _groupes = response.data;
          _isLoadingGroupes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingGroupes = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_nomCtrl, _prenomsCtrl, _telCtrl, _emailCtrl, _villeCtrl, _paysCtrl, _profCtrl, _quartierCtrl, _familleCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final data = {
        'nom': _nomCtrl.text.trim().toUpperCase(),
        'prenoms': _prenomsCtrl.text.trim().toUpperCase(),
        'telephone': _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'sexe': _sexe,
        'ville': _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
        'pays': _paysCtrl.text.trim().isEmpty ? null : _paysCtrl.text.trim(),
        'profession': _profCtrl.text.trim().isEmpty ? null : _profCtrl.text.trim(),
        'groupeId': _groupeSelectionne,
        'quartier': _quartierSelectionne == 'Autre'
            ? (_quartierCtrl.text.trim().isEmpty ? null : _quartierCtrl.text.trim())
            : _quartierSelectionne,
        'famille': _familleCtrl.text.trim().isEmpty ? null : _familleCtrl.text.trim(),
      };

      if (widget.membre != null) {
        await api.client.put('/membres/${widget.membre!.id}', data: data);
      } else {
        await api.client.post('/membres', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.membre != null ? '✅ Membre modifié avec succès !' : '✅ Membre ajouté avec succès !'), backgroundColor: const Color(0xFF10B981)),
        );
        Navigator.of(context).pop(true); // retour avec refresh signal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.membre != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le Membre' : 'Nouveau Membre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEF4444),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SAUVEGARDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Identité ─────────────────────────────────────
            _sectionHeader('Identité', Icons.badge),
            _buildField(_nomCtrl, 'Nom *', Icons.person, required: true, capitalization: TextCapitalization.characters),
            _buildField(_prenomsCtrl, 'Prénoms *', Icons.person_outline, required: true, capitalization: TextCapitalization.characters),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  initialValue: _sexe,
                  decoration: const InputDecoration(labelText: 'Sexe', border: InputBorder.none, prefixIcon: Icon(Icons.wc, color: Color(0xFFEF4444))),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculin')),
                    DropdownMenuItem(value: 'F', child: Text('Féminin')),
                  ],
                  onChanged: (v) => setState(() => _sexe = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _isLoadingGroupes
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)))),
                      )
                    : DropdownButtonFormField<int>(
                        value: _groupeSelectionne,
                        decoration: const InputDecoration(labelText: 'Groupe', border: InputBorder.none, prefixIcon: Icon(Icons.group, color: Color(0xFFEF4444))),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('-- Aucun groupe --')),
                          ..._groupes.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['nom'].toString()))),
                        ],
                        onChanged: (v) => setState(() => _groupeSelectionne = v),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Contact ──────────────────────────────────────
            _sectionHeader('Contact', Icons.contact_phone),
            _buildField(_telCtrl, 'Téléphone', Icons.phone, type: TextInputType.phone, inputFormatters: [PhoneSeparatorFormatter()]),
            _buildField(_emailCtrl, 'Email', Icons.email, type: TextInputType.emailAddress),
            const SizedBox(height: 16),

            // ─── Localisation ─────────────────────────────────
            _sectionHeader('Localisation', Icons.location_on),
            _buildField(_villeCtrl, 'Ville', Icons.location_city),
            _buildField(_paysCtrl, 'Pays', Icons.flag),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _quartierSelectionne,
                  decoration: const InputDecoration(labelText: 'Quartier', border: InputBorder.none, prefixIcon: Icon(Icons.home, color: Color(0xFFEF4444))),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('-- Choisir un quartier --')),
                    ..._quartiers.map((q) => DropdownMenuItem(value: q, child: Text(q))),
                  ],
                  onChanged: (v) => setState(() {
                    _quartierSelectionne = v;
                    if (v != 'Autre') _quartierCtrl.clear();
                  }),
                ),
              ),
            ),
            if (_quartierSelectionne == 'Autre') ...[
              const SizedBox(height: 12),
              _buildField(_quartierCtrl, 'Précisez le quartier', Icons.edit),
            ],
            const SizedBox(height: 16),

            // ─── Autres ───────────────────────────────────────
            _sectionHeader('Informations complémentaires', Icons.info_outline),
            _buildField(_profCtrl, 'Profession', Icons.work),
            _buildField(_familleCtrl, 'Famille', Icons.family_restroom),
            const SizedBox(height: 24),

            // Bouton bas de page
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer le Membre',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 18, color: const Color(0xFFEF4444)),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
    ]),
  );

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool required = false,
    TextCapitalization capitalization = TextCapitalization.none,
    List<dynamic> inputFormatters = const [],
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: TextFormField(
            controller: ctrl,
            keyboardType: type,
            textCapitalization: capitalization,
            inputFormatters: inputFormatters.cast(),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: const Color(0xFFEF4444), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est obligatoire' : null
                : null,
          ),
        ),
      );
}
