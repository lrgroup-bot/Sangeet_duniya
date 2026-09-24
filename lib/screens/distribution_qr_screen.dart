import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/distribution_service.dart';
import '../theme/app_theme.dart';

class DistributionQrScreen extends StatefulWidget {
  const DistributionQrScreen({super.key});

  @override
  State<DistributionQrScreen> createState() => _DistributionQrScreenState();
}

class _DistributionQrScreenState extends State<DistributionQrScreen> {
  late final TextEditingController urlController;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(
      text: distributionService.downloadUrl,
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    await distributionService.setDownloadUrl(urlController.text);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download link saved.')),
    );
  }

  Future<void> copyLink() async {
    await Clipboard.setData(
      ClipboardData(text: distributionService.downloadUrl),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download link copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download QR')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'Scan to get LR\'s Sangeet_Duniya',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    color: Colors.white,
                    child: QrImageView(
                      data: distributionService.downloadUrl,
                      size: 250,
                      version: QrVersions.auto,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    distributionService.downloadUrl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: copyLink,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy download link'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribution page',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Paste the free web page, GitHub Release, or other download URL you control. The QR is generated entirely offline.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Download URL',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save link'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Payment is disabled in this app. The QR and activation system do not collect money or require a payment gateway.',
                style: TextStyle(color: AppTheme.gold2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
