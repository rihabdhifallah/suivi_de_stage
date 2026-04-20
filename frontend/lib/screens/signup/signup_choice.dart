import 'package:flutter/material.dart';

class SignupChoice extends StatelessWidget {
  const SignupChoice({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F44),

      
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Créer un compte",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            _card(context, "Étudiant", '/signup-student', Icons.school),
            _card(context, "Entreprise", '/signup-company', Icons.business),
            _card(context, "Encadrant Académique", '/signup-academic', Icons.person),
            _card(context, "Encadrant Professionnel", '/signup-professional', Icons.work),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, String route, IconData icon) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0A1F44)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}