import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class SignupAcademic extends StatefulWidget {
  const SignupAcademic({super.key});

  @override
  State<SignupAcademic> createState() => _SignupAcademicState();
}

class _SignupAcademicState extends State<SignupAcademic> {
  final api = ApiService();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final departement = TextEditingController();
  final etablissement = TextEditingController();

  void signup() async {
    // ✅ Vérification champs
    if (name.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty ||
        departement.text.isEmpty ||
        etablissement.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    // ✅ Vérification password
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    await api.signup(body: {
      "role": "encadrant-academique",
      "name": name.text,
      "email": email.text,
      "password": password.text,
      "departement": departement.text,
      "etablissement": etablissement.text,
    });

    Navigator.pushReplacementNamed(context, '/');
  }

  Widget inputField(TextEditingController controller, String label) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        obscureText: label.toLowerCase().contains("mot de passe") || label == "Confirm",
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
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
              Color(0xFF002366), // bleu roi
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
                    "Inscription Académique",
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
                  inputField(confirm, "Confirme mot de passe"),
                  inputField(departement, "Département"),
                  inputField(etablissement, "Établissement"),

                  SizedBox(height: 20),

                  // ✅ Bouton transparent
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

                  // ✅ Login link
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
                          "Login",
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