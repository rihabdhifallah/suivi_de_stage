import 'package:flutter/material.dart';

class JournalDifficultesPage extends StatefulWidget {
   JournalDifficultesPage({super.key});

  @override
  State<JournalDifficultesPage> createState() =>
      _JournalDifficultesPageState();
}

class _JournalDifficultesPageState extends State<JournalDifficultesPage> {
  List<Map<String, dynamic>> difficultes = [
    {
      "title": "API login slow",
      "status": "bloquant",
      "resolved": false,
    },
    {
      "title": "Bug upload CV",
      "status": "moyen",
      "resolved": true,
    },
    {
      "title": "UI mobile overflow",
      "status": "mineur",
      "resolved": false,
    },
  ];

  Color getColor(String status) {
    switch (status) {
      case "bloquant":
        return Colors.red;
      case "moyen":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unresolved =
        difficultes.where((d) => d["resolved"] == false).toList();
    final resolved =
        difficultes.where((d) => d["resolved"] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Difficultés"),
        backgroundColor: const Color(0xFF0A1F44),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A1F44),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text("Nouvelle difficulté"),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Décrire le problème...",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annuler"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        difficultes.add({
                          "title": controller.text,
                          "status": "moyen",
                          "resolved": false,
                        });
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Ajouter"),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            const Text(
              "❌ Non résolues",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...unresolved.map((d) => _card(d)).toList(),

            const SizedBox(height: 20),

            const Text(
              "✅ Résolues",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...resolved.map((d) => _card(d)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _card(Map d) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          d["resolved"] ? Icons.check_circle : Icons.error,
          color: d["resolved"] ? Colors.green : Colors.red,
        ),
        title: Text(d["title"]),
        subtitle: Text(
          "Status: ${d["status"]}",
          style: TextStyle(
            color: getColor(d["status"]),
          ),
        ),
        trailing: Switch(
          value: d["resolved"],
          onChanged: (val) {
            setState(() {
              d["resolved"] = val;
            });
          },
        ),
      ),
    );
  }
}