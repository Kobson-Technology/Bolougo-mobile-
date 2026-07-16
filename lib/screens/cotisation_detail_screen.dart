import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/cotisation.dart';
import '../utils/formatters.dart';
import 'add_paiement_screen.dart';

class ConsolidatedMembre {
  final Map<String, dynamic> membre;
  final List<Map<String, dynamic>> sesPaiements;
  final double totalPaye;
  final double montantAttendu;
  final double resteAPayer;
  final String statut;
  final Color color;
  final String nomGroupe;

  ConsolidatedMembre({
    required this.membre,
    required this.sesPaiements,
    required this.totalPaye,
    required this.montantAttendu,
    required this.resteAPayer,
    required this.statut,
    required this.color,
    required this.nomGroupe,
  });
}

class CotisationDetailScreen extends StatefulWidget {
  final int cotisationId;
  final String titre;

  const CotisationDetailScreen(
      {super.key, required this.cotisationId, required this.titre});

  @override
  State<CotisationDetailScreen> createState() => _CotisationDetailScreenState();
}

class _CotisationDetailScreenState extends State<CotisationDetailScreen> {
  CotisationDetail? _detail;
  List<ConsolidatedMembre> _membresConsolides = [];
  double _totalAttendu = 0;
  double _totalResteAPayer = 0;
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
      // 1. Cotisation detail (required)
      final r = await api.client.get('/cotisations/${widget.cotisationId}');
      final detail = CotisationDetail.fromJson(r.data as Map<String, dynamic>);

      // 2. All members (required)
      final mRes = await api.client.get('/membres');
      final tousLesMembres =
          List<Map<String, dynamic>>.from(mRes.data as List);

      // 3. Groups (optional — skip if it fails, e.g. serialisation 500)
      List<Map<String, dynamic>> lesGroupes = [];
      try {
        final gRes = await api.client.get('/groupes');
        lesGroupes = List<Map<String, dynamic>>.from(gRes.data as List);
      } catch (_) {
        // continue without group names
      }

      final List<ConsolidatedMembre> list = [];
      double att = 0;
      double reste = 0;

      for (var membre in tousLesMembres) {
        final membreId = membre['id'] as int;
        final groupeId = membre['groupeId'] as int?;

        // Payments for this member in this cotisation
        final sesPaiements = detail.paiements
            .where((p) => p['membreId'] == membreId)
            .toList();
        final totalPaye = sesPaiements.fold<double>(
            0, (s, p) => s + (p['montant'] as num).toDouble());

        // Expected amount from paliers (only if API change is deployed)
        double montantAttendu = 0;
        if (groupeId != null && detail.montants.isNotEmpty) {
          final palier =
              detail.montants.where((m) => m['groupeId'] == groupeId).toList();
          if (palier.isNotEmpty) {
            montantAttendu = (palier.first['montant'] as num).toDouble();
          }
        }

        final resteAPayer =
            montantAttendu > 0 ? montantAttendu - totalPaye : 0.0;

        String statut;
        Color color;
        if (montantAttendu > 0) {
          if (resteAPayer <= 0) {
            statut = '🟢 Soldé';
            color = const Color(0xFF10B981);
          } else if (totalPaye > 0) {
            statut = '🟡 Partiel';
            color = const Color(0xFFF59E0B);
          } else {
            statut = '🔴 Non payé';
            color = const Color(0xFFEF4444);
          }
        } else {
          statut = totalPaye > 0 ? '🟢 A payé' : '⚪ En attente';
          color = totalPaye > 0 ? const Color(0xFF10B981) : Colors.grey;
        }

        String nomGroupe = groupeId != null ? 'Groupe $groupeId' : 'Sans groupe';
        if (groupeId != null && lesGroupes.isNotEmpty) {
          final g = lesGroupes.where((g) => g['id'] == groupeId).toList();
          if (g.isNotEmpty) nomGroupe = g.first['nom']?.toString() ?? nomGroupe;
        }

        if (totalPaye > 0 || montantAttendu > 0) {
          list.add(ConsolidatedMembre(
            membre: membre,
            sesPaiements: sesPaiements,
            totalPaye: totalPaye,
            montantAttendu: montantAttendu,
            resteAPayer: resteAPayer,
            statut: statut,
            color: color,
            nomGroupe: nomGroupe,
          ));
          att += montantAttendu;
          if (resteAPayer > 0) reste += resteAPayer;
        }
      }

      // Fallback: if no consolidated data, show payers directly from detail
      if (list.isEmpty && detail.paiements.isNotEmpty) {
        for (var p in detail.paiements) {
          final membreNom = p['membre']?.toString() ?? 'Inconnu';
          list.add(ConsolidatedMembre(
            membre: {'id': p['membreId'], 'nom': membreNom, 'prenoms': ''},
            sesPaiements: [p],
            totalPaye: (p['montant'] as num).toDouble(),
            montantAttendu: 0,
            resteAPayer: 0,
            statut: '🟢 A payé',
            color: const Color(0xFF10B981),
            nomGroupe: '-',
          ));
        }
      }

      list.sort((a, b) => (a.membre['nom'] ?? '')
          .toString()
          .compareTo((b.membre['nom'] ?? '').toString()));

      setState(() {
        _detail = detail;
        _membresConsolides = list;
        _totalAttendu = att;
        _totalResteAPayer = reste;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onAddPaiement() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => AddPaiementScreen(
                cotisationId: widget.cotisationId,
                titreCotisation: widget.titre,
              )),
    );
    if (result == true) {
      setState(() {
        _detail = null;
        _isLoading = true;
      });
      await _fetch();
    }
  }

  Future<void> _cloturerCampagne() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment clôturer cette campagne ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF92400e), foregroundColor: Colors.white),
            child: const Text('Clôturer')
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final api = Provider.of<ApiService>(context, listen: false);
        await api.client.put('/cotisations/${widget.cotisationId}/cloturer');
        await _fetch();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _genererTexte() {
    final soldes = _membresConsolides.where((m) => m.resteAPayer <= 0 && m.totalPaye > 0).toList();
    final partiels = _membresConsolides.where((m) => m.resteAPayer > 0 && m.totalPaye > 0).toList();
    final nonPayes = _membresConsolides.where((m) => m.totalPaye == 0 && m.montantAttendu > 0).toList();
    
    final participantsSet = <String>{};
    for (var m in [...soldes, ...partiels]) {
      participantsSet.add("${m.membre['nom']} ${m.membre['prenoms']}");
    }
    
    String texte = "🏦 *RAPPORT DE COTISATION*\n";
    texte += "📌 *${widget.titre}*\n";
    if (_detail!.description != null && _detail!.description!.isNotEmpty) {
      texte += "${_detail!.description}\n";
    }
    final dateStr = DateTime.now().toLocal().toString().split(' ')[0];
    texte += "📅 $dateStr\n\n";
    
    final sep = "─────────────────────────";
    texte += "$sep\n📊 *RÉSUMÉ*\n$sep\n";
    texte += "💰 Total attendu: ${formatMontant(_totalAttendu)}\n";
    texte += "✅ Total récolté: ${formatMontant(_detail!.totalCollecte)}\n";
    texte += "⏳ Reste à payer: ${formatMontant(_totalResteAPayer)}\n";
    texte += "👥 Participants: ${participantsSet.length}\n";

    Map<String, List<ConsolidatedMembre>> grouper(List<ConsolidatedMembre> liste) {
      final map = <String, List<ConsolidatedMembre>>{};
      for (var m in liste) {
        if (!map.containsKey(m.nomGroupe)) map[m.nomGroupe] = [];
        map[m.nomGroupe]!.add(m);
      }
      return map;
    }

    if (soldes.isNotEmpty) {
      texte += "\n$sep\n✅ *SOLDÉS (${soldes.length})*\n$sep\n\n";
      final g = grouper(soldes);
      g.forEach((groupe, membres) {
        final m = membres.first.montantAttendu;
        texte += "*$groupe* : ${formatMontant(m)} :\n\n";
        for (var mb in membres) {
          texte += "• ${mb.membre['nom']} ${mb.membre['prenoms']}\n\n";
        }
      });
    }

    if (partiels.isNotEmpty) {
      texte += "\n$sep\n🟡 *PARTIELS (${partiels.length})*\n$sep\n\n";
      final g = grouper(partiels);
      g.forEach((groupe, membres) {
        final m = membres.first.montantAttendu;
        texte += "*$groupe* : ${formatMontant(m)} :\n\n";
        for (var mb in membres) {
          texte += "• ${mb.membre['nom']} ${mb.membre['prenoms']} — Payé: ${formatMontant(mb.totalPaye)} / Reste: ${formatMontant(mb.resteAPayer)}\n\n";
        }
      });
    }

    texte += "\n_Rapport généré depuis Bolougô App Mobile_";
    return texte;
  }

  String _genererRappelTexte() {
    final nonPayes = _membresConsolides.where((m) => m.totalPaye == 0 && m.montantAttendu > 0).toList();
    
    String texte = "⚠️ *RAPPEL DE COTISATION*\n📌 *${widget.titre}*\n";
    if (_detail!.description != null && _detail!.description!.isNotEmpty) {
      texte += "${_detail!.description}\n";
    }
    final dateStr = DateTime.now().toLocal().toString().split(' ')[0];
    texte += "📅 $dateStr\n\n";
    
    final sep = "─────────────────────────";
    texte += "$sep\nBonjour à tous,\nVoici le rappel pour les membres qui n'ont pas encore réglé leur cotisation.\nMerci de vous mettre à jour dans les meilleurs délais 🙏\n";
    
    if (nonPayes.isNotEmpty) {
      texte += "\n$sep\n🔴 *NON PAYÉS (${nonPayes.length})*\n$sep\n\n";
      Map<String, List<ConsolidatedMembre>> grouper(List<ConsolidatedMembre> liste) {
        final map = <String, List<ConsolidatedMembre>>{};
        for (var m in liste) {
          if (!map.containsKey(m.nomGroupe)) map[m.nomGroupe] = [];
          map[m.nomGroupe]!.add(m);
        }
        return map;
      }
      final g = grouper(nonPayes);
      g.forEach((groupe, membres) {
        final m = membres.first.montantAttendu;
        texte += "*$groupe* : ${formatMontant(m)} à régler\n\n";
        for (var mb in membres) {
          texte += "• ${mb.membre['nom']} ${mb.membre['prenoms']}\n\n";
        }
      });
    } else {
      texte += "\n✅ Aucun membre n'est dans la liste des \"Non Payés\" pour cette cotisation.\n";
    }

    texte += "\n_Rapport généré depuis Bolougô App Mobile_";
    return texte;
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_detail!.statut != 'TERMINE' && _detail!.statut != 'CLOTURE') ...[
            ElevatedButton.icon(
              onPressed: _cloturerCampagne,
              icon: const Icon(Icons.lock_outline, size: 17),
              label: const Text('Cloturer la campagne', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF92400e),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _genererTexte()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rapport payes copie !'), backgroundColor: Color(0xFF334155)),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: const Text('Rapport\npayes', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _genererRappelTexte()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rapport non payes copie !'), backgroundColor: Color(0xFFf59e0b)),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: const Text('Rapport\nNon payes', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf59e0b),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: Text(widget.titre,
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            iconTheme: const IconThemeData(color: Colors.white)),
        body:
            const Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(widget.titre,
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() { _isLoading = true; _error = null; });
                        _fetch();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white),
                    ),
                  ],
                ))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      floatingActionButton: _detail != null && _detail!.statut == 'EN_COURS'
          ? FloatingActionButton.extended(
              onPressed: _onAddPaiement,
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter Paiement',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: const Color(0xFF10B981),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(widget.titre,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
              ),
            ),
          ),
          // Fixed KPI bar — never scrolls away
          SliverPersistentHeader(
            pinned: true,
            delegate: _KpiHeaderDelegate(
              totalAttendu: _totalAttendu,
              totalCollecte: _detail!.totalCollecte,
              resteAPayer: _totalResteAPayer,
            ),
          ),
        ],
        body: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_detail!.description != null)
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_detail!.description!,
                            style: const TextStyle(color: Colors.black54)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  _buildActionButtons(),

                  Text(
                      'Suivi des paiements (${_membresConsolides.length} membres)',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_membresConsolides.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child: Text(
                                "Aucun paiement enregistré pour cette campagne.",
                                style: TextStyle(color: Colors.grey))),
                      ),
                    )
                  else
                    ..._membresConsolides.map((data) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${data.membre['nom'] ?? ''} ${data.membre['prenoms'] ?? ''}'
                                            .trim(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: data.color
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(data.statut,
                                          style: TextStyle(
                                              color: data.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius:
                                          BorderRadius.circular(4)),
                                  child: Text(data.nomGroupe,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54)),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMoneyCol('Attendu',
                                        data.montantAttendu, Colors.black54),
                                    _buildMoneyBadge(
                                        'Payé',
                                        data.totalPaye,
                                        data.totalPaye > 0
                                            ? const Color(0xFF10B981)
                                            : Colors.grey),
                                    _buildMoneyBadge(
                                        'Reste',
                                        data.resteAPayer,
                                        data.resteAPayer > 0
                                            ? Colors.red
                                            : Colors.grey),
                                  ],
                                ),
                                if (data.sesPaiements.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                      '${data.sesPaiements.length} versement(s)',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey)),
                                ]
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyCol(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(amount > 0 ? formatMontant(amount) : '-',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildMoneyBadge(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            amount > 0 ? formatMontant(amount) : '-',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color),
          ),
        ),
      ],
    );
  }
}

// ── Persistent KPI header delegate ──────────────────────────────────────────
class _KpiHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double totalAttendu;
  final double totalCollecte;
  final double resteAPayer;

  _KpiHeaderDelegate({
    required this.totalAttendu,
    required this.totalCollecte,
    required this.resteAPayer,
  });

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  bool shouldRebuild(_KpiHeaderDelegate old) =>
      old.totalAttendu != totalAttendu ||
      old.totalCollecte != totalCollecte ||
      old.resteAPayer != resteAPayer;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF059669),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _kpi('Attendu', totalAttendu, Colors.white70),
          _divider(),
          _kpi('Récolté', totalCollecte, Colors.white),
          _divider(),
          _kpi('Reste', resteAPayer, Colors.red[200]!),
        ],
      ),
    );
  }

  Widget _kpi(String label, double amount, Color color) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(formatMontant(amount),
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _divider() => Container(
        height: 30,
        width: 1,
        color: Colors.white24,
      );
}
