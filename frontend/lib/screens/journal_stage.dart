import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JournalStage extends StatefulWidget {
  const JournalStage({super.key});

  @override
  State<JournalStage> createState() => _JournalStageState();
}

class _JournalStageState extends State<JournalStage> {
  final desc = TextEditingController();
  final diff = TextEditingController();
  final sol = TextEditingController();

  final api = ApiService();

  void sendJournal() async {
    await api.sendJournal({
      "studentId": 1,
      "date": DateTime.now().toString(),
      "description": desc.text,
      "difficulties": diff.text,
      "solution": sol.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Journal envoyé")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Journal de stage")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(controller: desc, decoration: const InputDecoration(labelText: "Travail fait")),
            TextField(controller: diff, decoration: const InputDecoration(labelText: "Difficultés")),
            TextField(controller: sol, decoration: const InputDecoration(labelText: "Solution")),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: sendJournal,
              child: const Text("Envoyer"),
            ),
          ],
        ),
      ),
    );
  }
}