import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class AddUtilisateurScreen extends StatefulWidget {
  const AddUtilisateurScreen({super.key});

  @override
  State<AddUtilisateurScreen> createState() => _AddUtilisateurScreenState();
}

class _AddUtilisateurScreenState extends State<AddUtilisateurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  String _roleSelectionne = 'REDACTEUR';
  
  final Map<String, String> _roles = {
    'SUPER_ADMIN': 'Super Administrateur - Accès total (Responsable Technique)',
    'TRESORIER': 'Trésorier - Finances, Cotisations, Membres (lecture)',
    'COMMISSAIRE_COMPTES': 'Commissaire aux Comptes - Lecture seule Finances & Cotisations',
    'SECRETAIRE': 'Secrétaire - Membres, Groupes, Bureau',
    'SUPERVISEUR': 'Superviseur - Publication Actualités & Médias',
    'GESTIONNAIRE_COM': 'Gestionnaire Com - Création Contenus & Médias',
    'REDACTEUR': 'Rédacteur - Articles uniquement (ses propres)',
  };

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.client.post('/auth/register', data: {
        'name': _nomCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'role': _roleSelectionne,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur créé avec succès !'), backgroundColor: Color(0xFF10B981)),
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
        title: const Text('Ajouter un utilisateur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF3B82F6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
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
                    TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(labelText: 'Nom complet', hintText: 'Ex: THIERRY KOBOU', border: InputBorder.none, prefixIcon: Icon(Icons.person, color: Color(0xFF3B82F6))),
                    ),
                    const Divider(height: 1),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Adresse Email *', hintText: 'jean@bolougo.com', border: InputBorder.none, prefixIcon: Icon(Icons.email, color: Color(0xFF3B82F6))),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const Divider(height: 1),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe *', 
                        hintText: 'Minimum 6 caractères', 
                        border: InputBorder.none, 
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF3B82F6)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v.length < 6) return '6 caractères minimum';
                        return null;
                      },
                    ),
                    const Divider(height: 1),
                    DropdownButtonFormField<String>(
                      value: _roleSelectionne,
                      decoration: const InputDecoration(labelText: 'Rôle (Permissions) *', border: InputBorder.none, prefixIcon: Icon(Icons.shield, color: Color(0xFF3B82F6))),
                      isExpanded: true,
                      items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _roleSelectionne = val!),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Choisissez le rôle qui correspond aux responsabilités de cet utilisateur.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(_isLoading ? 'Création...' : "Créer l'utilisateur", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
