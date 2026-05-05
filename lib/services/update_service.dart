import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:ota_update/ota_update.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String changelog;
  final String androidUrl;
  final String linuxUrl;
  final String windowsUrl;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    required this.androidUrl,
    required this.linuxUrl,
    required this.windowsUrl,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: (json['version'] ?? '1.0.0').toString(),
      buildNumber: json['build_number'] is int 
          ? json['build_number'] 
          : int.tryParse(json['build_number']?.toString() ?? '0') ?? 0,
      changelog: json['changelog'] ?? '',
      androidUrl: json['android_url'] ?? '',
      linuxUrl: json['linux_url'] ?? '',
      windowsUrl: json['windows_url'] ?? '',
    );
  }
}

class UpdateService {
  // Ganti dengan URL asli website abang nanti
  static const String _updateUrl = 'https://sambungkata.sakum.my.id/version.json';

  /// Cek apakah ada update tersedia
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final info = UpdateInfo.fromJson(json.decode(response.body));
        final packageInfo = await PackageInfo.fromPlatform();
        
        final currentVersion = packageInfo.version.trim();
        final currentBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;
        
        final serverVersion = info.version.trim();
        final serverBuild = info.buildNumber;

        debugPrint('[UPDATE] Checking: Local($currentVersion+$currentBuild) vs Server($serverVersion+$serverBuild)');

        // Bandingkan versi secara mendalam
        bool hasNewVersion = _isVersionGreater(serverVersion, currentVersion);
        bool hasNewBuild = serverBuild > currentBuild && serverVersion == currentVersion;

        if (hasNewVersion || hasNewBuild) {
          debugPrint('[UPDATE] New update found!');
          return info;
        } else {
          debugPrint('[UPDATE] Application is up to date.');
        }
      }
    } catch (e) {
      debugPrint('Gagal cek update: $e');
    }
    return null;
  }

  static bool _isVersionGreater(String newVersion, String currentVersion) {
    try {
      List<int> v1 = newVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> v2 = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      int maxLength = v1.length > v2.length ? v1.length : v2.length;
      
      for (int i = 0; i < maxLength; i++) {
        int val1 = i < v1.length ? v1[i] : 0;
        int val2 = i < v2.length ? v2[i] : 0;
        
        if (val1 > val2) return true;
        if (val1 < val2) return false;
      }
    } catch (e) {
      debugPrint('Error comparing versions: $e');
    }
    return false;
  }

  /// Jalankan proses update berdasarkan platform
  static Stream<OtaEvent>? updateAndroid(String url) {
    try {
      return OtaUpdate().execute(url, destinationFilename: 'game-update.apk');
    } catch (e) {
      debugPrint('Gagal update Android: $e');
      return null;
    }
  }

  /// Update untuk Desktop (Linux/Windows) via ZIP
  static Future<void> updateDesktop(String url, Function(String) onStatus) async {
    final rng = DateTime.now().millisecondsSinceEpoch;
    final tempDir = await getTemporaryDirectory();
    final downloadPath = '${tempDir.path}/update_$rng.zip';
    final extractPath = '${tempDir.path}/extract_$rng';

    try {
      onStatus("Mendownload paket update...");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Gagal download file");
      
      final file = File(downloadPath);
      await file.writeAsBytes(response.bodyBytes);

      onStatus("Mengekstrak file...");
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('$extractPath/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('$extractPath/$filename').createSync(recursive: true);
        }
      }

      onStatus("Menyiapkan script updater...");
      final appPath = File(Platform.resolvedExecutable).parent.path;
      final exeName = Platform.resolvedExecutable.split(Platform.pathSeparator).last;

      if (Platform.isLinux) {
        await _runLinuxUpdater(extractPath, appPath, exeName);
      } else if (Platform.isWindows) {
        await _runWindowsUpdater(extractPath, appPath, exeName);
      }
      
      exit(0); // Tutup aplikasi untuk memulai proses update file
    } catch (e) {
      onStatus("Error: $e");
      rethrow;
    }
  }

  static Future<void> _runLinuxUpdater(String src, String dest, String exe) async {
    final scriptPath = '${Directory.systemTemp.path}/updater.sh';
    final scriptContent = '''
#!/bin/bash
echo "=== SAMBUNG KATA UPDATER LOG ==="
echo "Menunggu aplikasi tertutup..."
sleep 2
echo "Menyalin file baru ke: $dest"
cp -rf "$src"/* "$dest/"
echo "Membersihkan file sementara..."
rm -rf "$src"
echo "Update selesai! Menjalankan aplikasi..."
cd "$dest"
./"$exe" &
echo "LOG SELESAI. Jendela ini akan tertutup dalam 3 detik."
sleep 3
''';

    await File(scriptPath).writeAsString(scriptContent);
    await Process.run('chmod', ['+x', scriptPath]);
    
    // Jalankan updater di terminal terpisah agar user bisa liat log-nya
    await Process.start('x-terminal-emulator', ['-e', 'bash', scriptPath], mode: ProcessStartMode.detached);
  }

  static Future<void> _runWindowsUpdater(String src, String dest, String exe) async {
    final scriptPath = '${Directory.systemTemp.path}\\updater.ps1';
    final scriptContent = '''
Write-Host "=== SAMBUNG KATA UPDATER LOG ===" -ForegroundColor Cyan
Write-Host "Menunggu aplikasi tertutup..."
Start-Sleep -Seconds 2
Write-Host "Menyalin file baru ke: $dest"
Copy-Item -Path "$src\\*" -Destination "$dest" -Recurse -Force
Write-Host "Membersihkan file sementara..."
Remove-Item -Path "$src" -Recurse -Force
Write-Host "Update selesai! Menjalankan aplikasi..."
cd "$dest"
Start-Process ".\\$exe"
Write-Host "LOG SELESAI. Jendela ini akan tertutup dalam 3 detik."
Start-Sleep -Seconds 3
''';

    await File(scriptPath).writeAsString(scriptContent);
    
    // Jalankan powershell di jendela baru
    await Process.start('powershell', ['-NoExit', '-File', scriptPath], mode: ProcessStartMode.detached);
  }
}
