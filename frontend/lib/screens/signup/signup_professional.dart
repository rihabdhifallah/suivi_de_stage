import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class SignupProfessional extends StatefulWidget {
  const SignupProfessional({super.key});

  @override
  State<SignupProfessional> createState() => _SignupProfessionalState();
}

class _SignupProfessionalState extends State<SignupProfessional> {
  final api = ApiService();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final poste = TextEditingController();
  final entreprise = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  void signup() async {
    if (name.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirm.text.isEmpty ||
        poste.text.isEmpty ||
        entreprise.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await api.signup(body: {
        "role": "encadrant-professionnel",
        "name": name.text,
        "email": email.text,
        "password": password.text,
        "poste": poste.text,
        "entreprise": entreprise.text,
      });

Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'inscription")),
      );
    }

    setState(() => isLoading = false);
  }

  Widget inputField(TextEditingController controller, String label,
    {bool isPassword = false, bool isConfirm = false}) {

  IconData icon;

  if (label.toLowerCase().contains("nom")) {
    icon = Icons.person;
  } else if (label.toLowerCase().contains("email")) {
    icon = Icons.email;
  } else if (label.toLowerCase().contains("mot de passe")) {
    icon = Icons.lock;
  } else if (label.toLowerCase().contains("confirmer")) {
    icon = Icons.lock_outline;
  } else if (label.toLowerCase().contains("poste")) {
    icon = Icons.work;
  } else if (label.toLowerCase().contains("entreprise")) {
    icon = Icons.business;
  } else {
    icon = Icons.text_fields;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      obscureText: isPassword
          ? hidePassword
          : isConfirm
              ? hideConfirm
              : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70), // 🔥 ICON ICI
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        // 👁️ show/hide password
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  hidePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() => hidePassword = !hidePassword);
                },
              )
            : isConfirm
                ? IconButton(
                    icon: Icon(
                      hideConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => hideConfirm = !hideConfirm);
                    },
                  )
                : null,
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
                    "Inscription Professionnel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),

                  inputField(name, "Nom"),
                  inputField(email, "Email"),
                  inputField(password, "Mot de passe", isPassword: true),
                  inputField(confirm, "Confirmer mot de passe", isConfirm: true),
                  inputField(poste, "Poste"),
                  inputField(entreprise, "Entreprise"),

                  SizedBox(height: 20),

                  // 🔥 bouton avec loading
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
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