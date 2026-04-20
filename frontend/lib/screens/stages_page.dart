import 'package:flutter/material.dart';

class StagesPage extends StatelessWidget {
  const StagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stages')),
      body: const Center(
        child: Text('Liste des stages'),
      ),
    );
  }
}