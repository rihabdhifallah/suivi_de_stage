import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final api = ApiService();
  final storage = const FlutterSecureStorage();
  Map<String, dynamic> profile = {};
  bool loading = true;

  // Encadrants
  List<Map<String, String>> _encPro  = [];
  List<Map<String, String>> _encAcad = [];

  // ── Colors ──
  static const Color kPrimary = Color(0xFF1E3A5F);
  static const Color kAccent  = Color(0xFF2563EB);
  static const Color kBg      = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    loadProfile();
    _loadEncadrants();
  }

  Future<void> _loadEncadrants() async {
    // Encadrant professionnel
    try {
      final List apps = await api.getMyApplications();
      final Set<String> seen = {};
      final List<Map<String, String>> loaded = [];
      for (var app in apps) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        if (!['accepted','signed_by_company','fully_signed'].contains(status)) continue;
        final offre = app['offre'] ?? app['stage'] ?? {};
        final invitations = offre['invitations'];
        if (invitations is List) {
          for (var inv in invitations) {
            final enc = inv['encadrant'];
            if (enc == null) continue;
            final email = (enc['email'] ?? '').toString().trim().toLowerCase();
            final name  = (enc['nomComplet'] ?? enc['name'] ?? '').toString().trim();
            final photo = (enc['photo'] ?? '').toString();
            if (email.isNotEmpty && !seen.contains(email)) {
              seen.add(email);
              loaded.add({'name': name.isNotEmpty ? name : email,
                'email': email, 'photo': photo,
                'offre': (offre['titre'] ?? '').toString()});
            }
          }
        }
      }
      if (mounted) setState(() => _encPro = loaded);
    } catch (_) {}

    // Encadrant académique
    try {
      final List data = await api.getMyEncadrements();
      final Set<String> seen = {};
      final List<Map<String, String>> loaded = [];
      for (var enc in data) {
        final encadrant = enc['encadrant'];
        if (encadrant == null) continue;
        final email = (encadrant['email'] ?? '').toString().trim().toLowerCase();
        final name  = (encadrant['name'] ?? encadrant['nom'] ?? '').toString().trim();
        final photo = (encadrant['photo'] ?? '').toString();
        if (email.isNotEmpty && !seen.contains(email)) {
          seen.add(email);
          loaded.add({'name': name.isNotEmpty ? name : email,
            'email': email, 'photo': photo,
            'specialite': (enc['specialite'] ?? '').toString()});
        }
      }
      if (mounted) setState(() => _encAcad = loaded);
    } catch (_) {}
  }

  Future<void> loadProfile() async {
    try {
      final data = await api.getProfile();
      setState(() { profile = data; loading = false; });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ── Upload photo ──
  Future<void> _uploadPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null) return;
      final file = result.files.first;
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
      final token = await storage.read(key: "token");
      final req = http.MultipartRequest("POST",
        Uri.parse("${ApiService.baseUrl}/auth/upload-photo"));
      req.headers["Authorization"] = "Bearer $token";
      if (file.bytes != null) {
        req.files.add(http.MultipartFile.fromBytes("file", file.bytes!, filename: file.name));
      } else if (file.path != null) {
        req.files.add(await http.MultipartFile.fromPath("file", file.path!));
      }
      final res = await req.send();
      if (mounted) Navigator.pop(context);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(await res.stream.bytesToString());
        setState(() => profile["photo"] = body["photo"] ?? "");
        _snack("Photo mise à jour !", kAccent);
      } else {
        _snack("Erreur lors de l'envoi", Colors.red);
      }
    } catch (e) {
      _snack("Erreur : $e", Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Edit profile dialog ──
  void _showEditDialog() {
    final nameCtrl       = TextEditingController(text: profile["name"] ?? '');
    final phoneCtrl      = TextEditingController(text: profile["phone"] ?? '');
    final adresseCtrl    = TextEditingController(text: profile["country"] ?? '');
    final uniCtrl        = TextEditingController(text: profile["universite"] ?? '');
    final specCtrl       = TextEditingController(text: profile["specialite"] ?? '');
    final entrepriseCtrl = TextEditingController(text: profile["entreprise"] ?? '');
    final posteCtrl      = TextEditingController(text: profile["poste"] ?? '');

    final String role = (profile["role"] ?? '').toString().toLowerCase();
    final bool isProf = role.contains('professionnel') || role.contains('professional') || role.contains('company');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                const Row(children: [
                  Icon(Icons.edit_rounded, color: kAccent, size: 20),
                  SizedBox(width: 10),
                  Text("Modifier le profil",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPrimary)),
                ]),
                const SizedBox(height: 20),

                // ── Champs communs ──
                _editField("Nom complet", nameCtrl, Icons.person_outline_rounded),
                _editField("Téléphone", phoneCtrl, Icons.phone_outlined,
                  type: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLen: 8),
                _editField("Adresse", adresseCtrl, Icons.location_on_outlined),

                // ── Champs encadrant professionnel / entreprise ──
                if (isProf) ...[
                  _sectionDivider("Informations professionnelles"),
                  _editField("Entreprise", entrepriseCtrl, Icons.business_rounded),
                  _editField("Poste / Fonction", posteCtrl, Icons.badge_outlined),
                ],

                // ── Champs étudiant / académique ──
                if (!isProf) ...[
                  _sectionDivider("Informations académiques"),
                  _editField("Université / Établissement", uniCtrl, Icons.account_balance_outlined),
                  _editField("Spécialité", specCtrl, Icons.menu_book_outlined),
                ],

                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annuler"),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0),
                    onPressed: () async {
                      if (phoneCtrl.text.trim().isNotEmpty &&
                          !RegExp(r'^\d{8}$').hasMatch(phoneCtrl.text.trim())) {
                        _snack("Le téléphone doit contenir 8 chiffres", Colors.orange);
                        return;
                      }
                      await api.updateProfile({
                        "name": nameCtrl.text.trim(),
                        "phone": phoneCtrl.text.trim(),
                        "country": adresseCtrl.text.trim(),
                        "universite": uniCtrl.text.trim(),
                        "specialite": specCtrl.text.trim(),
                        "entreprise": entrepriseCtrl.text.trim(),
                        "poste": posteCtrl.text.trim(),
                      });
                      if (mounted) Navigator.pop(context);
                      loadProfile();
                      _snack("Profil mis à jour !", kAccent);
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text("Sauvegarder",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionDivider(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(children: [
        Container(width: 3, height: 14,
          decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold,
          color: kPrimary, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        inputFormatters: formatters,
        maxLength: maxLen,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: kPrimary, size: 20),
          counterText: '',
          filled: true, fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccent, width: 1.5)),
        ),
      ),
    );
  }

  // ── Change password dialog ──
  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false;
    bool showNew     = false;
    bool showConfirm = false;
    bool saving      = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setS) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.lock_outline_rounded,
                      color: Color(0xFFD97706), size: 22)),
                  const SizedBox(width: 12),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Changer le mot de passe",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary)),
                    Text("Sécurisez votre compte",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ]),
                const SizedBox(height: 20),
                // Current password
                _pwdField("Mot de passe actuel", currentCtrl, showCurrent,
                  () => setS(() => showCurrent = !showCurrent)),
                const SizedBox(height: 12),
                // New password
                _pwdField("Nouveau mot de passe", newCtrl, showNew,
                  () => setS(() => showNew = !showNew)),
                const SizedBox(height: 12),
                // Confirm
                _pwdField("Confirmer le nouveau mot de passe", confirmCtrl, showConfirm,
                  () => setS(() => showConfirm = !showConfirm)),
                const SizedBox(height: 8),
                // Password strength hint
                Text("• Minimum 6 caractères recommandés",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Annuler"),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0),
                    onPressed: saving ? null : () async {
                      if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) {
                        _snack("Veuillez remplir tous les champs", Colors.orange);
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        _snack("Les mots de passe ne correspondent pas", Colors.red);
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        _snack("Le mot de passe doit contenir au moins 6 caractères", Colors.orange);
                        return;
                      }
                      setS(() => saving = true);
                      try {
                        await api.changePassword(currentCtrl.text, newCtrl.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack("Mot de passe modifié avec succès !", const Color(0xFF059669));
                      } catch (e) {
                        setS(() => saving = false);
                        _snack(e.toString().replaceAll("Exception: ", ""), Colors.red);
                      }
                    },
                    icon: saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.lock_reset_rounded, size: 18),
                    label: Text(saving ? "En cours..." : "Modifier",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ]),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _pwdField(String label, TextEditingController ctrl, bool visible, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: kPrimary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey.shade400, size: 20),
          onPressed: toggle),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
      ),
    );
  }

  // ── Info row widget ──
  Widget _infoRow(IconData icon, String label, String value, Color color) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
              fontWeight: FontWeight.w500, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B))),
          ],
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kAccent)),
      );
    }

    final String name       = profile["name"] ?? "";
    final String email      = profile["email"] ?? "";
    final String phone      = profile["phone"] ?? "";
    final String adresse    = profile["country"] ?? "";
    final String niveau     = profile["niveau"] ?? "";
    final String uni        = profile["universite"] ?? "";
    final String spec       = profile["specialite"] ?? "";
    final String photo      = profile["photo"] ?? "";
    final String entreprise = profile["entreprise"] ?? "";
    final String poste      = profile["poste"] ?? "";
    final String role       = (profile["role"] ?? "").toString().toLowerCase();
    final bool isProf = role.contains('professionnel') || role.contains('professional') || role.contains('company');

    final String initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with gradient ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: kPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Mon Profil",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      GestureDetector(
                        onTap: _uploadPhoto,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                                boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3), blurRadius: 16)],
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: kAccent,
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage("${ApiService.baseUrl}/uploads/$photo")
                                    : null,
                                child: photo.isEmpty
                                    ? Text(initials, style: const TextStyle(
                                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 2, right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(name, style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: Colors.white60, fontSize: 12)),                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Action buttons ──
                  Row(children: [
                    Expanded(child: _actionBtn(
                      icon: Icons.edit_rounded,
                      label: "Modifier le profil",
                      color: kAccent,
                      bg: const Color(0xFFEFF6FF),
                      onTap: _showEditDialog,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _actionBtn(
                      icon: Icons.lock_reset_rounded,
                      label: "Changer mot de passe",
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFEF3C7),
                      onTap: _showChangePasswordDialog,
                    )),
                  ]),
                  const SizedBox(height: 24),

                  // ── Informations personnelles ──
                  _sectionTitle("Informations personnelles", Icons.person_rounded),
                  const SizedBox(height: 10),
                  _infoRow(Icons.phone_rounded, "Téléphone", phone, const Color(0xFF2563EB)),
                  _infoRow(Icons.location_on_rounded, "Adresse", adresse, const Color(0xFF059669)),

                  // ── Informations professionnelles (encadrant pro) ──
                  if (isProf && (entreprise.isNotEmpty || poste.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _sectionTitle("Informations professionnelles", Icons.work_rounded),
                    const SizedBox(height: 10),
                    _infoRow(Icons.business_rounded, "Entreprise", entreprise, const Color(0xFF1A3C8F)),
                    _infoRow(Icons.badge_outlined, "Poste", poste, const Color(0xFF2952B3)),
                  ],

                  // ── Informations académiques (étudiant / académique) ──
                  if (!isProf && (niveau.isNotEmpty || uni.isNotEmpty || spec.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    _sectionTitle("Informations académiques", Icons.school_rounded),
                    const SizedBox(height: 10),
                    _infoRow(Icons.school_rounded, "Niveau", niveau, const Color(0xFF7C3AED)),
                    _infoRow(Icons.account_balance_rounded, "Université", uni, const Color(0xFF0891B2)),
                    _infoRow(Icons.menu_book_rounded, "Spécialité", spec, const Color(0xFFEA580C)),
                  ],

                  // ── Mes Encadrants ──────────────────────────────────────
                  if (_encAcad.isNotEmpty || _encPro.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle("Mes Encadrants", Icons.supervisor_account_rounded),
                    const SizedBox(height: 12),

                    // Encadrant professionnel
                    if (_encPro.isNotEmpty) ...[
                      _encadrantSubLabel("Encadrant Professionnel",
                        Icons.work_outline_rounded, const Color(0xFF1A3C8F)),
                      const SizedBox(height: 8),
                      ..._encPro.map((enc) => _encadrantCard(enc,
                        color: const Color(0xFF1A3C8F),
                        bg: const Color(0xFFEFF6FF),
                        icon: Icons.work_outline_rounded)),
                      if (_encAcad.isNotEmpty) const SizedBox(height: 14),
                    ],

                    // Encadrant académique
                    if (_encAcad.isNotEmpty) ...[
                      _encadrantSubLabel("Encadrant Académique",
                        Icons.school_outlined, const Color(0xFF059669)),
                      const SizedBox(height: 8),
                      ..._encAcad.map((enc) => _encadrantCard(enc,
                        color: const Color(0xFF059669),
                        bg: const Color(0xFFECFDF5),
                        icon: Icons.school_outlined)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: kPrimary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.bold,
        color: kPrimary, letterSpacing: 0.3)),
    ]);
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center)),
        ]),
      ),
    );
  }

  Widget _encadrantSubLabel(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 13, color: color)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold,
          color: color, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _encadrantCard(Map<String, String> enc, {
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    final name  = enc['name']  ?? '';
    final email = enc['email'] ?? '';
    final photo = enc['photo'] ?? '';
    final sub   = enc['offre']?.isNotEmpty == true
        ? enc['offre']!
        : enc['specialite']?.isNotEmpty == true
            ? enc['specialite']!
            : email;

    final initials = name.trim().split(' ')
        .where((p) => p.isNotEmpty).take(2)
        .map((p) => p[0].toUpperCase()).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(
          color: color.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.transparent,
            backgroundImage: photo.isNotEmpty
                ? NetworkImage("${ApiService.baseUrl}/uploads/$photo")
                : null,
            child: photo.isEmpty
                ? Text(initials.isNotEmpty ? initials : '?',
                    style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.bold))
                : null,
          ),
        ),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B))),
            const SizedBox(height: 3),
            Row(children: [
              Icon(icon, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(child: Text(sub,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                overflow: TextOverflow.ellipsis)),
            ]),
          ],
        )),
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2))),
          child: Icon(icon, size: 14, color: color),
        ),
      ]),
    );
  }
}
