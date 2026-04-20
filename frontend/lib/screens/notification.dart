import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),

      body: ListView(
        children: const [

          ListTile(
            leading: Icon(Icons.notification_important),
            title: Text("Stage accepté par admin"),
          ),

          ListTile(
            leading: Icon(Icons.notification_important),
            title: Text("Nouveau stage disponible"),
          ),

          ListTile(
            leading: Icon(Icons.notification_important),
            title: Text("Encadrant assigné"),
          ),
        ],
      ),
    );
  }
}