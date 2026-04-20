import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CandidatsPage extends StatefulWidget {
  final int stageId;

  const CandidatsPage({super.key, required this.stageId});

  @override
  State<CandidatsPage> createState() => _CandidatsPageState();
}

class _CandidatsPageState extends State<CandidatsPage> {
  final api = ApiService();
  List candidats = [];

  // @override
  // void initState() {
  //   super.initState();
  //   load();
  // }

  // void load() async {
  //   final data = await api.getCandidats(widget.stageId);
  //   setState(() => candidats = data);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Candidats"),
        backgroundColor: const Color(0xFF002366),
      ),

      body: ListView.builder(
        itemCount: candidats.length,
        itemBuilder: (context, i) {
          final c = candidats[i];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(c['name'] ?? ''),
              subtitle: Text(c['email'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}