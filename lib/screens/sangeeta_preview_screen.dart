import 'package:flutter/material.dart';

class SangeetaPreviewScreen extends StatelessWidget {
  const SangeetaPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sangeeta')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFC857), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FFC857),
                      blurRadius: 36,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 64,
                  color: Color(0xFFFFC857),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sangeeta is getting ready 💛',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Voice wake words, Odia conversation, playback commands, avatar and Dance Mode are scheduled for Phases 2–3.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
