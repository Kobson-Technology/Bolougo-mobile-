import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/finance.dart';
import '../utils/formatters.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FinanceResume? _resume;
  List<Depense> _depenses = [];
  List<Don> _dons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await Future.wait([
        api.client.get('/finances/resume'),
        api.client.get('/finances/depenses'),
        api.client.get('/finances/dons'),
      ]);
      setState(() {
        _resume = FinanceResume.fromJson(results[0].data);
        _depenses = (results[1].data as List).map((j) => Depense.fromJson(j)).toList();
        _dons = (results[2].data as List).map((j) => Don.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFFF59E0B),
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Finances & Trésorerie', style: TextStyle(color: Colors.white, fontSize: 18)),
            flexibleSpace: FlexibleSpaceBar(
              background: _resume == null
                  ? Container(color: const Color(0xFFF59E0B))
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60), // Add top padding to clear the AppBar title
                          const Text('Solde Net', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Text(
                            formatMontant(_resume!.soldeNet),
                            style: TextStyle(
                              color: _resume!.soldeNet >= 0 ? Colors.white : Colors.red[200],
                              fontSize: 34, fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _miniStat('Entrées', _resume!.totalEntrees, const Color(0xFFD1FAE5)),
                              _miniStat('Sorties', _resume!.totalSorties, const Color(0xFFFEE2E2)),
                            ],
                          ),
                          const SizedBox(height: 30), // Padding to keep clear of TabBar
                        ],
                      ),
                    ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart), text: 'Résumé'),
                Tab(icon: Icon(Icons.arrow_upward), text: 'Dépenses'),
                Tab(icon: Icon(Icons.volunteer_activism), text: 'Dons'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildResume(),
                  _buildDepenses(),
                  _buildDons(),
                ],
              ),
      ),
    );
  }

  Widget _miniStat(String label, double val, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: bg.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Text(formatMontant(val), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildResume() {
    if (_resume == null) return const Center(child: Text('Aucune donnée'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard('Cotisations collectées', _resume!.totalCotisations, const Color(0xFF10B981), Icons.payments),
        _summaryCard('Dons reçus', _resume!.totalDons, const Color(0xFF3B82F6), Icons.volunteer_activism),
        _summaryCard('Total Dépenses', _resume!.totalSorties, const Color(0xFFEF4444), Icons.arrow_upward),
        _summaryCard('Solde Net Final', _resume!.soldeNet, const Color(0xFFF59E0B), Icons.account_balance, isLarge: true),
      ],
    );
  }

  Widget _buildDepenses() => _depenses.isEmpty
      ? const Center(child: Text('Aucune dépense enregistrée'))
      : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _depenses.length,
          itemBuilder: (_, i) {
            final d = _depenses[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1), child: const Icon(Icons.remove_circle, color: Color(0xFFEF4444))),
                title: Text(d.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${d.categorie ?? 'Sans catégorie'} • ${d.date.split('T').first}'),
                trailing: Text('-${formatMontant(d.montant, withSuffix: false)} F', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              ),
            );
          });

  Widget _buildDons() => _dons.isEmpty
      ? const Center(child: Text('Aucun don enregistré'))
      : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _dons.length,
          itemBuilder: (_, i) {
            final d = _dons[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1), child: const Icon(Icons.favorite, color: Color(0xFF3B82F6))),
                title: Text(d.donateur, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(d.date.split('T').first),
                trailing: Text('+${formatMontant(d.montant, withSuffix: false)} F', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
              ),
            );
          });

  Widget _summaryCard(String title, double amount, Color color, IconData icon, {bool isLarge = false}) => Card(
    elevation: 3,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: isLarge ? 32 : 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
            Text(formatMontant(amount), style: TextStyle(fontSize: isLarge ? 22 : 18, fontWeight: FontWeight.bold, color: color)),
          ])),
        ],
      ),
    ),
  );
}
