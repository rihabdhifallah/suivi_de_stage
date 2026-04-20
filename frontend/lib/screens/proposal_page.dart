import 'package:flutter/material.dart';

class ProposalPage extends StatelessWidget {
  const ProposalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proposer un stage')),
      body: const Center(
        child: Text('Proposition stage étudiant'),
      ),
    );
  }
}