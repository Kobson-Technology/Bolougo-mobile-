import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/permissions.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'mediatheque_screen.dart';
import 'actualites_screen.dart';
import 'manage_slides_screen.dart';
import 'bureau_screen.dart';
import 'groupes_screen.dart';
import 'utilisateurs_screen.dart';
import 'messages_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final role = auth.currentUser?['role'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Menu Principal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          if (Permissions.hasAccess(role, 'DASHBOARD'))
            _buildMenuItem(context, 'Statistiques', Icons.bar_chart_rounded, const Color(0xFF10B981), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
            }),
          if (Permissions.hasAccess(role, 'PHOTOS') || Permissions.hasAccess(role, 'VIDEOS') || Permissions.hasAccess(role, 'MUSIQUES'))
            _buildMenuItem(context, 'Médiathèque', Icons.perm_media_rounded, const Color(0xFFF59E0B), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MediathequeScreen()));
            }),
          if (Permissions.hasAccess(role, 'ACTUALITES'))
            _buildMenuItem(context, 'Actualités', Icons.article_rounded, const Color(0xFF3B82F6), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActualitesScreen()));
            }),
          if (Permissions.hasAccess(role, 'DIAPORAMA'))
            _buildMenuItem(context, 'Diaporama', Icons.view_carousel_rounded, const Color(0xFF14B8A6), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSlidesScreen()));
            }),
          if (Permissions.hasAccess(role, 'BUREAU'))
            _buildMenuItem(context, 'Bureau', Icons.work_rounded, const Color(0xFF8B5CF6), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BureauScreen()));
            }),
          if (Permissions.hasAccess(role, 'GROUPES'))
            _buildMenuItem(context, 'Groupes', Icons.groups_rounded, const Color(0xFFF97316), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupesScreen()));
            }),
          if (Permissions.hasAccess(role, 'UTILISATEURS'))
            _buildMenuItem(context, 'Utilisateurs', Icons.people_outline_rounded, const Color(0xFFEF4444), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilisateursScreen()));
            }),
          if (Permissions.hasAccess(role, 'MESSAGES'))
            _buildMenuItem(context, 'Messages', Icons.mail_rounded, const Color(0xFF0EA5E9), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
            }),
          _buildMenuItem(context, 'Mon Profil', Icons.person_rounded, const Color(0xFF6B7280), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }
}
