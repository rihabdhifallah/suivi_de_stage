import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            CircleAvatar(radius: 40),
            SizedBox(height: 10),

            Text("Student Name"),
            Text("student@email.com"),

            SizedBox(height: 20),

            ListTile(
              leading: Icon(Icons.school),
              title: Text("Université"),
            ),

            ListTile(
              leading: Icon(Icons.work),
              title: Text("Stage actuel"),
            ),
          ],
        ),
      ),
    );
  }
}