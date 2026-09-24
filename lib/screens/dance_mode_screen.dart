import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/dancing_sangeeta.dart';

class DanceModeScreen extends StatelessWidget {
  const DanceModeScreen({required this.category, super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Sangeeta • ' + category + ' Dance'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'SANGEETA DANCE MODE',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 13,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                DancingSangeeta(category: category),
                const SizedBox(height: 18),
                const Text(
                  'The performance preset follows the current song category.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
