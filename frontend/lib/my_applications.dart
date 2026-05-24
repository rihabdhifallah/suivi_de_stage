import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class MyApplicationsPage extends StatefulWidget {
  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final api = ApiService();
  List apps = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future load() async {
    final data = await api.getMyApplications();
    setState(() => apps = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mes demandes")),
      body: ListView.builder(
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];

          return ListTile(
            title: Text("Stage ID: ${app['stageId']}"),
            subtitle: Text("Status: ${app['status']}"),
          );
        },
      ),
    );
  }
}