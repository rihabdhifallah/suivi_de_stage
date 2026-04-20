import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UploadRapport extends StatefulWidget {
  const UploadRapport({super.key});

  @override
  State<UploadRapport> createState() => _UploadRapportState();
}

class _UploadRapportState extends State<UploadRapport> {
  final api = ApiService();

  void sendRapport() async {
    await api.sendRapport({
      "studentId": 1,
      "fileUrl": "https://example.com/rapport.pdf"
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rapport envoyé")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Envoyer Rapport")),
      body: Center(
        child: ElevatedButton(
          onPressed: sendRapport,
          child: const Text("Upload PDF"),
        ),
      ),
    );
  }
}