import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _kDark   = Color(0xFF0A1F44);
const Color _kBlue   = Color(0xFF1A3C8F);
const Color _kLight  = Color(0xFF4A72D4);
const Color _kBg     = Color(0xFFF5F7FF);
const Color _kCard   = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kSec    = Color(0xFF64748B);
const Color _kGreen  = Color(0xFF059669);

class CreateRapportPage extends StatefulWidget {
  final dynamic? editData;
  const CreateRapportPage({super.key, this.editData});
  @override
  State<CreateRapportPage> createState() => _CreateRapportPageState();
}

class _CreateRapportPageState extends State<CreateRapportPage> {
  final api = ApiService();

  int?      reportId;
  Uint8List? pdfFileBytes;
  String?   pdfName;

  final title  = TextEditingController();
  final resume = TextEditingController();

  String type    = "";
  bool   loading = false;

  // ── Encadrant académique dropdown ─────────────────────────────────────────
  List<Map<String, String>> _encadrants      = [];
  Map<String, String>?      _selectedEncadrant;
  bool                      _loadingEnc      = true;

  @override
  void initState() {
    super.initState();
    _loadEncadrants();
  }

  @override
  void dispose() {
    title.dispose();
    resume.dispose();
    super.dispose();
  }

  /// Charge les encadrants académiques via les encadrements de l'étudiant
  Future<void> _loadEncadrants() async {
    try {
      final List data = await api.getMyEncadrements();
      final Set<String> seen = {};
      final List<Map<String, String>> loaded = [];

      for (var enc in data) {
        final encadrant = enc['encadrant'];
        if (encadrant == null) continue;
        final email = (encadrant['email'] ?? '').toString().trim().toLowerCase();
        final name  = (encadrant['name']  ?? encadrant['nom'] ?? '').toString().trim();
        if (email.isNotEmpty && !seen.contains(email)) {
          seen.add(email);
          loaded.add({'name': name.isNotEmpty ? name : email, 'email': email});
        }
      }

      setState(() {
        _encadrants = loaded;
        if (loaded.length == 1) _selectedEncadrant = loaded.first;
        _loadingEnc = false;
      });
    } catch (e) {
      debugPrint("Error loading encadrants: $e");
      setState(() => _loadingEnc = false);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result != null) {
      setState(() {
        pdfFileBytes = result.files.first.bytes;
        pdfName      = result.files.first.name;
      });
    }
  }

  bool get isValid =>
      title.text.trim().isNotEmpty &&
      resume.text.trim().isNotEmpty &&
      _selectedEncadrant != null &&
      type.isNotEmpty &&
      pdfFileBytes != null;

  Future<int?> _submit() async {
    if (pdfFileBytes == null) return null;
    setState(() => loading = true);
    try {
      final result = await api.createReport({
        "title":    title.text.trim(),
        "type":     type,
        "resume":   resume.text.trim(),
        "encadrant": _selectedEncadrant?['email'] ?? '',
        "company":  '',
        "periode":  '',
        "difficulty": '',
      }, pdfFileBytes!);
      setState(() => loading = false);
      return result["id"];
    } catch (e) {
      debugPrint("ERROR: $e");
      setState(() => loading = false);
      return null;
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: error ? const Color(0xFFDC2626) : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _kDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text("Créer un Rapport",
                          style: TextStyle(color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Soumettez votre rapport de stage",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Type de rapport ──────────────────────────────────
                  _sectionLabel("Type de rapport", Icons.category_outlined),
                  const SizedBox(height: 12),
                  Row(children: [
                    _typeCard("final",        "Final",        Icons.verified_rounded),
                    const SizedBox(width: 10),
                    _typeCard("hebdomadaire", "Hebdomadaire", Icons.calendar_month_rounded),
                    const SizedBox(width: 10),
                    _typeCard("mi-stage",     "Mi-stage",     Icons.school_rounded),
                  ]),

                  const SizedBox(height: 24),

                  // ── Titre ────────────────────────────────────────────
                  _sectionLabel("Titre du rapport", Icons.title_rounded),
                  const SizedBox(height: 10),
                  _inputField(
                    controller: title,
                    hint: "Ex: Rapport de mi-stage — Développement mobile",
                    icon: Icons.edit_outlined,
                  ),

                  const SizedBox(height: 24),

                  // ── Résumé ───────────────────────────────────────────
                  _sectionLabel("Résumé des travaux", Icons.description_outlined),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorder),
                      boxShadow: [BoxShadow(
                        color: _kBlue.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: TextField(
                      controller: resume,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 14, color: _kDark),
                      decoration: InputDecoration(
                        hintText: "Décrivez les travaux réalisés durant cette période...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Encadrant académique ──────────────────────────────
                  _sectionLabel("Encadrant académique", Icons.person_outline_rounded),
                  const SizedBox(height: 10),
                  _encadrantDropdown(),

                  const SizedBox(height: 24),

                  // ── PDF ───────────────────────────────────────────────
                  _sectionLabel("Rapport PDF", Icons.picture_as_pdf_outlined),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickPdf,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: pdfFileBytes != null
                            ? _kGreen.withOpacity(0.05)
                            : _kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: pdfFileBytes != null ? _kGreen : _kBorder,
                          width: pdfFileBytes != null ? 1.5 : 1),
                        boxShadow: [BoxShadow(
                          color: (pdfFileBytes != null ? _kGreen : _kBlue)
                              .withOpacity(0.05),
                          blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (pdfFileBytes != null ? _kGreen : _kBlue)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                            pdfFileBytes != null
                                ? Icons.check_circle_outline_rounded
                                : Icons.upload_file_rounded,
                            color: pdfFileBytes != null ? _kGreen : _kBlue,
                            size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pdfFileBytes != null
                                  ? pdfName ?? "Fichier sélectionné"
                                  : "Importer votre rapport PDF",
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: pdfFileBytes != null ? _kGreen : _kDark),
                              overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(
                              pdfFileBytes != null
                                  ? "Appuyez pour changer"
                                  : "Format PDF uniquement",
                              style: TextStyle(
                                fontSize: 11,
                                color: pdfFileBytes != null
                                    ? _kGreen.withOpacity(0.7)
                                    : _kSec)),
                          ],
                        )),
                        Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: pdfFileBytes != null ? _kGreen : _kSec),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Bouton soumettre ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: loading ? null : () async {
                        if (!isValid) {
                          _snack("Veuillez remplir tous les champs obligatoires",
                            error: true);
                          return;
                        }
                        final id = await _submit();
                        if (id == null) {
                          _snack("Erreur lors de la création du rapport",
                            error: true);
                          return;
                        }
                        setState(() => reportId = id);
                        _snack("Rapport soumis avec succès ✔");
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: loading
                              ? null
                              : const LinearGradient(
                                  colors: [_kDark, _kBlue, _kLight]),
                          color: loading ? Colors.grey.shade300 : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: loading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded,
                                      color: Colors.white, size: 18),
                                    SizedBox(width: 10),
                                    Text("Soumettre le rapport",
                                      style: TextStyle(
                                        color: Colors.white, fontSize: 15,
                                        fontWeight: FontWeight.bold)),
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
        ],
      ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _kBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: _kBlue)),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.bold, color: _kDark)),
    ]);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(
          color: _kBlue.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: _kDark,
          fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, color: _kBlue, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _typeCard(String value, String label, IconData icon) {
    final selected = type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [_kDark, _kBlue])
                : null,
            color: selected ? null : _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : _kBorder,
              width: 1.5),
            boxShadow: selected
                ? [BoxShadow(color: _kBlue.withOpacity(0.3),
                    blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(children: [
            Icon(icon,
              color: selected ? Colors.white : _kSec, size: 20),
            const SizedBox(height: 6),
            Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : _kDark,
                fontWeight: FontWeight.bold, fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  Widget _encadrantDropdown() {
    if (_loadingEnc) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: _kBlue),
        ),
      );
    }
    if (_encadrants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
            color: Color(0xFFF97316), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            "Aucun encadrant académique trouvé.\nVous devez être assigné à un encadrement.",
            style: TextStyle(fontSize: 12,
              color: Colors.orange.shade800, height: 1.4),
          )),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedEncadrant != null ? _kBlue : _kBorder,
          width: _selectedEncadrant != null ? 1.5 : 1),
        boxShadow: [BoxShadow(
          color: _kBlue.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, String>>(
          value: _selectedEncadrant,
          isExpanded: true,
          hint: Text("Sélectionner l'encadrant académique",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kBlue),
          items: _encadrants.map((enc) {
            return DropdownMenuItem<Map<String, String>>(
              value: enc,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.08),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.school_outlined,
                    size: 14, color: _kBlue)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(enc['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: _kDark)),
                    Text(enc['email'] ?? '',
                      style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                  ],
                )),
              ]),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedEncadrant = val),
        ),
      ),
    );
  }
}
