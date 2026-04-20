import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class SignupStudent extends StatefulWidget {
  const SignupStudent({super.key});

  @override
  State<SignupStudent> createState() => _SignupStudentState();
}

class _SignupStudentState extends State<SignupStudent> {
  final api = ApiService();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final niveau = TextEditingController();
  final universite = TextEditingController();
  final specialite = TextEditingController(); // ✅ NEW

  void signup() async {
    // ✅ Vérification champs vides
    if (name.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty ||
        niveau.text.isEmpty ||
        universite.text.isEmpty ||
        specialite.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    //  Vérification password
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    // API
    await api.signup(body: {
      "role": "student",
      "name": name.text,
      "email": email.text,
      "password": password.text,
      "niveau": niveau.text,
      "universite": universite.text,
      "specialite": specialite.text, 
    });

    Navigator.pushReplacementNamed(context, '/');
  }

 Widget inputField(TextEditingController controller, String label) {

  IconData icon;

  if (label.toLowerCase().contains("nom")) {
    icon = Icons.person;
  } else if (label.toLowerCase().contains("email")) {
    icon = Icons.email;
  } else if (label.toLowerCase().contains("mot de passe")) {
    icon = Icons.lock;
  } else if (label.toLowerCase().contains("confirmer")) {
    icon = Icons.lock_outline;
  } else if (label.toLowerCase().contains("niveau")) {
    icon = Icons.school;
  } else if (label.toLowerCase().contains("université")) {
    icon = Icons.account_balance;
  } else if (label.toLowerCase().contains("spécialité")) {
    icon = Icons.menu_book;
  } else {
    icon = Icons.text_fields;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      obscureText: label.toLowerCase().contains("mot de passe") ||
          label.toLowerCase().contains("confirmer"),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70), // 🔥 ICON
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding: const EdgeInsets.symmetric(vertical: 18), // 💎 bonus
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF002366), 
              Color(0xFF0052cc),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "Inscription",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),

                  inputField(name, "Nom"),
                  inputField(email, "Email"),
                  inputField(password, "Mot de passe"),
                  inputField(confirm, "Confirmer mot de passe"),
                  inputField(niveau, "Niveau"),
                  inputField(universite, "Université"),
                  inputField(specialite, "Spécialité"), // 

                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white),
                        ),
                      ),
                      child: Text(
                        "S'inscrire",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Vous avez déjà un compte ? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          "Se connecter",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}