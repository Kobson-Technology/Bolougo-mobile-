import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/cotisation.dart';
import '../utils/formatters.dart';
import 'cotisation_detail_screen.dart';
import 'add_cotisation_screen.dart';

class CotisationsScreen extends StatefulWidget {
  const CotisationsScreen({super.key});

  @override
  State<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends State<CotisationsScreen> {
  List<MotifCotisation> _campagnes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCotisations();
  }

  Future<void> _fetchCotisations() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.client.get('/cotisations');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _campagnes = data.map((json) => MotifCotisation.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les campagnes.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotisations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCotisationScreen()),
          );
          if (res == true) _fetchCotisations();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _errorMessage != null
              ? _buildError()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _campagnes.length,
                  itemBuilder: (context, index) {
                    final c = _campagnes[index];
                    final isActif = c.statut.toLowerCase() == 'actif';
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (c.password != null && c.password!.isNotEmpty) {
                            _showPasswordDialog(context, c);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CotisationDetailScreen(cotisationId: c.id, titre: c.titre)),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(c.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActif ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(c.statut, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActif ? const Color(0xFF10B981) : Colors.grey)),
                                  ),
                                ],
                              ),
                              if (c.description != null) ...[
                                const SizedBox(height: 6),
                                Text(c.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _statChip(Icons.payments, formatMontant(c.totalCollecte), const Color(0xFF10B981)),
                                  const SizedBox(width: 12),
                                  _statChip(Icons.people, '${c.nombrePaiements} paiements', const Color(0xFF3B82F6)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    ],
  );

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: () { setState(() { _isLoading = true; _errorMessage = null; }); _fetchCotisations(); }, child: const Text('Réessayer')),
    ]),
  );

  void _showPasswordDialog(BuildContext context, MotifCotisation c) {
    final pwdCtrl = TextEditingController();
    String? error;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Mot de passe requis', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Veuillez entrer le mot de passe pour accéder à cette campagne.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pwdCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      errorText: error,
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pwdCtrl.text == c.password) {
                      Navigator.of(ctx).pop();
                      Navigator.of(this.context).push(
                        MaterialPageRoute(builder: (_) => CotisationDetailScreen(cotisationId: c.id, titre: c.titre)),
                      );
                    } else {
                      setState(() => error = 'Mot de passe incorrect');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Valider', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
