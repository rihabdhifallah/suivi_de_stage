import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config.dart';
import 'package:frontend/screens/add_company_page.dart';
import 'package:frontend/screens/encadrement_page.dart';
import 'package:frontend/screens/specialites_departements_page.dart';
import 'package:frontend/screens/specialites_page.dart';
import 'package:frontend/screens/departements_page.dart';
import 'package:frontend/screens/encadrants_pro_page.dart';
import 'package:frontend/screens/etudiants_page.dart';
import 'package:frontend/screens/academiques_page.dart';
import 'package:frontend/screens/entreprises_page.dart';
import 'package:frontend/theme/admin_theme.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final api = ApiService();

  final String baseUrl = "http://192.168.100.30:3001";

  List users = [];
  List companies = [];
  List filteredCompanies = [];
List stages = [];
  bool loading = true;
  int index = 0;
List students = [];
List offres = [];
List demandes = [];

  final _formKey = GlobalKey<FormState>();
  final telephoneCtrl = TextEditingController();

  String? validateRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  String? validateCINPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
    if (v.trim().length != 8) return '8 chiffres requis';
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
    if (!v.contains('@')) return 'Email invalide';
    return null;
  }



 @override
void initState() {
  super.initState();
  loadData();
    loadStudents();
      loadAdminOffres();  
        loadDemandes();
 



  Future.doWhile(() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
await loadStages();    }
    return true;
  });
}
Future loadDemandes() async {
  final res = await http.get(Uri.parse('$baseUrl/demandes'));

  setState(() {
    demandes = jsonDecode(res.body);
  });
}
Future loadStudents() async {
  final data = await api.getStudents();

  setState(() {
    students = data;
  });
}
Future<void> loadAdminOffres() async {
  final data = await ApiService().getAdminOffres();

  setState(() {
    offres = data;
  });
}
  // ================= LOAD =================
  Future<void> loadData() async {

    setState(() => loading = true);

    try {
      users = await api.getUsers();
      companies = await api.getCompanies();
      filteredCompanies = companies;
await loadStages(); 
    } catch (e) {
      print(e);
    }

    setState(() => loading = false);
  }

  // ================= TASKS =================
 Future<void> loadStages() async {
  final res = await http.get(Uri.parse('$baseUrl/stages'));

  if (res.statusCode == 200) {
    stages = jsonDecode(res.body);
    setState(() {});
  }
}
Future sendPdfToCompany({
  required String email,
  required List<int> pdfBytes,
}) async {
  await http.post(
    Uri.parse('$baseUrl/mail/send-pdf'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "pdf": base64Encode(pdfBytes),
    }),
  );
}
Future getAdminOffres() async {
  final res = await http.get(
Uri.parse("${Config.baseUrl}/offres/admin/all")  );

  return jsonDecode(res.body);
}
void openFile(String filename) async {
  final url = Uri.parse(
    "http://192.168.100.30:3001/demandes/file/$filename"
  );

  await launchUrl(url, mode: LaunchMode.externalApplication);
}
void load() async {
  demandes = await api.getDemandes();
  setState(() {});
}

void showDemandeDetails(d) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        decoration: const BoxDecoration(
          color: AdminTheme.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AdminTheme.radiusXl)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AdminTheme.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Row(children: [
                AdminTheme.iconContainer(Icons.assignment_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(d['titre'] ?? 'Demande',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary))),
              ]),
              const SizedBox(height: 20),
              // Sections
              _detailSection('Entreprise', Icons.business_outlined, AdminTheme.teal, [
                _detailRow('Nom', d['entreprise']),
                _detailRow('Secteur', d['secteur']),
                _detailRow('Adresse', d['adresse']),
              ]),
              const SizedBox(height: 14),
              _detailSection('Encadrant', Icons.person_outline, AdminTheme.warning, [
                _detailRow('Nom', d['encadrant_nom']),
                _detailRow('Email', d['encadrant_email']),
                _detailRow('Tél', d['encadrant_tel']),
              ]),
              const SizedBox(height: 14),
              _detailSection('Stage', Icons.school_outlined, AdminTheme.primary, [
                _detailRow('Mission', d['mission']),
                _detailRow('Compétences', d['skills']),
                _detailRow('Durée', d['duree']),
                _detailRow('Début', d['date_debut']),
                _detailRow('Fin', d['date_fin']),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.danger,
                      side: const BorderSide(color: AdminTheme.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () async {
                      await api.updateDemandeStatus(d['id'], 'rejected');
                      Navigator.pop(context);
                      await loadDemandes();
                      AdminTheme.snack(context, 'Demande refusée', error: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () async {
                      await api.updateDemandeStatus(d['id'], 'accepted');
                      Navigator.pop(context);
                      await loadDemandes();
                      AdminTheme.snack(context, 'Demande acceptée');
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      );
    },
  );
}

Widget _detailSection(String title, IconData icon, Color color, List<Widget> rows) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AdminTheme.surface,
      borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
      border: Border.all(color: AdminTheme.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 10),
      ...rows,
    ]),
  );
}

Widget _detailRow(String label, dynamic value) {
  if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary))),
      const SizedBox(width: 8),
      Expanded(child: Text(value.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AdminTheme.textPrimary))),
    ]),
  );
}

   // ================= ADD STUDENT DIALOG =================
  void _showAddStudentDialog() {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final cinCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final adresseCtrl = TextEditingController();
    final dateNaissanceCtrl = TextEditingController();
    final universiteCtrl = TextEditingController();
    String? selectedNiveau;
    String? selectedGenre;
    String? selectedSpecialite;
    List<String> specialitesList = [];
    bool isSpecsLoading = false;
    Map<String, dynamic>? selectedDepartementObj; // {id, nom}
    List<Map<String, dynamic>> departementsObjList = [];
    bool isDeptsLoading = true;
    bool isLoading = false;
    String? emailError;

    const niveaux = ['3ème Licence', '1ère Master Professionnel', '2ème Master Recherche'];
    const genres = ['Homme', 'Femme'];

    Future<void> fetchSpecsByDept(StateSetter setS, int deptId) async {
      setS(() { isSpecsLoading = true; specialitesList = []; selectedSpecialite = null; });
      try {
        final data = await api.getSpecialitesByDepartement(deptId);
        setS(() {
          specialitesList = data.map((d) => (d['nom'] as String)).toList();
          isSpecsLoading = false;
        });
      } catch (e) {
        setS(() => isSpecsLoading = false);
      }
    }

    Future<void> fetchDepts(StateSetter setS) async {
      try {
        final res = await http.get(Uri.parse('${Config.baseUrl}/departements'));
        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);
          setS(() {
            departementsObjList = data.map((d) => {'id': d['id'], 'nom': d['nom'] as String}).toList().cast<Map<String, dynamic>>();
            isDeptsLoading = false;
          });
        }
      } catch (e) {
        setS(() => isDeptsLoading = false);
      }
    }

    void showAddDeptInlineDialog(StateSetter setS) {
      final deptNameCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouveau Département', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: deptNameCtrl,
            decoration: InputDecoration(
              labelText: 'Nom du département *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = deptNameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final response = await http.post(
                    Uri.parse('${Config.baseUrl}/departements'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'nom': name}),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    final created = jsonDecode(response.body);
                    Navigator.pop(dialogCtx);
                    await fetchDepts(setS);
                    setS(() {
                      selectedDepartementObj = {'id': created['id'], 'nom': name};
                      specialitesList = [];
                      selectedSpecialite = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Département "$name" ajouté !'),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${response.body}'),
                        backgroundColor: Colors.red.shade600,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red.shade600),
                  );
                }
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    void showAddSpecInlineDialog(StateSetter setS) {
      final specNameCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouvelle Spécialité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: specNameCtrl,
            decoration: InputDecoration(
              labelText: 'Nom de la spécialité *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = specNameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final response = await http.post(
                    Uri.parse('${Config.baseUrl}/specialites'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'nom': name,
                      if (selectedDepartementObj != null) 'departementId': selectedDepartementObj!['id'],
                    }),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(dialogCtx);
                    if (selectedDepartementObj != null) {
                      await fetchSpecsByDept(setS, selectedDepartementObj!['id'] as int);
                    }
                    setS(() => selectedSpecialite = name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Spécialité "$name" ajoutée !'),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: ${response.body}'), backgroundColor: Colors.red.shade600),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red.shade600),
                  );
                }
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (isDeptsLoading && departementsObjList.isEmpty) {
            fetchDepts(setS);
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF002366), Color(0xFF1a3a6e)],
                  stops: [0.0, 0.18],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                           'Ajouter un étudiant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Colors.white70, size: 20),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row: Nom + Prénom
                            Row(
                              children: [
                                Expanded(child: _field(nomCtrl, 'Nom *', Icons.person_outline, validator: validateRequired)),
                                const SizedBox(width: 10),
                                Expanded(child: _field(prenomCtrl, 'Prénom *', Icons.person_outline, validator: validateRequired)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // CIN
                            _field(cinCtrl, 'CIN *', Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: validateCINPhone),
                            const SizedBox(height: 12),
                            // Téléphone
                            _field(telephoneCtrl, 'Téléphone *', Icons.phone_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: validateCINPhone),
                            const SizedBox(height: 12),
                            // Email with uniqueness check
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _field(emailCtrl, 'Email *', Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                                      if (!v.contains('@')) return 'Email invalide';
                                      if (emailError != null) return emailError;
                                      return null;
                                    },
                                    onEditingComplete: () async {
                                      final email = emailCtrl.text.trim();
                                      if (email.contains('@')) {
                                        final available = await api.checkEmailAvailable(email);
                                        setS(() => emailError = available ? null : 'Cet email est déjà utilisé');
                                        _formKey.currentState?.validate();
                                      }
                                    }),
                                if (emailError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 12),
                                    child: Text(emailError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          // Date de naissance
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1970),
                                lastDate: DateTime.now(),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF002366),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setS(() {
                                  dateNaissanceCtrl.text =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: _field(dateNaissanceCtrl, 'Date de naissance *', Icons.calendar_today_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Genre dropdown
                          _dropdownField(
                            label: 'Genre *',
                            icon: Icons.wc,
                            value: selectedGenre,
                            items: genres,
                            onChanged: (v) => setS(() => selectedGenre = v),
                            validator: validateRequired,
                          ),
                          const SizedBox(height: 12),
                          // Niveau dropdown
                          _dropdownField(
                            label: 'Niveau *',
                            icon: Icons.school_outlined,
                            value: selectedNiveau,
                            items: niveaux,
                            onChanged: (v) => setS(() => selectedNiveau = v),
                            validator: validateRequired,
                          ),
                          const SizedBox(height: 12),
                          // Université
                          _field(universiteCtrl, 'Université *', Icons.account_balance_outlined, validator: validateRequired),
                          const SizedBox(height: 12),
                          // Département dropdown with dynamic list and inline add
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: isDeptsLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: LinearProgressIndicator(color: Color(0xFF002366)),
                                      )
                                    : DropdownButtonFormField<Map<String, dynamic>>(
                                        value: selectedDepartementObj,
                                        decoration: InputDecoration(
                                          labelText: 'Département *',
                                          prefixIcon: const Icon(Icons.apartment_outlined, size: 18, color: Color(0xFF002366)),
                                          isDense: true,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF002366), width: 1.5),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                        ),
                                        items: departementsObjList.map((d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d['nom'] as String, style: const TextStyle(fontSize: 13)),
                                        )).toList(),
                                        onChanged: (v) {
                                          setS(() {
                                            selectedDepartementObj = v;
                                            selectedSpecialite = null;
                                            specialitesList = [];
                                          });
                                          if (v != null) fetchSpecsByDept(setS, v['id'] as int);
                                        },
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Spécialité dropdown — filtered by selected département
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: isSpecsLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: LinearProgressIndicator(color: Color(0xFF002366)),
                                      )
                                    : selectedDepartementObj == null
                                        ? InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Spécialité *',
                                              prefixIcon: const Icon(Icons.book_outlined, size: 18, color: Colors.grey),
                                              isDense: true,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                            ),
                                            child: Text('Choisir un département d\'abord', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                          )
                                        : specialitesList.isEmpty
                                            ? InputDecorator(
                                                decoration: InputDecoration(
                                                  labelText: 'Spécialité *',
                                                  prefixIcon: const Icon(Icons.book_outlined, size: 18, color: Colors.grey),
                                                  isDense: true,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                  filled: true,
                                                  fillColor: Colors.grey.shade100,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                                ),
                                                child: Text('Aucune spécialité pour ce département', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                              )
                                            : _dropdownField(
                                                label: 'Spécialité *',
                                                icon: Icons.book_outlined,
                                                value: selectedSpecialite,
                                                items: specialitesList,
                                                onChanged: (v) => setS(() => selectedSpecialite = v),
                                              ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Adresse
                          _field(adresseCtrl, 'Adresse', Icons.location_on_outlined, maxLines: 2),
                          const SizedBox(height: 20),
                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Veuillez remplir tous les champs obligatoires'),
                                            backgroundColor: Colors.orange.shade700,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }
                                      // Check email uniqueness before submit
                                      final emailOk = await api.checkEmailAvailable(emailCtrl.text.trim());
                                      if (!emailOk) {
                                        setS(() => emailError = 'Cet email est déjà utilisé');
                                        _formKey.currentState?.validate();
                                        return;
                                      }
                                      setS(() => isLoading = true);
                                      try {
                                        final responseData = await api.createStudent({
                                          'nom': nomCtrl.text.trim(),
                                          'prenom': prenomCtrl.text.trim(),
                                          'cin': cinCtrl.text.trim(),
                                          'email': emailCtrl.text.trim(),
                                          'adresse': adresseCtrl.text.trim(),
                                          'phone': telephoneCtrl.text.trim(),
                                          'dateNaissance': dateNaissanceCtrl.text,
                                          'genre': selectedGenre,
                                          'niveau': selectedNiveau,
                                          'universite': universiteCtrl.text.trim(),
                                          'departement': selectedDepartementObj?['nom'],
                                          'specialite': selectedSpecialite,
                                        });
                                        Navigator.pop(ctx);
                                        await loadStudents();
                                        await loadData();
                                        showDialog(
                                          context: context,
                                          builder: (dCtx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.green),
                                                SizedBox(width: 8),
                                                Text('Étudiant créé avec succès', style: TextStyle(fontSize: 16)),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text("Les accès ont été générés et envoyés à l'étudiant par email. Vous pouvez également les copier ci-dessous :"),
                                                const SizedBox(height: 16),
                                                SelectableText("Email : ${responseData['email'] ?? emailCtrl.text.trim()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                SelectableText("Mot de passe : ${responseData['password'] ?? '... '}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dCtx),
                                                child: const Text('Fermer'),
                                              ),
                                            ],
                                          ),
                                        );
                                      } catch (e) {
                                        setS(() => isLoading = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Erreur: ${e.toString()}'),
                                            backgroundColor: Colors.red.shade600,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Créer le compte étudiant',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Le mot de passe sera envoyé automatiquement par email',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
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


  void _showAddAcademiqueDialog() {
    final _formKeyAcad = GlobalKey<FormState>();
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final cinCtrl = TextEditingController();
    final telephoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final etablissementCtrl = TextEditingController();
    Map<String, dynamic>? selectedDepartementObj;
    List<Map<String, dynamic>> departementsObjList = [];
    bool isDeptsLoading = true;
    String? selectedSpecialite;
    List<String> specialitesList = [];
    bool isSpecsLoading = false;
    bool isLoading = false;
    String? emailError;

    Future<void> fetchSpecsByDept(StateSetter setS, int deptId) async {
      setS(() { isSpecsLoading = true; specialitesList = []; selectedSpecialite = null; });
      try {
        final data = await api.getSpecialitesByDepartement(deptId);
        setS(() {
          specialitesList = data.map((d) => (d['nom'] as String)).toList();
          isSpecsLoading = false;
        });
      } catch (e) {
        setS(() => isSpecsLoading = false);
      }
    }

    Future<void> fetchDepts(StateSetter setS) async {
      try {
        final res = await http.get(Uri.parse('${Config.baseUrl}/departements'));
        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);
          setS(() {
            departementsObjList = data.map((d) => {'id': d['id'], 'nom': d['nom'] as String}).toList().cast<Map<String, dynamic>>();
            isDeptsLoading = false;
          });
        }
      } catch (e) {
        setS(() => isDeptsLoading = false);
      }
    }

    void showAddSpecInlineDialog(StateSetter setS) {
      final specNameCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouvelle Spécialité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: specNameCtrl,
            decoration: InputDecoration(
              labelText: 'Nom de la spécialité *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = specNameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final response = await http.post(
                    Uri.parse('${Config.baseUrl}/specialites'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'nom': name,
                      if (selectedDepartementObj != null) 'departementId': selectedDepartementObj!['id'],
                    }),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(dialogCtx);
                    if (selectedDepartementObj != null) {
                      await fetchSpecsByDept(setS, selectedDepartementObj!['id'] as int);
                    }
                    setS(() => selectedSpecialite = name);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ Spécialité "$name" ajoutée !'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erreur: ${response.body}'),
                      backgroundColor: Colors.red.shade600,
                    ));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur: $e'), backgroundColor: Colors.red.shade600,
                  ));
                }
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    void showAddDeptInlineDialog(StateSetter setS) {
      final deptNameCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouveau Département', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: deptNameCtrl,
            decoration: InputDecoration(
              labelText: 'Nom du département *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = deptNameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final response = await http.post(
                    Uri.parse('${Config.baseUrl}/departements'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'nom': name}),
                  );
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    final created = jsonDecode(response.body);
                    Navigator.pop(dialogCtx);
                    await fetchDepts(setS);
                    setS(() {
                      selectedDepartementObj = {'id': created['id'], 'nom': name};
                      specialitesList = [];
                      selectedSpecialite = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('✅ Département "$name" ajouté !'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erreur: ${response.body}'), backgroundColor: Colors.red.shade600,
                    ));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur: $e'), backgroundColor: Colors.red.shade600,
                  ));
                }
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (isDeptsLoading && departementsObjList.isEmpty) {
            fetchDepts(setS);
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF002366), Color(0xFF1a3a6e)],
                  stops: [0.0, 0.18],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_ind_outlined, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ajouter un encadrant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Colors.white70, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Form(
                        key: _formKeyAcad,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _field(nomCtrl, 'Nom *', Icons.person_outline, validator: validateRequired)),
                                const SizedBox(width: 10),
                                Expanded(child: _field(prenomCtrl, 'Prénom *', Icons.person_outline, validator: validateRequired)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _field(cinCtrl, 'CIN *', Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: validateCINPhone),
                            const SizedBox(height: 12),
                            _field(telephoneCtrl, 'Téléphone *', Icons.phone_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: validateCINPhone),
                            const SizedBox(height: 12),
                            // Email with uniqueness check
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _field(emailCtrl, 'Email *', Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                                      if (!v.contains('@')) return 'Email invalide';
                                      if (emailError != null) return emailError;
                                      return null;
                                    },
                                    onEditingComplete: () async {
                                      final email = emailCtrl.text.trim();
                                      if (email.contains('@')) {
                                        final available = await api.checkEmailAvailable(email);
                                        setS(() => emailError = available ? null : 'Cet email est déjà utilisé');
                                        _formKeyAcad.currentState?.validate();
                                      }
                                    }),
                                if (emailError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 12),
                                    child: Text(emailError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _field(etablissementCtrl, 'Établissement *', Icons.account_balance_outlined, validator: validateRequired),
                          const SizedBox(height: 12),
                          // Département dropdown
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: isDeptsLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: LinearProgressIndicator(color: Color(0xFF002366)),
                                      )
                                    : DropdownButtonFormField<Map<String, dynamic>>(
                                        value: selectedDepartementObj,
                                        decoration: InputDecoration(
                                          labelText: 'Département *',
                                          prefixIcon: const Icon(Icons.apartment_outlined, size: 18, color: Color(0xFF002366)),
                                          isDense: true,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF002366), width: 1.5),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                        ),
                                        items: departementsObjList.map((d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d['nom'] as String, style: const TextStyle(fontSize: 13)),
                                        )).toList(),
                                        onChanged: (v) {
                                          setS(() {
                                            selectedDepartementObj = v;
                                            selectedSpecialite = null;
                                            specialitesList = [];
                                          });
                                          if (v != null) fetchSpecsByDept(setS, v['id'] as int);
                                        },
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Spécialité dropdown — filtered by département
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: isSpecsLoading
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: LinearProgressIndicator(color: Color(0xFF002366)),
                                      )
                                    : selectedDepartementObj == null
                                        ? InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Spécialité *',
                                              prefixIcon: const Icon(Icons.book_outlined, size: 18, color: Colors.grey),
                                              isDense: true,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                            ),
                                            child: Text("Choisir un département d'abord", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                          )
                                        : specialitesList.isEmpty
                                            ? InputDecorator(
                                                decoration: InputDecoration(
                                                  labelText: 'Spécialité *',
                                                  prefixIcon: const Icon(Icons.book_outlined, size: 18, color: Colors.grey),
                                                  isDense: true,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                  filled: true,
                                                  fillColor: Colors.grey.shade100,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                                ),
                                                child: Text('Aucune spécialité pour ce département', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                              )
                                            : _dropdownField(
                                                label: 'Spécialité *',
                                                icon: Icons.book_outlined,
                                                value: selectedSpecialite,
                                                items: specialitesList,
                                                onChanged: (v) => setS(() => selectedSpecialite = v),
                                              ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (!_formKeyAcad.currentState!.validate()) return;
                                      final emailOk = await api.checkEmailAvailable(emailCtrl.text.trim());
                                      if (!emailOk) {
                                        setS(() => emailError = 'Cet email est déjà utilisé');
                                        _formKeyAcad.currentState?.validate();
                                        return;
                                      }
                                      setS(() => isLoading = true);
                                      try {
                                        final responseData = await api.createAcademique({
                                          'nom': nomCtrl.text.trim(),
                                          'prenom': prenomCtrl.text.trim(),
                                          'cin': cinCtrl.text.trim(),
                                          'email': emailCtrl.text.trim(),
                                          'phone': telephoneCtrl.text.trim(),
                                          'etablissement': etablissementCtrl.text.trim(),
                                          'departement': selectedDepartementObj?['nom'],
                                          'specialite': selectedSpecialite,
                                        });
                                        Navigator.pop(ctx);
                                        await loadData();
                                        showDialog(
                                          context: context,
                                          builder: (dCtx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Row(children: [
                                              Icon(Icons.check_circle, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Encadrant créé avec succès', style: TextStyle(fontSize: 16)),
                                            ]),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text("Les accès ont été générés et envoyés à l'encadrant par email."),
                                                const SizedBox(height: 16),
                                                SelectableText("Email : ${responseData['email'] ?? emailCtrl.text.trim()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                SelectableText("Mot de passe : ${responseData['password'] ?? '...'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Fermer'))],
                                          ),
                                        );
                                      } catch (e) {
                                        setS(() => isLoading = false);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Erreur: ${e.toString()}'),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Créer le compte encadrant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Le mot de passe sera envoyé automatiquement par email',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
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

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onEditingComplete,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      inputFormatters: inputFormatters,
      onEditingComplete: onEditingComplete,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AdminTheme.primary),
        isDense: true,
        counterText: '',
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF002366), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AdminTheme.primary),
        isDense: true,
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF002366), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  // ================= LOGOUT =================
  void logout() async {
    await api.storage.deleteAll();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  // ================= CONTACT COMPANY =================
 void contactCompany(dynamic company) {
  final facName = TextEditingController();
  final facEmail = TextEditingController();
  final facPhone = TextEditingController();
  final facPays = TextEditingController();
final messageController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Demande de stage"),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: facName,
              decoration: const InputDecoration(labelText: "Nom Faculté"),
            ),
            TextField(
              controller: facEmail,
              decoration: const InputDecoration(labelText: "Email Faculté"),
            ),
            TextField(
              controller: facPhone,
              decoration: const InputDecoration(labelText: "Téléphone"),
            ),
             TextField(
              controller: facPays,
              decoration: const InputDecoration(labelText: "Pays"),
            ),
            TextField(
  controller: messageController,
  decoration: const InputDecoration(labelText: "Message"),
),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),

          ElevatedButton(
            onPressed: () async {
              if (facName.text.trim().isEmpty ||
    facEmail.text.trim().isEmpty ||
    facPhone.text.trim().isEmpty ||
    facPays.text.trim().isEmpty ||
    messageController.text.trim().isEmpty) {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Remplir tous les champs")),
  );
  return;
}
    
final res = await http.post(
  Uri.parse('$baseUrl/tasks'),
  headers: {"Content-Type": "application/json"},
  body: jsonEncode({
    "titre": "Demande de stage",
    "sender": "admin",
    "receiver": company['email'].toString().trim().toLowerCase(),
    "fac_name": facName.text,
    "fac_email": facEmail.text,
    "fac_phone": facPhone.text,
    "fac_pays": facPays.text,
    "message": messageController.text,
    "status": "en attente"
  }),
);
print("STATUS CODE => ${res.statusCode}");
              print("SEND RES => ${res.body}");

              Navigator.pop(context);
await loadStages(); 
            },
            child: const Text("Envoyer"),
          ),
        ],
      );
    },
  );
}

  // ================= FILTER =================
  void filterCompanies(String value) {
    setState(() {
      filteredCompanies = companies.where((c) {
        final name = (c['name'] ?? '').toLowerCase();
        final email = (c['email'] ?? '').toLowerCase();
        final country = (c['country'] ?? '').toLowerCase();

        return name.contains(value.toLowerCase()) ||
            email.contains(value.toLowerCase()) ||
            country.contains(value.toLowerCase());
      }).toList();
    });
  }

  // ================= TASKS VIEW =================
Widget stagesView() {
  if (stages.isEmpty) {
    return AdminTheme.emptyState(icon: Icons.school_outlined, message: 'Aucun stage disponible');
  }
  return RefreshIndicator(
    onRefresh: loadStages,
    color: AdminTheme.primary,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: stages.length,
      itemBuilder: (_, i) {
        final s = stages[i];
        final status = s['status'] ?? '';
        Color statusColor = status == 'en attente' ? AdminTheme.warning
            : status == 'accepté' ? AdminTheme.success
            : AdminTheme.textSecondary;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AdminTheme.cardBg,
            borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
            border: Border.all(color: AdminTheme.divider),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AdminTheme.iconContainer(Icons.school_outlined, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s['titre'] ?? 'Stage', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.primary)),
                    ),
                    AdminTheme.statusBadge(status.isEmpty ? 'N/A' : status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if ((s['domaine'] ?? '').isNotEmpty) _chip(Icons.category_outlined, s['domaine']),
                    if ((s['duree'] ?? '').isNotEmpty) _chip(Icons.timer_outlined, s['duree']),
                    if ((s['niveau'] ?? '').isNotEmpty) _chip(Icons.grade_outlined, s['niveau']),
                    if ((s['city'] ?? '').isNotEmpty) _chip(Icons.location_on_outlined, s['city']),
                  ],
                ),
                if ((s['companyName'] ?? s['companyEmail'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.business_outlined, size: 13, color: AdminTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(s['companyName'] ?? s['companyEmail'] ?? '', style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                  ]),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _chip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AdminTheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AdminTheme.divider),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AdminTheme.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
    ]),
  );
}
  Widget _miniStatBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _globalDistributionBar({
    required int total,
    required int studentsCount,
    required int companiesCount,
    required int academiquesCount,
    required int professionnelsCount,
  }) {
    if (total == 0) return const SizedBox.shrink();

    // Calculate percentages
    final double pctStudents = (studentsCount / total) * 100;
    final double pctCompanies = (companiesCount / total) * 100;
    final double pctAcademiques = (academiquesCount / total) * 100;
    final double pctProfessionnels = (professionnelsCount / total) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        border: Border.all(color: AdminTheme.divider),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 18, color: AdminTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Distribution Globale',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$total utilisateurs',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Custom Segmented Bar Chart
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 16,
              width: double.infinity,
              color: AdminTheme.surface,
              child: Row(
                children: [
                  if (studentsCount > 0)
                    Expanded(
                      flex: studentsCount,
                      child: Container(
                        color: AdminTheme.primary,
                        child: const Tooltip(message: 'Étudiants', child: SizedBox.expand()),
                      ),
                    ),
                  if (companiesCount > 0)
                    Expanded(
                      flex: companiesCount,
                      child: Container(
                        color: AdminTheme.teal,
                        child: const Tooltip(message: 'Entreprises', child: SizedBox.expand()),
                      ),
                    ),
                  if (academiquesCount > 0)
                    Expanded(
                      flex: academiquesCount,
                      child: Container(
                        color: AdminTheme.warning,
                        child: const Tooltip(message: 'Académiques', child: SizedBox.expand()),
                      ),
                    ),
                  if (professionnelsCount > 0)
                    Expanded(
                      flex: professionnelsCount,
                      child: Container(
                        color: AdminTheme.danger,
                        child: const Tooltip(message: 'Professionnels', child: SizedBox.expand()),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 400;
              final List<Widget> legendItems = [
                _legendItem('Étudiants', studentsCount, pctStudents, AdminTheme.primary),
                _legendItem('Entreprises', companiesCount, pctCompanies, AdminTheme.teal),
                _legendItem('Académiques', academiquesCount, pctAcademiques, AdminTheme.warning),
                _legendItem('Professionnels', professionnelsCount, pctProfessionnels, AdminTheme.danger),
              ];

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: legendItems.map((item) => Expanded(child: item)).toList(),
                );
              } else {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: legendItems[0]),
                        Expanded(child: legendItems[1]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: legendItems[2]),
                        Expanded(child: legendItems[3]),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(fontSize: 10, color: AdminTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget usersView() {
    List allUsers = users;

    List students = allUsers.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return role.contains('student') || role.contains('etudiant');
    }).toList();

    List companies = allUsers.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return role.contains('entreprise') || role.contains('company');
    }).toList();

    List academiques = allUsers.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return role.contains('academique');
    }).toList();

    List professionnels = allUsers.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return role.contains('professionnel');
    }).toList();

    final Set<String> deptsSet = {};
    for (var u in allUsers) {
      final dept = u['departement'];
      if (dept != null && dept.toString().trim().isNotEmpty) {
        deptsSet.add(dept.toString().trim());
      }
    }
    final List<String> departments = deptsSet.toList()..sort();
    final int totalUsers = students.length + companies.length + academiques.length + professionnels.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTheme.sectionLabel('Vue d\'ensemble'),
          const SizedBox(height: 10),
          _globalDistributionBar(
            total: totalUsers,
            studentsCount: students.length,
            companiesCount: companies.length,
            academiquesCount: academiques.length,
            professionnelsCount: professionnels.length,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _roleCard2('Étudiants', students, AdminTheme.primary, Icons.school_outlined, totalUsers),
              const SizedBox(width: 10),
              _roleCard2('Entreprises', companies, AdminTheme.teal, Icons.business_outlined, totalUsers),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _roleCard2('Académiques', academiques, AdminTheme.warning, Icons.person_outlined, totalUsers),
              const SizedBox(width: 10),
              _roleCard2('Professionnels', professionnels, AdminTheme.danger, Icons.work_outline, totalUsers),            ],
          ),
          const SizedBox(height: 24),
          AdminTheme.sectionLabel('Répartition par département'),
          const SizedBox(height: 10),
          if (departments.isEmpty)
            AdminTheme.emptyState(
              icon: Icons.apartment_outlined,
              message: 'Aucun département affecté',
              sub: 'Les utilisateurs n\'ont pas encore de département',
            )
          else
            ...departments.map((dept) {
              final deptStudents = students.where((s) => (s['departement'] ?? '').toString().trim() == dept).toList();
              final deptAcademiques = academiques.where((a) => (a['departement'] ?? '').toString().trim() == dept).toList();
              final int deptTotal = deptStudents.length + deptAcademiques.length;
              final String deptFormatted = dept.isNotEmpty
                  ? '${dept[0].toUpperCase()}${dept.substring(1)}'
                  : 'Département';

              return Container(
                key: ValueKey(dept),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AdminTheme.cardBg,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
                  border: Border.all(color: AdminTheme.divider),
                  boxShadow: AdminTheme.cardShadow,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: AdminTheme.iconContainer(Icons.apartment_outlined, color: AdminTheme.primary),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            deptFormatted,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminTheme.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AdminTheme.primary.withOpacity(0.15)),
                          ),
                          child: Text(
                            '$deptTotal membre${deptTotal > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AdminTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _miniStatBadge(Icons.assignment_ind_outlined, '${deptAcademiques.length} encadrant(s)', AdminTheme.warning),
                            const SizedBox(width: 8),
                            _miniStatBadge(Icons.school_outlined, '${deptStudents.length} étudiant(s)', AdminTheme.primary),
                          ],
                        ),
                        if (deptTotal > 0) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Container(
                              height: 6,
                              width: double.infinity,
                              color: AdminTheme.surface,
                              child: Row(
                                children: [
                                  if (deptStudents.isNotEmpty)
                                    Expanded(
                                      flex: deptStudents.length,
                                      child: Container(color: AdminTheme.primary),
                                    ),
                                  if (deptAcademiques.isNotEmpty)
                                    Expanded(
                                      flex: deptAcademiques.length,
                                      child: Container(color: AdminTheme.warning),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AdminTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Étudiants (${(deptStudents.length / deptTotal * 100).toStringAsFixed(0)}%)',
                                    style: const TextStyle(fontSize: 9, color: AdminTheme.textSecondary),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AdminTheme.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Encadrants (${(deptAcademiques.length / deptTotal * 100).toStringAsFixed(0)}%)',
                                    style: const TextStyle(fontSize: 9, color: AdminTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'Aucun membre affecté',
                            style: TextStyle(
                              fontSize: 11,
                              color: AdminTheme.textSecondary.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      const Divider(height: 1, color: AdminTheme.divider),
                      const SizedBox(height: 12),
                      _deptSectionHeader('Encadrants académiques', Icons.assignment_ind_outlined, AdminTheme.warning),
                      const SizedBox(height: 6),
                      if (deptAcademiques.isEmpty)
                        _emptyDeptText('Aucun encadrant dans ce département')
                      else
                        ...deptAcademiques.map((a) => _deptUserRow(
                          name: '${a['prenom'] ?? ''} ${a['name'] ?? ''}'.trim(),
                          email: a['email'] ?? '',
                          sub: a['specialite']?.toString().isNotEmpty == true ? 'Spécialité : ${a['specialite']}' : 'Pas de spécialité',
                          icon: Icons.person_outline,
                          color: AdminTheme.warning,
                        )),
                      const SizedBox(height: 12),
                      _deptSectionHeader('Étudiants', Icons.school_outlined, AdminTheme.primary),
                      const SizedBox(height: 6),
                      if (deptStudents.isEmpty)
                        _emptyDeptText('Aucun étudiant dans ce département')
                      else
                        ...deptStudents.map((s) {
                          final level = s['niveau']?.toString() ?? '';
                          final spec = s['specialite']?.toString() ?? '';
                          final sub = [level, spec].where((e) => e.isNotEmpty).join(' · ');
                          return _deptUserRow(
                            name: '${s['prenom'] ?? ''} ${s['name'] ?? ''}'.trim(),
                            email: s['email'] ?? '',
                            sub: sub.isNotEmpty ? sub : 'Pas de niveau/spécialité',
                            icon: Icons.school_outlined,
                            color: AdminTheme.primary,
                          );
                        }),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _roleCard2(String title, List list, Color color, IconData icon, int totalUsers) {
    Widget? dest;
    if (title == 'Étudiants') dest = const EtudiantsPage();
    if (title == 'Entreprises') dest = const EntreprisesPage();
    if (title == 'Académiques') dest = const AcademiquesPage();
    if (title == 'Professionnels') dest = const EncadrantsProPage();

    final double ratio = totalUsers > 0 ? (list.length / totalUsers) : 0.0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (dest != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => dest!)).then((_) => loadData());
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UsersListPage(title: title, users: list)));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdminTheme.cardBg,
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            border: Border.all(color: AdminTheme.divider),
            boxShadow: AdminTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AdminTheme.iconContainer(icon, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${list.length}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                        ),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AdminTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: color.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(ratio * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    'du total',
                    style: TextStyle(fontSize: 9, color: AdminTheme.textSecondary.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deptSectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
    ]);
  }

  Widget _emptyDeptText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(text, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
    );
  }

  Widget _deptUserRow({
    required String name,
    required String email,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    final String initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'U';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.08),
            child: Text(
              initials,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 11, color: AdminTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(icon, size: 11, color: color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sub,
                          style: TextStyle(fontSize: 10, color: color.withOpacity(0.85), fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
Widget roleSection(String title, List list, Color color, IconData icon) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          "$title (${list.length})",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      if (list.isEmpty)
        const Padding(
          padding: EdgeInsets.all(10),
          child: Text("No users found"),
        ),

      ...list.map((u) {
       
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            title: Text(u['name'] ?? "No name"),
            subtitle: Text(u['email'] ?? "No email"),
            trailing: Text(
            (u['role'] ?? '').toString(),
              style: TextStyle(color: color),
            ),
          ),
        );
      }).toList(),
    ],
  );
} 

  // ================= COMPANIES =================
Widget home() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Quick Actions ──
        AdminTheme.sectionLabel('Actions rapides'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _quickAction2('Stages', Icons.school_outlined, () => setState(() => index = 2)),
            _quickAction2('Candidats', Icons.people_outline, () => setState(() => index = 1)),
            _quickAction2('Entreprises', Icons.business_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCompanyPage())).then((_) => loadData())),
            _quickAction2('Encadrement', Icons.assignment_ind_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => EncadrementPage()))),
            _quickAction2('+ Étudiant', Icons.person_add_outlined, _showAddStudentDialog, accent: AdminTheme.accent),
            _quickAction2('+ Encadrant', Icons.person_add_alt_1_outlined, _showAddAcademiqueDialog, accent: const Color(0xFF0D9488)),
            _quickAction2('Enc. Pro', Icons.work_outline_rounded,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EncadrantsProPage())).then((_) => loadData()),
              accent: const Color(0xFF0891B2)),
            _quickAction2('Spécialités', Icons.book_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialitesPage()))),
            _quickAction2('Départements', Icons.apartment_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartementsPage()))),          ],
        ),
      ],
    ),
  );
}

Widget _quickAction2(String title, IconData icon, VoidCallback onTap, {Color? accent}) {
  final color = accent ?? AdminTheme.primary;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.divider),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary), overflow: TextOverflow.ellipsis)),
          Icon(Icons.chevron_right, size: 14, color: AdminTheme.textSecondary),
        ],
      ),
    ),
  );
}
 Widget encadrementView() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Encadrement",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Column(
            children: [

              // HEADER TABLE
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.blue.shade50,
                child: const Row(
                  children: [
                    Expanded(child: Text("Année", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text("Encadrant", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text("Niveau", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text("Spécialité", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text("Étudiant", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),

              // DATA ROWS
              ...students.map((s) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),

                  child: Row(
                    children: [

                      Expanded(child: Text(s['annee'] ?? "-")),

                      Expanded(child: Text(s['encadrant'] ?? "-")),

                      Expanded(child: Text(s['niveau'] ?? "-")),

                      Expanded(child: Text(s['specialite'] ?? "-")),

                      Expanded(child: Text(s['name'] ?? "-")),
                    ],
                  ),
                );
              }).toList(),

            ],
          ),
        ),
      ],
    ),
  );
}
Widget quickAction(String title, IconData icon, VoidCallback onTap, {Color? color}) {
  final themeColor = color ?? AdminTheme.primary;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: themeColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    ),
  );
}

Widget _kpiCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget homeCard(String title, IconData icon, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8), //  padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), 
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color), //
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11, // 
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
  // ================= BODY =================
  Widget body() {
    switch (index) {
      case 0:
        return home();
      case 1:
        return usersView();
      case 2:
  return stagesView();
   case 3:
      return demandesView(); 
    case 4:
  return students.isEmpty
      ? const Center(child: CircularProgressIndicator())
      : encadrementView();
      default:
        return home();
    }
  }
Widget demandesView() {
  if (demandes.isEmpty) {
    return AdminTheme.emptyState(
      icon: Icons.assignment_outlined,
      message: 'Aucune demande',
      sub: 'Les demandes de stage apparaîtront ici',
    );
  }
  return RefreshIndicator(
    onRefresh: loadDemandes,
    color: AdminTheme.primary,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: demandes.length,
      itemBuilder: (context, index) => demandeCard(demandes[index], index),
    ),
  );
}
Widget demandeCard(dynamic d, int index) {
  final status = d['status'] ?? 'pending';
  Color statusColor = status == 'accepted' ? AdminTheme.success
      : status == 'rejected' ? AdminTheme.danger
      : AdminTheme.warning;
  String statusLabel = status == 'accepted' ? 'Accepté'
      : status == 'rejected' ? 'Refusé'
      : 'En attente';

  return GestureDetector(
    onTap: () => showDemandeDetails(d),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        border: Border.all(color: AdminTheme.divider),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AdminTheme.primary.withOpacity(0.1),
              child: Text('${index + 1}', style: const TextStyle(color: AdminTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['titre'] ?? 'Demande', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(d['entreprise'] ?? '', style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                ],
              ),
            ),
            AdminTheme.statusBadge(statusLabel, color: statusColor),
          ],
        ),
      ),
    ),
  );
}
  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Tableau de bord',
        subtitle: 'Espace administrateur',
        showBack: false,
        height: 66,
        actions: [
          AdminTheme.appBarAction(
            icon: Icons.archive_outlined,
            tooltip: 'Acteurs Archivés',
            onPressed: () {
              Navigator.pushNamed(context, '/admin-archives').then((_) => loadData());
            },
          ),
          AdminTheme.appBarAction(
            icon: Icons.logout_rounded,
            tooltip: 'Déconnexion',
            onPressed: logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : body(),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AdminTheme.divider)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) {
            setState(() => index = i);
            if (i == 2) loadStages();
          },
          selectedItemColor: AdminTheme.primary,
          unselectedItemColor: AdminTheme.textSecondary,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people_rounded), label: 'Utilisateurs'),
            BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school_rounded), label: 'Stages'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment_rounded), label: 'Demandes'),
          ],
        ),
      ),
    );
  }

  
}
class UsersListPage extends StatelessWidget {
  final String title;
  final List users;

  const UsersListPage({super.key, required this.title, required this.users});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: title,
        subtitle: '${users.length} utilisateur${users.length != 1 ? 's' : ''}',
        showBack: true,
        context: context,
      ),
      body: users.isEmpty
          ? AdminTheme.emptyState(icon: Icons.people_outline, message: 'Aucun utilisateur')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                final name = '${u['prenom'] ?? ''} ${u['name'] ?? ''}'.trim();
                final role = (u['role'] ?? '').toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AdminTheme.cardBg,
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    border: Border.all(color: AdminTheme.divider),
                    boxShadow: AdminTheme.cardShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AdminTheme.primary.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AdminTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name.isNotEmpty ? name : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminTheme.textPrimary)),
                    subtitle: Text(u['email'] ?? '', style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                    trailing: AdminTheme.statusBadge(role),
                  ),
                );
              },
            ),
    );
  }
}
