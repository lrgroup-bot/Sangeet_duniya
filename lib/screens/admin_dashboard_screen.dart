import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_provider.dart';
import '../services/local_lan_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final serverController =
      TextEditingController(text: localLanService.serverUrl);

  @override
  void dispose() {
    serverController.dispose();
    super.dispose();
  }

  Future<void> _saveAndSync() async {
    await localLanService.setServerUrl(serverController.text);
    final ok = authProvider.isActivated
        ? await authProvider.syncWithAdmin()
        : await localLanService.checkHealth();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'PC admin server sync succeeded.'
            : 'PC admin server is not reachable.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PC Admin Server')),
      body: AnimatedBuilder(
        animation: Listenable.merge([authProvider, localLanService]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.desktop_windows_rounded,
              size: 64,
              color: AppTheme.gold,
            ),
            const SizedBox(height: 12),
            const Text(
              'Windows PC is the admin authority',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate 6-digit codes, view users/devices, revoke access and monitor validity from the web dashboard running on the Windows PC.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .68)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: serverController,
              decoration: const InputDecoration(
                labelText: 'PC server address',
                hintText: '192.168.1.10:40425 or Tailscale 100.x.x.x:40425',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saveAndSync,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Save & sync'),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: Icon(
                  localLanService.isReachable
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: localLanService.isReachable
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                title: Text(
                  localLanService.isReachable
                      ? 'PC reachable'
                      : 'PC not currently reachable',
                ),
                subtitle: Text(
                  localLanService.lastContact == null
                      ? 'No successful contact yet.'
                      : 'Last contact: ${localLanService.lastContact}',
                ),
              ),
            ),
            if (authProvider.license != null)
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.verified_rounded, color: AppTheme.gold),
                  title: Text(authProvider.statusText),
                  subtitle: Text(
                    'Device ID: ${authProvider.deviceId}\n'
                    'Activation ID: ${authProvider.license!.activationId}',
                  ),
                  isThreeLine: true,
                ),
              ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: localLanService.serverUrl.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: '${localLanService.serverUrl}/',
                        ),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PC dashboard address copied.'),
                        ),
                      );
                    },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy PC dashboard address'),
            ),
            const SizedBox(height: 20),
            const Text(
              'On the PC run admin_server/start_admin_server.bat. Open the printed dashboard URL in the PC browser and log in with the admin token printed by the server.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
