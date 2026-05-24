import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final api = ApiService();

  bool _hidePwd  = true;
  bool _loading  = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final pwd   = _passwordCtrl.text;

    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _error = "Veuillez remplir tous les champs.");
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final data = await api.login(email: email, password: pwd);

      if (data['role'] == null) {
        setState(() {
          _error = data['message'] ?? 'Identifiants incorrects.';
          _loading = false;
        });
        return;
      }

      final role = data['role'].toString().toLowerCase();
      await api.storage.write(key: "token",     value: data['access_token']);
      await api.storage.write(key: "email",     value: data['email']);
      await api.storage.write(key: "name",      value: data['name'] ?? data['nom'] ?? '');
      await api.storage.write(key: "userId",    value: data['id'].toString());
      await api.storage.write(key: "role",      value: role);
      if (data['companyId'] != null) {
        await api.storage.write(key: "companyId", value: data['companyId'].toString());
      }

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (role == 'student') {
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      } else if (role == 'company') {
        Navigator.pushReplacementNamed(context, '/company-dashboard');
      } else if (role == 'encadrant-professionnel') {
        Navigator.pushReplacementNamed(context, '/professional-dashboard');
      } else if (role == 'encadrant-academique' || role == 'academique') {
        Navigator.pushReplacementNamed(context, '/encadrant-dashboard');
      } else {
        setState(() {
          _error = 'Rôle non reconnu : $role';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Identifiants incorrects. Veuillez réessayer.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B4B), Color(0xFF1A3C8F), Color(0xFF2952B3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(top: -60, right: -60,
                child: Container(width: 220, height: 220,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)))),
              Positioned(bottom: 80, left: -40,
                child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)))),
              Positioned(top: 120, left: 30,
                child: Container(width: 60, height: 60,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03)))),

              // Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: const Icon(Icons.school_rounded, size: 52, color: Colors.white),
                          ),
                          const SizedBox(height: 20),

                          // Title
                          const Text("StageConnect",
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                              color: Colors.white, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Text("Suivi de stage intelligent",
                            style: TextStyle(fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7))),
                          const SizedBox(height: 36),

                          // Form card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Connexion",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D1B4B))),
                                const SizedBox(height: 4),
                                Text("Entrez vos identifiants pour continuer",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(height: 22),

                                // Email field
                                _inputField(
                                  controller: _emailCtrl,
                                  label: "Adresse email",
                                  icon: Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),

                                // Password field
                                TextField(
                                  controller: _passwordCtrl,
                                  obscureText: _hidePwd,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B4B)),
                                  onSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    labelText: "Mot de passe",
                                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                                      color: Color(0xFF1A3C8F), size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _hidePwd ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        color: Colors.grey.shade400, size: 20),
                                      onPressed: () => setState(() => _hidePwd = !_hidePwd)),
                                    filled: true,
                                    fillColor: const Color(0xFFF0F4FF),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFF1A3C8F), width: 1.5)),
                                  ),
                                ),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF1A3C8F),
                                      padding: const EdgeInsets.symmetric(vertical: 4)),
                                    child: const Text("Mot de passe oublié ?",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),

                                // Error message
                                if (_error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_error!,
                                        style: const TextStyle(fontSize: 12,
                                          color: Color(0xFFDC2626), fontWeight: FontWeight.w500))),
                                    ]),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A3C8F),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                      disabledBackgroundColor: const Color(0xFF1A3C8F).withValues(alpha: 0.6),
                                    ),
                                    child: _loading
                                        ? const SizedBox(width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5, color: Colors.white))
                                        : const Text("Se connecter",
                                            style: TextStyle(fontSize: 15,
                                              fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign up link
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text("Pas encore de compte ?",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/signup_choice'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 6)),
                              child: const Text("S'inscrire",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B4B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1A3C8F), size: 20),
        filled: true,
        fillColor: const Color(0xFFF0F4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A3C8F), width: 1.5)),
      ),
    );
  }
}
