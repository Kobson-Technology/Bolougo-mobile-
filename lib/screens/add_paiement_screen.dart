import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class AddPaiementScreen extends StatefulWidget {
  final int cotisationId;
  final String titreCotisation;

  const AddPaiementScreen(
      {super.key, required this.cotisationId, required this.titreCotisation});

  @override
  State<AddPaiementScreen> createState() => _AddPaiementScreenState();
}

class _AddPaiementScreenState extends State<AddPaiementScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingMembres = true;

  List<Map<String, dynamic>> _membres = [];
  List<Map<String, dynamic>> _filteredMembres = [];
  Map<String, dynamic>? _selectedMembre;
  final _searchCtrl = TextEditingController();
  bool _showDropdown = false;

  final _montantCtrl = TextEditingController();
  String _modePaiement = 'Espèces';

  @override
  void initState() {
    super.initState();
    _fetchMembres();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _showDropdown = query.isNotEmpty;
      _filteredMembres = _membres.where((m) {
        final name = '${m['nom']} ${m['prenoms']}'.toLowerCase();
        return name.contains(query);
      }).take(8).toList();
    });
  }

  Future<void> _fetchMembres() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final r = await api.client.get('/membres');
      setState(() {
        _membres = List<Map<String, dynamic>>.from(r.data);
        _isLoadingMembres = false;
      });
    } catch (e) {
      setState(() => _isLoadingMembres = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMembre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un membre'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);

    try {
      await api.client.post('/cotisations/${widget.cotisationId}/paiements',
          data: {
            'membreId': _selectedMembre!['id'],
            'montant': parseMontant(_montantCtrl.text),
            'modePaiement': _modePaiement,
            'datePaiement': DateTime.now().toIso8601String(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Paiement enregistré !'),
              backgroundColor: Color(0xFF10B981)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'), backgroundColor: Colors.red),
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
        title: const Text('Enregistrer un Paiement',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingMembres
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : GestureDetector(
              onTap: () => setState(() => _showDropdown = false),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Campaign header
                    Card(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          const Icon(Icons.campaign, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(widget.titreCotisation,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Searchable member field ───────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              // Selected member display OR search field
                              if (_selectedMembre != null && !_showDropdown)
                                ListTile(
                                  leading: const Icon(Icons.person,
                                      color: Color(0xFF10B981)),
                                  title: Text(
                                    '${_selectedMembre!['nom']} ${_selectedMembre!['prenoms']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle:
                                      const Text('Membre sélectionné'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _selectedMembre = null;
                                        _searchCtrl.clear();
                                      });
                                    },
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: TextFormField(
                                    controller: _searchCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Rechercher un membre *',
                                      prefixIcon: Icon(Icons.search,
                                          color: Color(0xFF10B981)),
                                      border: InputBorder.none,
                                      hintText: 'Tapez un nom...',
                                    ),
                                    onTap: () {
                                      if (_searchCtrl.text.isNotEmpty) {
                                        setState(
                                            () => _showDropdown = true);
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Dropdown results
                        if (_showDropdown && _filteredMembres.isNotEmpty)
                          Card(
                            margin: const EdgeInsets.only(top: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 6,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 250),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                itemCount: _filteredMembres.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final m = _filteredMembres[i];
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF10B981)
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        (m['nom'] as String? ?? '?')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                        '${m['nom']} ${m['prenoms']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                        formatPhone(m['telephone']
                                            ?.toString())),
                                    onTap: () {
                                      setState(() {
                                        _selectedMembre = m;
                                        _searchCtrl.text =
                                            '${m['nom']} ${m['prenoms']}';
                                        _showDropdown = false;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        if (_showDropdown && _filteredMembres.isEmpty)
                          Card(
                            margin: const EdgeInsets.only(top: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: Text('Aucun membre trouvé',
                                      style:
                                          TextStyle(color: Colors.grey))),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Montant ──────────────────────────────────
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: TextFormField(
                        controller: _montantCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandSeparatorFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Montant (F CFA) *',
                          prefixIcon: Icon(Icons.payments,
                              color: Color(0xFF10B981)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Entrez un montant';
                          final parsed = parseMontant(v);
                          if (parsed <= 0) return 'Montant invalide';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Mode paiement ────────────────────────────
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: DropdownButtonFormField<String>(
                          value: _modePaiement,
                          decoration: const InputDecoration(
                            labelText: 'Mode de Paiement',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.credit_card,
                                color: Color(0xFF10B981)),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Espèces', child: Text('Espèces')),
                            DropdownMenuItem(
                                value: 'Mobile Money',
                                child: Text('Mobile Money')),
                            DropdownMenuItem(
                                value: 'Virement',
                                child: Text('Virement bancaire')),
                            DropdownMenuItem(
                                value: 'Chèque', child: Text('Chèque')),
                          ],
                          onChanged: (v) =>
                              setState(() => _modePaiement = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded,
                                color: Colors.white),
                        label: Text(
                            _isLoading
                                ? 'Enregistrement...'
                                : 'Valider le Paiement',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
