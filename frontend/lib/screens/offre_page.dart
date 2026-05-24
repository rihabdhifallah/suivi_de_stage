import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../services/api_service.dart';

class OffresPage extends StatefulWidget {
  const OffresPage({super.key});

  @override
  State<OffresPage> createState() => _OffresPageState();
}

class _OffresPageState extends State<OffresPage> {
  final _formKey = GlobalKey<FormState>();
Map<int, dynamic> encadrantsByOffre = {};
String? companyId;
List encadrants = [];
String? selectedEncadrant;

int? selectedEncadrantId;
String? selectedEncadrantName;
  final storage = const FlutterSecureStorage();

  final titreController = TextEditingController();
  final skillsController = TextEditingController();
  final departementController = TextEditingController();

  final dureeController = TextEditingController();
  final cityController = TextEditingController();

  final dateDebutController = TextEditingController();
  final dateFinController = TextEditingController();

  String selectedNiveau = "3 eme licence";
  final List<String> niveaux = ["3 eme licence", "2 master professionnel", "2eme master de recherche"];
  int placesCount = 1;

  // Nouveaux champs
  String typeStage = "Présentiel";
  final remunerationController = TextEditingController();

  bool loading = false;
int? createdOffreId;

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
    );
  }
Future<void> loadEncadrants() async {
  final companyId = await storage.read(key: "userId");
  print("loadEncadrants - COMPANY ID FROM SECURE STORAGE => $companyId");

  if (companyId != null) {
    try {
      final data = await ApiService().getEncadrantsByCompany(companyId);
      setState(() {
        encadrants = data;
      });
      return;
    } catch (e) {
      print("Error fetching encadrants by company ID: $e");
    }
  }

  // Fallback to getProfile if secure storage is empty or fails
  try {
    final profile = await ApiService().getProfile();
    print("PROFILE => $profile");
    final profileCompanyId = profile['id'] ?? profile['companyId']; 
    print("COMPANY ID FROM PROFILE => $profileCompanyId");

    if (profileCompanyId != null) {
      final data = await ApiService().getEncadrantsByCompany(profileCompanyId.toString());
      setState(() {
        encadrants = data;
      });
    }
  } catch (e) {
    print("Error loading profile fallback: $e");
  }
}

  Future<void> submit() async {
  if (!_formKey.currentState!.validate()) return;

  if (selectedEncadrantId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Choisir un encadrant")),
    );
    return;
  }

  final email = await storage.read(key: "email");
  String? companyName = await storage.read(key: "name");
  if (companyName == null || companyName.isEmpty) {
    try {
      final profile = await ApiService().getProfile();
      companyName = profile['name'];
    } catch (e) {
      print("Error loading profile for name fallback: $e");
    }
  }

  final data = {
    "titre": titreController.text,
    "domaine": departementController.text,
    "duree": dureeController.text,
    "niveau": selectedNiveau,
    "places": placesCount,
    "city": cityController.text,
    "dateDebut": dateDebutController.text,
    "dateFin": dateFinController.text,
    "skills": skillsController.text.split(",").map((e) => e.trim()).toList(),
    "companyEmail": email,
    "companyName": companyName ?? '',
    "typeStage": typeStage,
    if (remunerationController.text.trim().isNotEmpty)
      "remuneration": remunerationController.text.trim(),
  };

  try {
    setState(() => loading = true);

    final response = await ApiService().createOffre(data);

    print("RESPONSE => $response");

    createdOffreId = response["id"];

    if (createdOffreId != null) {
      await ApiService().inviteEncadrant(
        selectedEncadrantId!,
        createdOffreId!,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Offre créée avec succès")),
    );

    clearFields();
  } catch (e) {
    print("ERROR => $e");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur création offre")),
    );
  } finally {
    setState(() => loading = false);
  }
}

  void clearFields() {
    titreController.clear();
    skillsController.clear();
    departementController.clear();
    dureeController.clear();
    cityController.clear();
    dateDebutController.clear();
    dateFinController.clear();
    remunerationController.clear();
    setState(() {
      selectedNiveau = "3 eme licence";
      placesCount = 1;
      typeStage = "Présentiel";
    });
  }


  Future pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }@override
void initState() {
  super.initState();
  loadEncadrants();
}

  Widget sectionTitle(
    IconData icon,
    String title,
    Color color,
  ) {
    return Row(
      children: [

        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _typeStageBtn(String label, IconData icon) {
    final selected = typeStage == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => typeStage = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF002366) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF002366) : Colors.grey.shade300,
              width: 1.5),
            boxShadow: selected ? [
              BoxShadow(
                color: const Color(0xFF002366).withOpacity(0.25),
                blurRadius: 10, offset: const Offset(0, 4))
            ] : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  //
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002366),

        title: const Text(
          "Créer une offre de stage",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(

              padding: const EdgeInsets.all(16),

              child: Form(
                key: _formKey,

                child: Column(
                  children: [


                    Container(
                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          sectionTitle(
                            Icons.work_outline,
                            "Informations du poste",
                            Colors.blue,
                          ),

                          const SizedBox(height: 25),

                          label("Titre du stage"),

                          TextFormField(
                            controller: titreController,
                            decoration:
                                inputStyle("Entrer le titre"),
                            validator: (v) =>
                                v!.isEmpty
                                    ? "Champ obligatoire"
                                    : null,
                          ),

                          const SizedBox(height: 20),

                          label("Compétences requises"),

                          TextFormField(
                            controller: skillsController,
                            maxLines: 3,
                            decoration: inputStyle(
                              "Flutter, NodeJS, SQL...",
                            ),
                            validator: (v) =>
                                v!.isEmpty
                                    ? "Champ obligatoire"
                                    : null,
                          ),

                          const SizedBox(height: 20),

                          label("Département"),

                          TextFormField(
                            controller: departementController,
                            decoration:
                                inputStyle("Informatique"),
                            validator: (v) =>
                                v!.isEmpty
                                    ? "Champ obligatoire"
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),


                    Container(
                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          sectionTitle(
                            Icons.event_note,
                            "Détails pratiques",
                            Colors.orange,
                          ),

                          const SizedBox(height: 25),

                          label("Durée du stage"),

                          Row(
                            children: [

                              Expanded(
                                child: TextFormField(
                                  controller:
                                      dureeController,
                                  decoration: inputStyle(
                                    "6 mois",
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty
                                          ? "Champ obligatoire"
                                          : null,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: TextFormField(
                                  controller:
                                      cityController,
                                  decoration:
                                      inputStyle(
                                    "Lieu",
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty
                                          ? "Champ obligatoire"
                                          : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          label("Date"),

                          Row(
                            children: [

                              Expanded(
                                child: TextFormField(
                                  controller:
                                      dateDebutController,
                                  readOnly: true,
                                  decoration:
                                      inputStyle(
                                    "Début",
                                  ),
                                  onTap: () =>
                                      pickDate(
                                        dateDebutController,
                                      ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: TextFormField(
                                  controller:
                                      dateFinController,
                                  readOnly: true,
                                  decoration:
                                      inputStyle(
                                    "Fin",
                                  ),
                                  onTap: () =>
                                      pickDate(
                                        dateFinController,
                                      ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          label("Niveau & Nombre de places"),

                          Row(
                            children: [

                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: selectedNiveau,
                                  decoration: inputStyle("Niveau"),
                                  items: niveaux.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                                  onChanged: (v) => setState(() => selectedNiveau = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFFD6B38A)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () => setState(() { if (placesCount > 1) placesCount--; }),
                                        child: const Icon(Icons.remove, size: 20, color: Color(0xFF002366)),
                                      ),
                                      Text(placesCount.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      InkWell(
                                        onTap: () => setState(() { placesCount++; }),
                                        child: const Icon(Icons.add, size: 20, color: Color(0xFF002366)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── TYPE DE STAGE ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(Icons.laptop_mac_outlined, "Type de stage", Colors.indigo),
                          const SizedBox(height: 20),
                          Row(children: [
                            _typeStageBtn("Présentiel", Icons.business_rounded),
                            const SizedBox(width: 12),
                            _typeStageBtn("En ligne", Icons.laptop_rounded),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── RÉMUNÉRATION ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(Icons.payments_outlined, "Rémunération", Colors.green),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Text("Optionnel",
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ]),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: remunerationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Ex: 300",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              suffixText: "DT / mois",
                              suffixStyle: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 10),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Encadrant professionnel",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
         child: Text(
  selectedEncadrantName ?? "Aucun encadrant sélectionné",
),
      ),

      const SizedBox(height: 15),

      DropdownButtonFormField<int>(
  value: selectedEncadrantId,
  decoration: InputDecoration(
    hintText: "Choisir un encadrant",
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  ),
  items: encadrants.map<DropdownMenuItem<int>>((e) {
  return DropdownMenuItem<int>(
    value: e["id"],
    child: Text(e["nomComplet"] ?? "No name"),
  );
}).toList(),
  onChanged: (value) {
    setState(() {
      selectedEncadrantId = value;
      selectedEncadrantName = encadrants
          .firstWhere((e) => e["id"] == value)["nomComplet"];
    });
  },
)
    ],
  ),
),

                    const SizedBox(height: 40),

                    Row(
                      children: [

                        Expanded(
                          child: OutlinedButton(

                            style:
                                OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                              ),
                            ),

                            onPressed: () {

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Brouillon sauvegardé",
                                  ),
                                ),
                              );
                            },

                            child: const Text(
                              "Sauvegarder brouillon",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: ElevatedButton(

                            style:
                                ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                                  const Color(0xFF002366),

                              foregroundColor:
                                  Colors.white,

                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                              ),
                            ),

                            onPressed: () async {
                              await submit();
                            },

                            child: const Text(
                              "Envoyer",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}