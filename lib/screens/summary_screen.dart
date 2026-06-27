//lib/screens/summary_screen.dart
import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Итоги по сменам'),
      ),
      body: const Center(
        child: Text('Итоги по сменам (в разработке)'),
      ),
    );
  }
}
