import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/api_service.dart';
import '../theme/admin_theme.dart';

class EncadrementPage extends StatefulWidget {
  const EncadrementPage({super.key});

  @override
  State<EncadrementPage> createState() => _EncadrementPageState();
}

class _EncadrementPageState extends State<EncadrementPage> {
  final api = ApiService();

  List encadrements = [];
  bool loading = false;

  List allUsers = [];
  List users = [];
  List departements = [];
  List specialites = [];

  Map<String, dynamic>? selectedEncadrant;

  TextEditingController encadrant = TextEditingController();
  TextEditingController emailEnc = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
    loadUsers();
    loadMetadata();
  }

  // ================= LOAD METADATA =================
  Future loadMetadata() async {
    try {
      final baseUrl = Config.baseUrl;
      final resDept = await http.get(Uri.parse('$baseUrl/departements'));
      final resSpec = await http.get(Uri.parse('$baseUrl/specialites'));
      
      setState(() {
        departements = jsonDecode(resDept.body);
        specialites = jsonDecode(resSpec.body);
      });
    } catch (e) {
      print("Error loading metadata: $e");
    }
  }

  // ================= LOAD USERS =================
  Future loadUsers() async {
    try {
      final data = await api.getUsers();

      setState(() {
        allUsers = data;
        users = data.where((u) {
          final role = (u['role'] ?? '')
              .toString()
              .toLowerCase()
              .trim();

          return role.contains("academ") ||
                 role.contains("prof");
        }).toList();
      });

      print("USERS => $users");
    } catch (e) {
      print(e);
    }
  }
  // ================= LOAD =================
  Future load() async {
    setState(() => loading = true);

    try {
      final data = await api.getMyEncadrements();

      setState(() {
        encadrements = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ================= ADD DIALOG =================
  void addDialog() {
    final outerCtx = context; // capture page context before dialog opens
    final formKey = GlobalKey<FormState>();
    final annee = TextEditingController(text: "2025-2026");
    String? selectedNiveau;
    String? selectedDept;
    String? selectedSpec;
    Map<String, dynamic>? selEncadrant;
    Map<String, dynamic>? selStudent;
    final emailEncCtrl = TextEditingController();
    final emailEtudCtrl = TextEditingController();

    showDialog(
      context: outerCtx,
      builder: (_) => StatefulBuilder(
        builder: (dlgCtx, setS) {
          // Filter encadrants by selected department
          List filteredAdvisors = allUsers.where((u) {
            final role = (u['role'] ?? '').toString().toLowerCase();
            if (!role.contains("academ") && !role.contains("prof")) return false;
            if (selectedDept == null) return false;
            return u['departement'] == selectedDept;
          }).toList();

          // Filter students by selected department AND specialité
          List filteredStudents = allUsers.where((u) {
            final role = (u['role'] ?? '').toString().toLowerCase();
            if (!role.contains("student") && !role.contains("etudiant")) return false;
            if (selectedDept == null) return false;
            if (u['departement'] != selectedDept) return false;
            if (selectedSpec != null && u['specialite'] != selectedSpec) return false;
            return true;
          }).toList();

          // Filter specialités by selected department ID
          List<DropdownMenuItem<String>> filteredSpecItems() {
            if (selectedDept == null) return [];
            final deptMatches = departements.where((d) => d['nom'].toString() == selectedDept).toList();
            if (deptMatches.isEmpty) return [];
            final deptId = deptMatches.first['id'];
            return specialites
                .where((s) => s['departementId'] == deptId)
                .map((s) => DropdownMenuItem<String>(value: s['nom'].toString(), child: Text(s['nom'])))
                .toList();
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusXl)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
                gradient: AdminTheme.dialogHeaderGradient,
              ),
              width: MediaQuery.of(dlgCtx).size.width * 0.95,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(dlgCtx).size.height * 0.88),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                        ),
                        child: const Icon(Icons.assignment_ind_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Ajouter un encadrement',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(dlgCtx),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close, color: Colors.white70, size: 18),
                        ),
                      ),
                    ]),
                  ),
                  // ── Body ──
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AdminTheme.cardBg,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(AdminTheme.radiusXl),
                          bottomRight: Radius.circular(AdminTheme.radiusXl),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Année + Niveau
                              _rRow(dlgCtx,
                                AdminTheme.formField(
                                  annee,
                                  'Année académique *',
                                  Icons.calendar_today_outlined,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                                ),
                                AdminTheme.dropdownField<String>(
                                  label: 'Niveau *',
                                  value: selectedNiveau,
                                  icon: Icons.grade_outlined,
                                  validator: (v) => v == null ? 'Champ obligatoire' : null,
                                  items: [
                                    '3ème Licence',
                                    '2ème Master Professionnel',
                                    '2ème Master Recherche',
                                  ].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                  onChanged: (v) => setS(() => selectedNiveau = v),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Département + Spécialité (filtrée)
                              _rRow(dlgCtx,
                                AdminTheme.dropdownField<String>(
                                  label: 'Département *',
                                  value: selectedDept,
                                  icon: Icons.apartment_outlined,
                                  validator: (v) => v == null ? 'Champ obligatoire' : null,
                                  items: departements
                                      .map((d) => DropdownMenuItem(value: d['nom'].toString(), child: Text(d['nom'])))
                                      .toList(),
                                  onChanged: (v) => setS(() {
                                    selectedDept = v;
                                    selectedSpec = null; // reset spécialité
                                    selEncadrant = null;
                                    selStudent = null;
                                    emailEncCtrl.clear();
                                    emailEtudCtrl.clear();
                                  }),
                                ),
                                AdminTheme.dropdownField<String>(
                                  label: 'Spécialité *',
                                  value: selectedSpec,
                                  icon: Icons.book_outlined,
                                  hint: Text(selectedDept == null
                                      ? 'Choisissez un département d\'abord'
                                      : 'Sélectionnez une spécialité'),
                                  validator: (v) => v == null ? 'Champ obligatoire' : null,
                                  items: filteredSpecItems(),
                                  onChanged: (v) => setS(() {
                                    selectedSpec = v;
                                    selStudent = null;
                                    emailEtudCtrl.clear();
                                  }),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Encadrant + Email encadrant
                              _rRow(dlgCtx,
                                AdminTheme.dropdownField<Map<String, dynamic>>(
                                  label: 'Encadrant *',
                                  value: selEncadrant,
                                  icon: Icons.person_outline,
                                  hint: Text(selectedDept == null
                                      ? 'Choisissez un département'
                                      : "Sélectionnez l'encadrant"),
                                  validator: (v) => v == null ? 'Champ obligatoire' : null,
                                  items: filteredAdvisors.map((u) => DropdownMenuItem<Map<String, dynamic>>(
                                    value: u as Map<String, dynamic>,
                                    child: Text('${u['name']} ${u['prenom'] ?? ''}'),
                                  )).toList(),
                                  onChanged: (v) => setS(() {
                                    selEncadrant = v;
                                    emailEncCtrl.text = v?['email'] ?? '';
                                  }),
                                ),
                                AdminTheme.formField(emailEncCtrl, 'Email encadrant', Icons.email_outlined, readOnly: true),
                              ),
                              const SizedBox(height: 14),
                              // Étudiant + Email étudiant
                              _rRow(dlgCtx,
                                AdminTheme.dropdownField<Map<String, dynamic>>(
                                  label: 'Étudiant *',
                                  value: selStudent,
                                  icon: Icons.school_outlined,
                                  hint: Text(selectedDept == null
                                      ? 'Choisissez un département'
                                      : selectedSpec == null
                                          ? 'Choisissez une spécialité'
                                          : "Sélectionnez l'étudiant"),
                                  validator: (v) => v == null ? 'Champ obligatoire' : null,
                                  items: filteredStudents.map((u) => DropdownMenuItem<Map<String, dynamic>>(
                                    value: u as Map<String, dynamic>,
                                    child: Text('${u['name']} ${u['prenom'] ?? ''}'),
                                  )).toList(),
                                  onChanged: (v) => setS(() {
                                    selStudent = v;
                                    emailEtudCtrl.text = v?['email'] ?? '';
                                  }),
                                ),
                                AdminTheme.formField(emailEtudCtrl, 'Email étudiant', Icons.email_outlined, readOnly: true),
                              ),
                              const SizedBox(height: 24),
                              // Boutons
                              Row(children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                                      side: const BorderSide(color: AdminTheme.border),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: () => Navigator.pop(dlgCtx),
                                    child: const Text('Annuler', style: TextStyle(color: AdminTheme.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: () async {
                                      // Validate all required fields (shows red borders)
                                      if (!formKey.currentState!.validate()) {
                                        AdminTheme.snack(outerCtx, 'Veuillez remplir tous les champs obligatoires (*)', warning: true);
                                        return;
                                      }
                                      try {
                                        final created = await api.createEncadrement({
                                          'annee': annee.text,
                                          'encadrantId': selEncadrant?['id'],
                                          'niveau': selectedNiveau,
                                          'specialite': selectedSpec,
                                          'emailEtudiant': emailEtudCtrl.text,
                                        });
                                        setState(() => encadrements.insert(0, created));
                                        await api.sendEncadrementMessage(created['id']);
                                        Navigator.pop(dlgCtx); // close dialog only
                                        AdminTheme.snack(outerCtx, '✅ Encadrement créé et notifié !');
                                      } catch (err) {
                                        AdminTheme.snack(outerCtx, 'Erreur: ${err.toString()}', error: true);
                                      }
                                    },
                                    child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
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
          );
        },
      ),
    );
  }

  Widget _rRow(BuildContext context, Widget left, Widget right) {
    return MediaQuery.of(context).size.width > 600
        ? Row(children: [Expanded(child: left), const SizedBox(width: 14), Expanded(child: right)])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 14), right]);
  }

  void _confirmDelete(int id, int idx) {
    AdminTheme.confirmDelete(
      context: context,
      title: 'Supprimer encadrement',
      message: 'Supprimer cet encadrement ? Cette action est irréversible.',
      onConfirm: () async {
        await api.deleteEncadrement(id);
        setState(() => encadrements.removeAt(idx));
        AdminTheme.snack(context, 'Encadrement supprimé', error: true);
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Encadrements',
        subtitle: 'Gestion des binômes étudiants · encadrants',
        showBack: true,
        context: context,
        actions: [
          AdminTheme.appBarAction(
            icon: Icons.add_rounded,
            tooltip: 'Ajouter un encadrement',
            onPressed: addDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
          : encadrements.isEmpty
              ? AdminTheme.emptyState(
                  icon: Icons.assignment_ind_outlined,
                  message: 'Aucun encadrement',
                  sub: 'Appuyez sur + pour en créer un',
                )
              : RefreshIndicator(
                  onRefresh: load,
                  color: AdminTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: encadrements.length,
                    itemBuilder: (context, i) {
                      final e = encadrements[i];
                      final studentName = "${e["student"]?["name"] ?? ''} ${e["student"]?["prenom"] ?? ''}".trim();
                      final studentEmail = e["student"]?["email"] ?? '';
                      final encadrantName = "${e["encadrant"]?["name"] ?? ''} ${e["encadrant"]?["prenom"] ?? ''}".trim();
                      final encadrantEmail = e["encadrant"]?["email"] ?? '';
                      final spec = e["specialite"] ?? '';
                      final lvl = e["niveau"] ?? '';
                      final isSent = (e["status"] ?? '') == 'sent';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AdminTheme.cardBg,
                          borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                          border: Border.all(color: AdminTheme.divider),
                          boxShadow: AdminTheme.cardShadow,
                        ),
                        child: Column(
                          children: [
                            // Card header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AdminTheme.primary.withOpacity(0.04),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(AdminTheme.radiusLg),
                                  topRight: Radius.circular(AdminTheme.radiusLg),
                                ),
                                border: Border(bottom: BorderSide(color: AdminTheme.divider)),
                              ),
                              child: Row(
                                children: [
                                  AdminTheme.iconContainer(Icons.school_outlined, size: 16),
                                  const SizedBox(width: 10),
                                  Text(
                                    e["annee"] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AdminTheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  AdminTheme.statusBadge(
                                    isSent ? 'Notifié' : 'En attente',
                                    color: isSent ? AdminTheme.success : AdminTheme.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AdminTheme.danger, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDelete(e["id"], i),
                                  ),
                                ],
                              ),
                            ),
                            // Card body
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Student
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AdminTheme.sectionLabel('Étudiant'),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              AdminTheme.iconContainer(Icons.person_outline, size: 14),
                                              const SizedBox(width: 8),
                                              Expanded(child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(studentName.isNotEmpty ? studentName : 'N/A',
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminTheme.textPrimary)),
                                                  Text(studentEmail, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                                                ],
                                              )),
                                            ]),
                                          ],
                                        ),
                                      ),
                                      Container(width: 1, height: 50, color: AdminTheme.divider, margin: const EdgeInsets.symmetric(horizontal: 12)),
                                      // Encadrant
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AdminTheme.sectionLabel('Encadrant'),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              AdminTheme.iconContainer(Icons.assignment_ind_outlined, size: 14),
                                              const SizedBox(width: 8),
                                              Expanded(child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(encadrantName.isNotEmpty ? encadrantName : 'N/A',
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminTheme.textPrimary)),
                                                  Text(encadrantEmail, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                                                ],
                                              )),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (spec.isNotEmpty || lvl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AdminTheme.surface,
                                        borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                                        border: Border.all(color: AdminTheme.divider),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.bookmark_outline, size: 14, color: AdminTheme.textSecondary),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(
                                          "$lvl${spec.isNotEmpty ? ' · $spec' : ''}",
                                          style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                        )),
                                      ]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}