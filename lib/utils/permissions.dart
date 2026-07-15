class Permissions {
  static const Map<String, List<String>> rolePermissions = {
    'SUPER_ADMIN': ['DASHBOARD', 'ACTUALITES', 'MEMBRES', 'GROUPES', 'BUREAU', 'DIAPORAMA', 'PHOTOS', 'VIDEOS', 'MUSIQUES', 'COTISATIONS', 'FINANCES', 'UTILISATEURS'],
    'TRESORIER': ['DASHBOARD', 'FINANCES', 'COTISATIONS', 'MEMBRES'],
    'COMMISSAIRE_COMPTES': ['DASHBOARD', 'FINANCES', 'COTISATIONS', 'MEMBRES'],
    'SECRETAIRE': ['DASHBOARD', 'MEMBRES', 'GROUPES', 'BUREAU'],
    'SUPERVISEUR': ['DASHBOARD', 'ACTUALITES', 'DIAPORAMA', 'PHOTOS', 'VIDEOS', 'MUSIQUES', 'BUREAU'],
    'GESTIONNAIRE_COM': ['DASHBOARD', 'ACTUALITES', 'DIAPORAMA', 'PHOTOS', 'VIDEOS', 'MUSIQUES', 'BUREAU'],
    'REDACTEUR': ['DASHBOARD', 'ACTUALITES'],
  };

  static bool hasAccess(String? role, String module) {
    if (role == null || !rolePermissions.containsKey(role)) return false;
    return rolePermissions[role]!.contains(module);
  }
}
