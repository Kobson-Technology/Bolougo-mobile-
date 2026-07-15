import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final r = await api.client.get('/stats/dashboard');
      setState(() {
        _stats = r.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les statistiques.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Statistiques', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6366F1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() { _isLoading = true; _error = null; _stats = null; _fetchStats(); }),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => setState(() { _isLoading = true; _error = null; _fetchStats(); }), child: const Text('Réessayer')),
                ]))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ─── Membres ─────────────────────────────────────────
                    _sectionTitle('👥 Membres', const Color(0xFFEF4444)),
                    Row(children: [
                      Expanded(child: _kpiCard('Total', '${_stats!['membres']['total']}', Icons.people, const Color(0xFFEF4444))),
                      const SizedBox(width: 10),
                      Expanded(child: _kpiCard('Hommes', '${_stats!['membres']['hommes']}', Icons.man, const Color(0xFF3B82F6))),
                      const SizedBox(width: 10),
                      Expanded(child: _kpiCard('Femmes', '${_stats!['membres']['femmes']}', Icons.woman, const Color(0xFFEC4899))),
                    ]),
                    const SizedBox(height: 12),
                    _buildVilleChart(),

                    const SizedBox(height: 20),
                    // ─── Cotisations ─────────────────────────────────────
                    _sectionTitle('💳 Cotisations', const Color(0xFF10B981)),
                    Row(children: [
                      Expanded(child: _kpiCard('Campagnes', '${_stats!['cotisations']['totalCampagnes']}', Icons.campaign, const Color(0xFF10B981))),
                      const SizedBox(width: 10),
                      Expanded(child: _kpiCard('Actives', '${_stats!['cotisations']['campagnesActives']}', Icons.check_circle, const Color(0xFF059669))),
                      const SizedBox(width: 10),
                      Expanded(child: _kpiCard('Paiements', '${_stats!['cotisations']['totalPaiements']}', Icons.receipt, const Color(0xFF6366F1))),
                    ]),

                    const SizedBox(height: 20),
                    // ─── Finances ─────────────────────────────────────────
                    _sectionTitle('💰 Finances', const Color(0xFFF59E0B)),
                    _financeBar(),

                    const SizedBox(height: 20),
                    // ─── Évolution ────────────────────────────────────────
                    _sectionTitle('📈 Évolution des Paiements', const Color(0xFF6366F1)),
                    _buildEvolutionChart(),

                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _sectionTitle(String title, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _kpiCard(String label, String value, IconData icon, Color color) => Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ]),
    ),
  );

  Widget _buildVilleChart() {
    final parVille = List<Map<String, dynamic>>.from(_stats!['membres']['parVille'] ?? []);
    if (parVille.isEmpty) return const SizedBox.shrink();
    final maxCount = parVille.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Membres par Quartier (Top 5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...parVille.map((v) {
              final pct = maxCount > 0 ? (v['count'] as int) / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(width: 90, child: Text(v['quartier'] ?? v['ville'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      minHeight: 14,
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      color: const Color(0xFFEF4444),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Text('${v['count']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _financeBar() {
    final f = _stats!['finances'];
    final collecte = (f['totalCollecte'] ?? 0).toDouble();
    final dons = (f['totalDons'] ?? 0).toDouble();
    final depenses = (f['totalDepenses'] ?? 0).toDouble();
    final solde = (f['soldeNet'] ?? 0).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _financeRow('Cotisations collectées', collecte, const Color(0xFF10B981), Icons.payments),
          _financeRow('Dons reçus', dons, const Color(0xFF3B82F6), Icons.favorite),
          _financeRow('Dépenses', depenses, const Color(0xFFEF4444), Icons.arrow_upward),
          const Divider(height: 20),
          _financeRow('Solde Net', solde, solde >= 0 ? const Color(0xFF059669) : const Color(0xFFEF4444), Icons.account_balance, bold: true),
        ]),
      ),
    );
  }

  Widget _financeRow(String label, double amount, Color color, IconData icon, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 15 : 13))),
      Text('${amount.toStringAsFixed(0)} F', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: bold ? 16 : 13)),
    ]),
  );

  Widget _buildEvolutionChart() {
    final evolution = List<Map<String, dynamic>>.from(_stats!['evolution'] ?? []);
    if (evolution.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aucune donnée pour les 12 derniers mois', style: TextStyle(color: Colors.grey)))),
      );
    }
    final maxTotal = evolution.map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: evolution.map((e) {
                  final pct = maxTotal > 0 ? (e['total'] as num).toDouble() / maxTotal : 0.0;
                  final moisIndex = (e['mois'] as int) - 1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 30,
                            height: (pct * 120).clamp(4.0, 120.0),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(months[moisIndex], style: const TextStyle(fontSize: 9, color: Colors.black45)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
