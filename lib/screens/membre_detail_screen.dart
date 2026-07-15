import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/membre.dart';
import '../utils/formatters.dart';

class MembreDetailScreen extends StatefulWidget {
  final int membreId;
  final String nomComplet;

  const MembreDetailScreen({super.key, required this.membreId, required this.nomComplet});

  @override
  State<MembreDetailScreen> createState() => _MembreDetailScreenState();
}

class _MembreDetailScreenState extends State<MembreDetailScreen> {
  MembreDetail? _membre;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final r = await api.client.get('/membres/${widget.membreId}');
      setState(() { _membre = MembreDetail.fromJson(r.data); _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Impossible de charger les données du membre.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _error != null
              ? Center(child: Text(_error!))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: const Color(0xFFEF4444),
                      iconTheme: const IconThemeData(color: Colors.white),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(widget.nomComplet, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, size: 80, color: Colors.white30),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionCard('Informations Personnelles', [
                              _infoRow(Icons.badge, 'Sexe', _membre!.sexe ?? 'N/A'),
                              _infoRow(Icons.phone, 'Téléphone', formatPhone(_membre!.telephone) ?? 'N/A'),
                              _infoRow(Icons.email, 'Email', _membre!.email ?? 'N/A'),
                              _infoRow(Icons.work, 'Profession', _membre!.profession ?? 'N/A'),
                            ]),
                            const SizedBox(height: 16),
                            _sectionCard('Localisation', [
                              _infoRow(Icons.location_city, 'Ville', _membre!.ville ?? 'N/A'),
                              _infoRow(Icons.flag, 'Pays', _membre!.pays ?? 'N/A'),
                              _infoRow(Icons.home, 'Quartier', _membre!.quartier ?? 'N/A'),
                              _infoRow(Icons.family_restroom, 'Famille', _membre!.famille ?? 'N/A'),
                            ]),
                            const SizedBox(height: 16),
                            _buildPaiementsSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPaiementsSection() {
    final paiements = _membre!.paiements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historique des Paiements (${paiements.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        if (paiements.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Aucun paiement enregistré', style: TextStyle(color: Colors.grey))),
            ),
          )
        else
          ...paiements.map((p) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                child: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              ),
              title: Text(p['motif'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p['modePaiement'] ?? 'N/A'} • ${(p['datePaiement'] ?? '').toString().split('T').first}'),
              trailing: Text(formatMontant((p['montant'] as num?)?.toDouble()), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            ),
          )),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
