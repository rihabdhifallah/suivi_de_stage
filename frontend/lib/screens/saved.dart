import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;

class SavedStagesPage extends StatelessWidget {
  final List stages;

  const SavedStagesPage({super.key, required this.stages});
Future saveStage(int id) async {
  await http.post(
    Uri.parse("${Config.baseUrl}/saved"),
    body: jsonEncode({"stageId": id}),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stages enregistrés")),
      body: ListView.builder(
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final s = stages[index];

          return Card(
            child: ListTile(
              title: Text(s["titre"] ?? ""),
              subtitle: Text(s["companyName"] ?? ""),
            ),
          );
        },
      ),
    );
  }
}