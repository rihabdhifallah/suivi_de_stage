import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF0D1B4B);
const Color _kAccent  = Color(0xFF1A3C8F);
const Color _kMid     = Color(0xFF2952B3);
const Color _kBg      = Color(0xFFF0F4FF);
const Color _kCard    = Color(0xFFFFFFFF);
const Color _kDivider = Color(0xFFE4EAF8);
const Color _kTextSec = Color(0xFF6B7A99);

class CompanyProfile extends StatefulWidget {
  const CompanyProfile({super.key});
  @override
  State<CompanyProfile> createState() => _CompanyProfileState();
}

class _CompanyProfileState extends State<CompanyProfile> {
  final storage = const FlutterSecureStorage();
  final api = ApiService();

  String name    = "";
  String email   = "";
  String phone   = "";
  String country = "";
  String photo   = "";
  String secteur = "";
  bool   loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _initials(String text) {
    final parts = text.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);
    try {
      final role   = await storage.read(key: "role");
      final userId = await storage.read(key: "userId");

      if (role == "company" && userId != null) {
        try {
          final data = await api.getCompanyById(int.parse(userId));
          setState(() {
            name    = data["nom"] ?? data["name"] ?? "";
            phone   = data["telephone"] ?? data["phone"] ?? "";
            country = data["adresse"] ?? data["country"] ?? "";
            email   = data["email"] ?? "";
            photo   = data["photo"] ?? "";
            secteur = data["secteurActivite"] ?? "";
          });
          setState(() => loading = false);
          return;
        } catch (_) {}
      }

      final data = await api.getProfile();
      setState(() {
        name    = data["name"] ?? data["nom"] ?? "";
        phone   = data["phone"] ?? data["telephone"] ?? "";
        country = data["country"] ?? data["adresse"] ?? "";
        email   = data["email"] ?? "";
        photo   = data["photo"] ?? "";
        secteur = data["secteurActivite"] ?? "";
      });
    } catch (e) {
      final n = await storage.read(key: "name");
      final e2 = await storage.read(key: "email");
      setState(() { name = n ?? ""; email = e2 ?? ""; });
    }
    setState(() => loading = false);
  }

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
        setState(() => photo = body["photo"] ?? "");
        _snack("Logo mis à jour !", _kAccent);
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
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _logout() async {
    await storage.deleteAll();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  // ── Edit dialog ──────────────────────────────────────────────────────────────
  void _showEditDialog() {
    final nameCtrl    = TextEditingController(text: name);
    final phoneCtrl   = TextEditingController(text: phone);
    final adresseCtrl = TextEditingController(text: country);
    final secteurCtrl = TextEditingController(text: secteur);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: _kCard,
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
                  Icon(Icons.edit_rounded, color: _kAccent, size: 20),
                  SizedBox(width: 10),
                  Text("Modifier le profil",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kPrimary)),
                ]),
                const SizedBox(height: 20),
                _field("Nom de l'entreprise", nameCtrl, Icons.business_rounded),
                _field("Téléphone", phoneCtrl, Icons.phone_outlined,
                  type: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLen: 8),
                _field("Adresse", adresseCtrl, Icons.location_on_outlined),
                _field("Secteur d'activité", secteurCtrl, Icons.category_outlined),
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
                      backgroundColor: _kAccent, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0),
                    onPressed: () async {
                      if (phoneCtrl.text.trim().isNotEmpty &&
                          !RegExp(r'^\d{8}$').hasMatch(phoneCtrl.text.trim())) {
                        _snack("Le téléphone doit contenir 8 chiffres", Colors.orange);
                        return;
                      }
                      try {
                        final role   = await storage.read(key: "role");
                        final userId = await storage.read(key: "userId");
                        if (role == "company" && userId != null) {
                          await api.updateCompany(int.parse(userId), {
                            "nom": nameCtrl.text.trim(),
                            "telephone": phoneCtrl.text.trim(),
                            "adresse": adresseCtrl.text.trim(),
                            "secteurActivite": secteurCtrl.text.trim(),
                          });
                        } else {
                          await api.updateProfile({
                            "name": nameCtrl.text.trim(),
                            "phone": phoneCtrl.text.trim(),
                            "country": adresseCtrl.text.trim(),
                          });
                        }
                        await storage.write(key: "name", value: nameCtrl.text.trim());
                        setState(() {
                          name    = nameCtrl.text.trim();
                          phone   = phoneCtrl.text.trim();
                          country = adresseCtrl.text.trim();
                          secteur = secteurCtrl.text.trim();
                        });
                        if (mounted) Navigator.pop(context);
                        _snack("Profil mis à jour !", _kAccent);
                      } catch (e) {
                        _snack("Erreur : $e", Colors.red);
                      }
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

  // ── Change password dialog ────────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false, showNew = false, showConfirm = false, saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: _kCard,
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
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.lock_outline_rounded, color: _kAccent, size: 22)),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Changer le mot de passe",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
                  Text("Sécurisez votre compte",
                    style: TextStyle(fontSize: 12, color: _kTextSec)),
                ]),
              ]),
              const SizedBox(height: 20),
              _pwdField("Mot de passe actuel", currentCtrl, showCurrent,
                () => setS(() => showCurrent = !showCurrent)),
              const SizedBox(height: 12),
              _pwdField("Nouveau mot de passe", newCtrl, showNew,
                () => setS(() => showNew = !showNew)),
              const SizedBox(height: 12),
              _pwdField("Confirmer le nouveau mot de passe", confirmCtrl, showConfirm,
                () => setS(() => showConfirm = !showConfirm)),
              const SizedBox(height: 8),
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
                    backgroundColor: _kAccent, foregroundColor: Colors.white,
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
                      _snack("Minimum 6 caractères", Colors.orange);
                      return;
                    }
                    setS(() => saving = true);
                    try {
                      await api.changePassword(currentCtrl.text, newCtrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _snack("Mot de passe modifié !", const Color(0xFF059669));
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
        )),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl, IconData icon, {
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
          labelStyle: const TextStyle(color: _kTextSec, fontSize: 13),
          prefixIcon: Icon(icon, color: _kPrimary, size: 20),
          counterText: '',
          filled: true, fillColor: _kBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kAccent, width: 1.5)),
        ),
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
        labelStyle: const TextStyle(color: _kTextSec, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _kPrimary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey.shade400, size: 20),
          onPressed: toggle),
        filled: true, fillColor: _kBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAccent, width: 1.5)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
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
            Text(label, style: const TextStyle(fontSize: 11, color: _kTextSec,
              fontWeight: FontWeight.w500, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: _kPrimary)),
          ],
        )),
      ]),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(width: 3, height: 16,
        decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Icon(icon, size: 15, color: _kPrimary),
      const SizedBox(width: 7),
      Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.bold,
        color: _kPrimary, letterSpacing: 0.3)),
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
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Flexible(child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center)),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    if (loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kAccent)),
      );
    }

    final initials = _initials(name);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar ──
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            stretch: true,
            backgroundColor: _kPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Profil Entreprise",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 17),
                ),
                onPressed: _logout,
                tooltip: "Déconnexion",
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimary, _kAccent, _kMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                child: Stack(children: [
                  // Decorative circles
                  Positioned(top: -30, right: -30,
                    child: Container(width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04)))),
                  Positioned(bottom: -20, left: -20,
                    child: Container(width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04)))),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 80, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7DD3FC), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              const Text("Entreprise",
                                style: TextStyle(color: Colors.white, fontSize: 11,
                                  fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          // Avatar + name row
                          Row(children: [
                            GestureDetector(
                              onTap: _uploadPhoto,
                              child: Stack(children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                                    boxShadow: [BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25), blurRadius: 12)],
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: _kMid,
                                    backgroundImage: photo.isNotEmpty
                                        ? NetworkImage("${ApiService.baseUrl}/uploads/$photo")
                                        : null,
                                    child: photo.isEmpty
                                        ? Text(initials, style: const TextStyle(
                                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                ),
                                Positioned(bottom: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB), shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 12),
                                  )),
                              ]),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name.isNotEmpty ? name : "Entreprise",
                                  style: const TextStyle(color: Colors.white, fontSize: 20,
                                    fontWeight: FontWeight.bold, letterSpacing: -0.3),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                if (secteur.isNotEmpty)
                                  Row(children: [
                                    const Icon(Icons.category_outlined, size: 12,
                                      color: Color(0xFF93C5FD)),
                                    const SizedBox(width: 5),
                                    Text(secteur,
                                      style: const TextStyle(color: Color(0xFF93C5FD),
                                        fontSize: 12, fontWeight: FontWeight.w500)),
                                  ]),
                              ],
                            )),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ]),
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
                  // Action buttons
                  Row(children: [
                    Expanded(child: _actionBtn(
                      icon: Icons.edit_rounded,
                      label: "Modifier le profil",
                      color: _kAccent,
                      bg: const Color(0xFFEEF2FF),
                      onTap: _showEditDialog,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _actionBtn(
                      icon: Icons.lock_reset_rounded,
                      label: "Changer mot de passe",
                      color: _kMid,
                      bg: const Color(0xFFF0F4FF),
                      onTap: _showChangePasswordDialog,
                    )),
                  ]),
                  const SizedBox(height: 24),

                  // Informations
                  _sectionTitle("Informations de l'entreprise", Icons.business_rounded),
                  const SizedBox(height: 12),
                  _infoRow(Icons.email_outlined, "Email", email, _kAccent),
                  _infoRow(Icons.phone_rounded, "Téléphone", phone, _kMid),
                  _infoRow(Icons.location_on_rounded, "Adresse", country, const Color(0xFF059669)),
                  _infoRow(Icons.category_outlined, "Secteur d'activité", secteur, const Color(0xFF0891B2)),

                  const SizedBox(height: 24),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                      label: const Text("Se déconnecter",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
