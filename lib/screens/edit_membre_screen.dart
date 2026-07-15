import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/membre.dart';

class EditMembreScreen extends StatefulWidget {
  final MembreDetail membre;

  const EditMembreScreen({super.key, required this.membre});

  @override
  State<EditMembreScreen> createState() => _EditMembreScreenState();
}

class _EditMembreScreenState extends State<EditMembreScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomsCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _villeCtrl;
  late final TextEditingController _paysCtrl;
  late final TextEditingController _profCtrl;
  late final TextEditingController _quartierCtrl;
  late final TextEditingController _familleCtrl;
  String? _sexe;
  String? _quartierSelectionne;
  final List<String> _quartiers = ['Dissaninhouo', 'Douopeli', 'Gbadihouo', 'Glahouo', 'Autre'];

  @override
  void initState() {
    super.initState();
    final m = widget.membre;
    _nomCtrl = TextEditingController(text: m.nom);
    _prenomsCtrl = TextEditingController(text: m.prenoms);
    _telCtrl = TextEditingController(text: m.telephone ?? '');
    _emailCtrl = TextEditingController(text: m.email ?? '');
    _villeCtrl = TextEditingController(text: m.ville ?? '');
    _paysCtrl = TextEditingController(text: m.pays ?? '');
    _profCtrl = TextEditingController(text: m.profession ?? '');
    _quartierCtrl = TextEditingController();
    if (m.quartier != null && m.quartier!.isNotEmpty) {
      if (_quartiers.contains(m.quartier)) {
        _quartierSelectionne = m.quartier;
      } else {
        _quartierSelectionne = 'Autre';
        _quartierCtrl.text = m.quartier!;
      }
    }
    _familleCtrl = TextEditingController(text: m.famille ?? '');
    _sexe = m.sexe;
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
      await api.client.put('/membres/${widget.membre.id}', data: {
        'nom': _nomCtrl.text.trim().toUpperCase(),
        'prenoms': _prenomsCtrl.text.trim().toUpperCase(),
        'telephone': _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'sexe': _sexe,
        'ville': _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
        'pays': _paysCtrl.text.trim().isEmpty ? null : _paysCtrl.text.trim(),
        'profession': _profCtrl.text.trim().isEmpty ? null : _profCtrl.text.trim(),
        'quartier': _quartierSelectionne == 'Autre'
            ? (_quartierCtrl.text.trim().isEmpty ? null : _quartierCtrl.text.trim())
            : _quartierSelectionne,
        'famille': _familleCtrl.text.trim().isEmpty ? null : _familleCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Membre mis à jour !'), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.of(context).pop(true);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Modifier ${widget.membre.nomComplet}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
            const SizedBox(height: 16),

            _sectionHeader('Contact', Icons.contact_phone),
            _buildField(_telCtrl, 'Téléphone', Icons.phone, type: TextInputType.phone),
            _buildField(_emailCtrl, 'Email', Icons.email, type: TextInputType.emailAddress),
            const SizedBox(height: 16),

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

            _sectionHeader('Informations complémentaires', Icons.info_outline),
            _buildField(_profCtrl, 'Profession', Icons.work),
            _buildField(_familleCtrl, 'Famille', Icons.family_restroom),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
