import 'package:flutter/material.dart';


class JournalDetailPage extends StatelessWidget {
  final Map journal;

  const JournalDetailPage({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final j = journal;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail journal"),
        backgroundColor: const Color(0xFF0A1F44),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Humeur: ${j["mood"]}"),
            Text("Tâches faites: ${j["tasksDone"]}"),
            Text("En cours: ${j["tasksInProgress"]}"),
            Text("Difficultés: ${j["difficulties"]}"),
            Text("Gravité: ${j["severity"]}"),
            Text("Solution: ${j["solution"]}"),
            Text("Appris: ${j["learned"]}"),
            Text("Plan: ${j["plan"]}"),
          ],
        ),
      ),
    );
  }
}