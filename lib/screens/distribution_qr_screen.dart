import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/distribution_service.dart';
import '../theme/app_theme.dart';

class DistributionQrScreen extends StatefulWidget {
  const DistributionQrScreen({super.key});

  @override
  State<DistributionQrScreen> createState() => _DistributionQrScreenState();
}

class _DistributionQrScreenState extends State<DistributionQrScreen> {
  late final TextEditingController androidController;
  late final TextEditingController iosController;

  DistributionPlatform platform = DistributionPlatform.android;

  @override
  void initState() {
    super.initState();
    androidController =
        TextEditingController(text: distributionService.androidUrl);
    iosController = TextEditingController(text: distributionService.iosUrl);
  }

  @override
  void dispose() {
    androidController.dispose();
    iosController.dispose();
    super.dispose();
  }

  String get _qrData => switch (platform) {
        DistributionPlatform.android => androidController.text.trim(),
        DistributionPlatform.ios => iosController.text.trim(),
        DistributionPlatform.both => _bothMessageForQr(),
      };

  String _bothMessageForQr() =>
      'LR\'s Sangeet_Duniya\nAndroid: ${androidController.text.trim()}\niOS: ${iosController.text.trim()}';

  String _shareText() {
    final android = androidController.text.trim();
    final ios = iosController.text.trim();

    return switch (platform) {
      DistributionPlatform.android =>
        "LR's Sangeet_Duniya\nAndroid download:\n$android",
      DistributionPlatform.ios =>
        "LR's Sangeet_Duniya\niOS download:\n$ios",
      DistributionPlatform.both =>
        "LR's Sangeet_Duniya\n\nAndroid download:\n$android\n\niOS download:\n$ios",
    };
  }

  Future<void> save() async {
    await distributionService.setAndroidUrl(androidController.text);
    await distributionService.setIosUrl(iosController.text);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Android and iOS links saved.')),
    );
  }

  Future<void> copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected download link(s) copied.')),
    );
  }

  Future<File> _downloadApkFile() async {
    final url = androidController.text.trim();
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('APK download failed: HTTP ' + response.statusCode.toString());
    }
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(root.path + '/sangeet_duniya/apk');
    await dir.create(recursive: true);
    final file = File(dir.path + '/LRS-Sangeet-Duniya-v2.0.0.apk');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  Future<void> downloadApk() async {
    try {
      final file = await _downloadApkFile();
      await SharePlus.instance.share(
        ShareParams(
          subject: "LR's Sangeet_Duniya APK",
          text: 'APK file',
          files: [XFile(file.path, mimeType: 'application/vnd.android.package-archive')],
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APK downloaded and ready to share.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('APK download failed: ' + e.toString())),
        );
      }
    }
  }

  Future<void> shareLinks() async {
    await SharePlus.instance.share(
      ShareParams(
        subject: "LR's Sangeet_Duniya",
        text: _shareText(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBoth = platform == DistributionPlatform.both;

    return Scaffold(
      appBar: AppBar(title: const Text('Share App')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'Share LR\'s Sangeet_Duniya',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<DistributionPlatform>(
                    segments: const [
                      ButtonSegment(
                        value: DistributionPlatform.android,
                        icon: Icon(Icons.android_rounded),
                        label: Text('Android'),
                      ),
                      ButtonSegment(
                        value: DistributionPlatform.ios,
                        icon: Icon(Icons.phone_iphone_rounded),
                        label: Text('iOS'),
                      ),
                      ButtonSegment(
                        value: DistributionPlatform.both,
                        icon: Icon(Icons.devices_other_rounded),
                        label: Text('Both'),
                      ),
                    ],
                    selected: <DistributionPlatform>{platform},
                    onSelectionChanged: (value) {
                      setState(() => platform = value.first);
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    color: Colors.white,
                    child: QrImageView(
                      data: _qrData,
                      size: 250,
                      version: QrVersions.auto,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isBoth
                        ? 'Both links are included in the QR data and in the shared message. For the easiest customer experience, the shared message contains separate Android and iOS links.'
                        : 'The Android QR points directly to the versioned APK file.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    switch (platform) {
                      DistributionPlatform.android => androidController.text,
                      DistributionPlatform.ios => iosController.text,
                      DistributionPlatform.both => _shareText(),
                    },
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: copyLink,
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy link'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: downloadApk,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download APK'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: shareLinks,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share direct link'),
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
                    'Download links',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the Android APK/release URL and iOS distribution URL here. Then choose Android, iOS, or Both when sharing.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: androidController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Android APK / download URL',
                      prefixIcon: Icon(Icons.android_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iosController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'iOS download / TestFlight URL',
                      prefixIcon: Icon(Icons.phone_iphone_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save links'),
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
                'Payment is disabled in this app. Sharing links and QR codes do not collect money.',
                style: TextStyle(color: AppTheme.gold2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}