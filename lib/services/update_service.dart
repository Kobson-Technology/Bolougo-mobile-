import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  static const String repoOwner = 'Kobson-Technology';
  static const String repoName = 'Bolougo-mobile-telechargement';
  static const String apiReleaseUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final dio = Dio();
      final response = await dio.get(apiReleaseUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['tag_name'] as String;
        final assets = data['assets'] as List;

        if (assets.isEmpty) return;

        final downloadUrl = assets.firstWhere((a) => a['name'].toString().endsWith('.apk'), orElse: () => null)?['browser_download_url'];
        if (downloadUrl == null) return;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl, dio);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    latest = latest.replaceAll('v', '');
    current = current.replaceAll('v', '');
    List<String> currentParts = current.split('.');
    List<String> latestParts = latest.split('.');

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      int c = int.tryParse(currentParts[i]) ?? 0;
      int l = int.tryParse(latestParts[i]) ?? 0;
      if (l > c) return true;
      if (c > l) return false;
    }
    return latestParts.length > currentParts.length;
  }

  static void _showUpdateDialog(BuildContext context, String version, String downloadUrl, Dio dio) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: Text('Une nouvelle version ($version) est disponible. Voulez-vous la télécharger et l\'installer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndInstall(context, downloadUrl, dio);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Mettre à jour', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstall(BuildContext context, String url, Dio dio) async {
    bool hasPermission = true;
    if (Platform.isAndroid) {
      var status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        status = await Permission.requestInstallPackages.request();
      }
      hasPermission = status.isGranted;
    }

    if (!context.mounted) return;

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission d\'installation requise')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFEF4444)),
            SizedBox(width: 20),
            Text('Téléchargement en cours...'),
          ],
        ),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';

      await dio.download(url, savePath);

      if (context.mounted) Navigator.pop(context); // close progress dialog

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ouverture : ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de téléchargement : $e')),
        );
      }
    }
  }
}
