import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final api = ApiService();

  bool isPasswordHidden = true;

void login() async {
  try {
    final data = await api.login(
      email: emailController.text,
      password: passwordController.text,
    );
    print("LOGIN RESPONSE = $data");
         await api.storage.write(
  key: "email",
  value: data['email']?.toString().trim().toLowerCase() ?? '',
);

await api.storage.write(
  key: "name",
  value: data['name'] ?? '',
);
await api.storage.write(
  key: "phone",
  value: data['phone'] ?? '',
);

await api.storage.write(
  key: "country",
  value: data['country'] ?? '',
);
await api.storage.write(
  key: "role",
  value: data['role'] ?? '',
);
    if (data['role'] == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (data['role'] == 'student') {
      Navigator.pushReplacementNamed(context, '/student-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/company-dashboard');
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login failed')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1F44), // bleu roi très foncé
              Color(0xFF0D47A1), // bleu roi
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // LOGO
                const Icon(Icons.school, size: 80, color: Colors.white),

                const SizedBox(height: 10),

                // TITRE
                const Text(
                  'Bienvenue',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Suivi de stage simple et efficace',
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 30),

                // CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [

                      // EMAIL
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email, color: Colors.white70),
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PASSWORD
                      TextField(
                        controller: passwordController,
                        obscureText: isPasswordHidden,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock, color: Colors.white70),

                          //  EYE ICON
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordHidden = !isPasswordHidden;
                              });
                            },
                          ),

                          labelText: 'Mot de passe',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // FORGOT PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                           onPressed: () {
    Navigator.pushNamed(context, '/forgot-password');
  },
  child: const Text(
    'Mot de passe oublié ?',
    style: TextStyle(color: Colors.white),
  ),
),
                            
                      ),

                      const SizedBox(height: 10),

                      // BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF0A1F44),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
Navigator.pushNamed(context, '/signup_choice');
                  },
                  child: const Text(
                    "Pas de compte ? S'inscrire",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}