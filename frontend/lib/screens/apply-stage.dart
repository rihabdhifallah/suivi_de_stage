import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:frontend/config.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _kDark    = Color(0xFF0A1F44);
const Color _kBlue    = Color(0xFF1A3C8F);
const Color _kLight   = Color(0xFF4A72D4);
const Color _kBg      = Color(0xFFF5F7FF);
const Color _kCard    = Color(0xFFFFFFFF);
const Color _kBorder  = Color(0xFFE2E8F0);
const Color _kTextSec = Color(0xFF64748B);
const Color _kGreen   = Color(0xFF059669);

class ApplyStagePage extends StatefulWidget {
  const ApplyStagePage({super.key});
  @override
  State<ApplyStagePage> createState() => _ApplyStagePageState();
}

class _ApplyStagePageState extends State<ApplyStagePage>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  int step = 1;
  bool _submitting = false;

  final noteCtrl          = TextEditingController();
  final phoneCtrl         = TextEditingController();
  final niveauCtrl        = TextEditingController();
  final dateCtrl          = TextEditingController();
  final cityCtrl          = TextEditingController();
  final etablissementCtrl = TextEditingController();
  final dureeCtrl         = TextEditingController();

  PlatformFile? selectedFile;
  PlatformFile? selectedMotivationFile;
  String typeStage = "Présentiel";

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await api.getProfile();
      if (mounted && profile != null) {
        setState(() {
          phoneCtrl.text         = profile['phone']?.toString() ?? profile['telephone']?.toString() ?? '';
          cityCtrl.text          = profile['country']?.toString() ?? profile['adresse']?.toString() ?? profile['city']?.toString() ?? '';
          etablissementCtrl.text = profile['universite']?.toString() ?? profile['etablissement']?.toString() ?? '';
          niveauCtrl.text        = profile['niveau']?.toString() ?? '';
        });
      }
    } catch (e) { debugPrint("Erreur profil: $e"); }
  }

  Future<void> _pickFile(bool isCV) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        if (isCV) selectedFile = result.files.first;
        else selectedMotivationFile = result.files.first;
      });
    }
  }

  void _nextStep() {
    _animCtrl.reset();
    setState(() => step++);
    _animCtrl.forward();
  }

  Future<void> _submit(Map stage) async {
    setState(() => _submitting = true);
    try {
      final token   = await api.storage.read(key: "token");
      final stageId = stage["id"]?.toString();
      var request   = http.MultipartRequest(
        "POST", Uri.parse("${Config.baseUrl}/applications/apply/$stageId"));
      request.headers["Authorization"] = "Bearer $token";
      request.fields["companyEmail"]   = stage["companyEmail"] ?? "";
      request.fields["phone"]          = phoneCtrl.text;
      request.fields["niveau"]         = niveauCtrl.text;
      request.fields["city"]           = cityCtrl.text.trim();
      request.fields["date"]           = dateCtrl.text.trim();
      request.fields["etablissement"]  = etablissementCtrl.text.trim();
      request.fields["duree"]          = dureeCtrl.text.trim();
      request.fields["note"]           = noteCtrl.text;
      request.fields["typeStage"]      = typeStage;
      if (selectedFile != null) {
        request.files.add(http.MultipartFile.fromBytes(
          "cv", selectedFile!.bytes!, filename: selectedFile!.name));
      }
      if (selectedMotivationFile != null) {
        request.files.add(http.MultipartFile.fromBytes(
          "motivation", selectedMotivationFile!.bytes!, filename: selectedMotivationFile!.name));
      }
      final res  = await request.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        _nextStep();
      } else {
        if (!mounted) return;
        String msg = "Erreur lors de la postulation";
        try { final p = jsonDecode(body); if (p is Map && p['message'] != null) msg = p['message'].toString(); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur réseau")));
    }
    setState(() => _submitting = false);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stage = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(stage),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: step == 1 ? _stepOne(stage)
                     : step == 2 ? _stepTwo(stage)
                     : _stepThree(stage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(Map stage) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _kDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => step > 1 && step < 3
            ? setState(() { _animCtrl.reset(); step--; _animCtrl.forward(); })
            : Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kDark, _kBlue, _kLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Postuler",
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 4),
                  Text(stage["titre"] ?? "Offre de stage",
                    style: const TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  _buildStepper(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── STEPPER ───────────────────────────────────────────────────────────────
  Widget _buildStepper() {
    final labels = ["Documents", "Infos", "Envoyé"];
    return Row(
      children: List.generate(3, (i) {
        final n = i + 1;
        final done   = step > n;
        final active = step == n;
        return Expanded(
          child: Row(children: [
            Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _kGreen : active ? Colors.white : Colors.white24,
                  border: Border.all(
                    color: done ? _kGreen : active ? Colors.white : Colors.white38,
                    width: 2),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : Text("$n", style: TextStyle(
                          color: active ? _kDark : Colors.white60,
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
            ]),
            if (i < 2)
              Expanded(child: Container(
                height: 2, margin: const EdgeInsets.only(bottom: 18),
                color: done ? _kGreen : Colors.white24)),
          ]),
        );
      }),
    );
  }

  // ── STEP 1 ────────────────────────────────────────────────────────────────
  Widget _stepOne(Map stage) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      // Company card
      _companyCard(stage),
      const SizedBox(height: 28),
      _sectionTitle("Documents requis", Icons.folder_outlined),
      const SizedBox(height: 14),
      _filePickerCard(
        label: "Lettre de motivation",
        subtitle: "Format PDF uniquement",
        icon: Icons.description_outlined,
        file: selectedMotivationFile,
        onTap: () => _pickFile(false),
      ),
      const SizedBox(height: 12),
      _filePickerCard(
        label: "Curriculum Vitae (CV)",
        subtitle: "Format PDF uniquement",
        icon: Icons.badge_outlined,
        file: selectedFile,
        onTap: () => _pickFile(true),
      ),
      const SizedBox(height: 28),
      _sectionTitle("Note supplémentaire", Icons.edit_note_rounded, optional: true),
      const SizedBox(height: 14),
      _noteField(),
      const SizedBox(height: 32),
      _primaryButton(
        label: "Continuer",
        icon: Icons.arrow_forward_rounded,
        onPressed: () {
          if (selectedMotivationFile == null) {
            _snack("Veuillez importer votre lettre de motivation"); return;
          }
          if (selectedFile == null) {
            _snack("Veuillez importer votre CV"); return;
          }
          _nextStep();
        },
      ),
    ]);
  }

  // ── STEP 2 ────────────────────────────────────────────────────────────────
  Widget _stepTwo(Map stage) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      _sectionTitle("Informations personnelles", Icons.person_outline_rounded),
      const SizedBox(height: 16),
      _formCard(children: [
        _formField(phoneCtrl, "Téléphone", Icons.phone_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 8),
        _divider(),
        _formField(niveauCtrl, "Niveau d'étude", Icons.school_outlined),
        _divider(),
        _formField(etablissementCtrl, "Université / Établissement", Icons.account_balance_outlined),
        _divider(),
        _formField(cityCtrl, "Adresse", Icons.location_on_outlined),
        _divider(),
        _formField(dureeCtrl, "Durée souhaitée", Icons.timer_outlined),
        _divider(),
        _datePicker(),
      ]),
      const SizedBox(height: 32),
      _primaryButton(
        label: _submitting ? "Envoi en cours..." : "Envoyer ma candidature",
        icon: Icons.send_rounded,
        loading: _submitting,
        onPressed: _submitting ? null : () async {
          if (phoneCtrl.text.trim().isEmpty || niveauCtrl.text.trim().isEmpty ||
              cityCtrl.text.isEmpty || dateCtrl.text.isEmpty ||
              etablissementCtrl.text.isEmpty || dureeCtrl.text.isEmpty) {
            _snack("Veuillez remplir tous les champs"); return;
          }
          if (!RegExp(r'^\d{8}$').hasMatch(phoneCtrl.text.trim())) {
            _snack("Le téléphone doit contenir exactement 8 chiffres"); return;
          }
          await _submit(stage);
        },
      ),
    ]);
  }

  // ── STEP 3 ────────────────────────────────────────────────────────────────
  Widget _stepThree(Map stage) {
    final company = (stage["companyName"] ?? stage["companyEmail"] ?? "L'entreprise").toString();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        // Success animation
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
        ),
        const SizedBox(height: 28),
        const Text("Candidature envoyée !",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kDark),
          textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text("Votre candidature a été soumise avec succès.\n$company examinera votre dossier.",
          style: const TextStyle(fontSize: 14, color: _kTextSec, height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 36),
        // Recap card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
            boxShadow: [BoxShadow(
              color: _kBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(
                company.substring(0, company.length >= 2 ? 2 : 1).toUpperCase(),
                style: const TextStyle(color: _kBlue, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stage["titre"] ?? "Offre de stage",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(company, style: const TextStyle(fontSize: 13, color: _kTextSec)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: const Text("En attente",
                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        const SizedBox(height: 40),
        _primaryButton(
          label: "Retour à l'accueil",
          icon: Icons.home_rounded,
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ],
    );
  }

  // ── WIDGETS HELPERS ───────────────────────────────────────────────────────

  Widget _companyCard(Map stage) {
    final company = (stage["companyName"] ?? stage["companyEmail"] ?? "Entreprise").toString();
    final domain  = (stage["domaine"] ?? '').toString();
    final city    = (stage["city"] ?? '').toString();
    final duree   = (stage["duree"] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kDark, _kBlue]),
            borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(
            company.substring(0, company.length >= 2 ? 2 : 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            if (domain.isNotEmpty) _miniChip(Icons.category_outlined, domain, _kBlue),
            if (city.isNotEmpty)   _miniChip(Icons.location_on_outlined, city, _kTextSec),
            if (duree.isNotEmpty)  _miniChip(Icons.timer_outlined, duree, _kGreen),
          ]),
        ])),
      ]),
    );
  }

  Widget _miniChip(IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _sectionTitle(String title, IconData icon, {bool optional = false}) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _kBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: _kBlue)),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.bold, color: _kDark)),
      if (optional) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _kTextSec.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
          child: const Text("Optionnel",
            style: TextStyle(fontSize: 10, color: _kTextSec, fontWeight: FontWeight.w500))),
      ],
    ]);
  }

  Widget _filePickerCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required PlatformFile? file,
    required VoidCallback onTap,
  }) {
    final picked = file != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: picked ? _kGreen.withOpacity(0.04) : _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? _kGreen : _kBorder,
            width: picked ? 1.5 : 1),
          boxShadow: [BoxShadow(
            color: (picked ? _kGreen : _kBlue).withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (picked ? _kGreen : _kBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(
              picked ? Icons.check_circle_outline_rounded : icon,
              color: picked ? _kGreen : _kBlue, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              picked ? file!.name : label,
              style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14,
                color: picked ? _kGreen : _kDark),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              picked ? "Fichier sélectionné ✓" : subtitle,
              style: TextStyle(
                fontSize: 12,
                color: picked ? _kGreen.withOpacity(0.7) : _kTextSec)),
          ])),
          Icon(
            picked ? Icons.edit_outlined : Icons.upload_rounded,
            color: picked ? _kGreen : _kTextSec, size: 18),
        ]),
      ),
    );
  }



  Widget _noteField() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: noteCtrl,
        maxLines: 4,
        style: const TextStyle(fontSize: 14, color: _kDark),
        decoration: InputDecoration(
          hintText: "Un message court pour l'entreprise...",
          hintStyle: const TextStyle(color: _kTextSec, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _formCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 14, color: _kDark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _kBlue, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: _kTextSec, fontSize: 13),
          border: InputBorder.none,
          counterText: "",
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 52, color: Color(0xFFF1F5F9));

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
          initialDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: _kBlue)),
            child: child!),
        );
        if (picked != null) {
          setState(() => dateCtrl.text = picked.toIso8601String().split("T")[0]);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, color: _kBlue, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(
            dateCtrl.text.isEmpty ? "Date de début" : dateCtrl.text,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: dateCtrl.text.isEmpty ? _kTextSec : _kDark))),
          Icon(Icons.arrow_drop_down_rounded, color: _kTextSec),
        ]),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? null
                : const LinearGradient(colors: [_kDark, _kBlue, _kLight]),
            color: onPressed == null ? Colors.grey.shade300 : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(label, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ]),
          ),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF0A1F44),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
