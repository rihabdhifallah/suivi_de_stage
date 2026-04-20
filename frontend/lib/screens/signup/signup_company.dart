import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class SignupCompany extends StatefulWidget {
  const SignupCompany({super.key});

  @override
  State<SignupCompany> createState() => _SignupCompanyState();
}

class _SignupCompanyState extends State<SignupCompany> {
  final api = ApiService();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final country = TextEditingController();
  final phone = TextEditingController();

  void signup() async {
    // ✅ check empty fields
    if (name.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty ||
        country.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    // ❌ password check
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    try {
      await api.signup(body: {
        "role": "company",
        "name": name.text,
        "email": email.text,
        "password": password.text,
        "country": country.text,
          "phone": phone.text,

      });

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur signup")),
      );
    }
  }

 Widget inputField(TextEditingController controller, String label) {

  IconData icon;

  if (label.toLowerCase().contains("nom")) {
    icon = Icons.business;
  } else if (label.toLowerCase().contains("email")) {
    icon = Icons.email;
  } else if (label.toLowerCase().contains("mot de passe")) {
    icon = Icons.lock;
  } else if (label.toLowerCase().contains("confirme")) {
    icon = Icons.lock_outline;
  } else if (label.toLowerCase().contains("pays")) {
    icon = Icons.public;
  } else if (label.toLowerCase().contains("téléphone")) {
    icon = Icons.phone;
  } else {
    icon = Icons.text_fields;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: label.toLowerCase().contains("mot de passe") ||
          label.toLowerCase().contains("confirme"),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70), // 🔥 ICON ICI
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white24,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002366), Color(0xFF0052cc)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Inscription Entreprise",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  inputField(name, "Nom entreprise"),
                  inputField(email, "Email entreprise"),
                  inputField(password, "Mot de passe"),
                  inputField(confirm, "Confirme mot de passe"),
                  inputField(country, "Pays"),
                  inputField(phone, "Téléphone"), 

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Vous avez déjà un compte ? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
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