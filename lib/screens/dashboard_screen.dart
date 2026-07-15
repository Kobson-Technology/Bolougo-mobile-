import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'membres_screen.dart';
import 'cotisations_screen.dart';
import 'finances_screen.dart';
import 'stats_screen.dart';
import '../models/slide.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../utils/permissions.dart';
import '../utils/formatters.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Stats
  int _totalMembres = 0;
  int _totalCampagnes = 0;
  double _soldeNet = 0;
  List<Slide> _slides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await Future.wait([
        api.client.get('/membres'),
        api.client.get('/cotisations'),
        api.client.get('/finances/resume'),
        api.client.get('/slides'),
      ]);
      setState(() {
        _totalMembres = (results[0].data as List).length;
        _totalCampagnes = (results[1].data as List).length;
        _soldeNet = (results[2].data['soldeNet'] ?? 0).toDouble();
        _slides = (results[3].data as List).map((e) => Slide.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthService>(context).currentUser?['role'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFFEF4444),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_slides.isNotEmpty)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 250,
                        viewportFraction: 1.0,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 4),
                      ),
                      items: _slides.map((slide) {
                        return Image.network(
                          slide.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFEF4444)),
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  // Dark overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bolougô Admin', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                Text('Tableau de bord', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        Row(
                          children: [
                            Expanded(child: _statCard('Membres', '$_totalMembres', Icons.people, const Color(0xFFEF4444))),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard('Campagnes', '$_totalCampagnes', Icons.payments, const Color(0xFF10B981))),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard('Solde', formatMontant(_soldeNet), Icons.account_balance, const Color(0xFFF59E0B))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Quick Access Title
                        const Text('Accès Rapide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        const SizedBox(height: 12),

                        // Grid of modules
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            if (Permissions.hasAccess(role, 'MEMBRES'))
                              _moduleCard(
                                icon: Icons.people,
                                title: 'Membres',
                                subtitle: '$_totalMembres inscrits',
                                color: const Color(0xFFEF4444),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MembresScreen())),
                              ),
                            if (Permissions.hasAccess(role, 'COTISATIONS'))
                              _moduleCard(
                                icon: Icons.payments,
                                title: 'Cotisations',
                                subtitle: '$_totalCampagnes campagnes',
                                color: const Color(0xFF10B981),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CotisationsScreen())),
                              ),
                            if (Permissions.hasAccess(role, 'FINANCES'))
                              _moduleCard(
                                icon: Icons.account_balance,
                                title: 'Finances',
                                subtitle: 'Voir la trésorerie',
                                color: const Color(0xFFF59E0B),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinancesScreen())),
                              ),
                            if (Permissions.hasAccess(role, 'DASHBOARD'))
                              _moduleCard(
                                icon: Icons.bar_chart,
                                title: 'Rapports',
                                subtitle: 'Statistiques',
                                color: const Color(0xFF6366F1),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }


  Widget _statCard(String label, String value, IconData icon, Color color) => Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    ),
  );

  Widget _moduleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 26),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
