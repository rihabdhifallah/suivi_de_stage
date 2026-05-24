import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;

class DemandeStagePage extends StatefulWidget {
  const DemandeStagePage({super.key});

  @override
  State<DemandeStagePage> createState() => _DemandeStagePageState();
}

class _DemandeStagePageState extends State<DemandeStagePage> {
  int step = 1;
final api = ApiService();

  // ================= STEP 1 =================
  final specialiteController = TextEditingController();
  final dureeController = TextEditingController();
  final dateController = TextEditingController();

  // ================= ENTREPRISE =================
  final entrepriseController = TextEditingController();
  final secteurController = TextEditingController();
  final adresseController = TextEditingController();
  final telController = TextEditingController();
  final emailController = TextEditingController();

  // ================= ENCADRANT =================
  final encadrantNomController = TextEditingController();
  final posteController = TextEditingController();
  final telEncadrantController = TextEditingController();
  final emailEncadrantController = TextEditingController();

  // ================= STEP 3 =================
  final titlePosteController = TextEditingController();
  final missionController = TextEditingController();
  final skillsController = TextEditingController();
  final remunerationController = TextEditingController();
  final noteController = TextEditingController();

  String foundVia = "";
DateTime? startDate;
DateTime? endDate;
PlatformFile? cvFile;
PlatformFile? lettreFile;
  // ================= VALIDATION =================
  bool step1Valid() =>
      specialiteController.text.isNotEmpty &&
      dureeController.text.isNotEmpty &&
      dateController.text.isNotEmpty;

  bool step2Valid() =>
      entrepriseController.text.isNotEmpty &&
      secteurController.text.isNotEmpty &&
      adresseController.text.isNotEmpty &&
      telController.text.isNotEmpty &&
      emailController.text.isNotEmpty &&
      encadrantNomController.text.isNotEmpty &&
      posteController.text.isNotEmpty &&
      telEncadrantController.text.isNotEmpty &&
      emailEncadrantController.text.isNotEmpty;

 bool step3Valid() =>
    titlePosteController.text.isNotEmpty &&
    missionController.text.isNotEmpty &&
    skillsController.text.isNotEmpty &&
    startDate != null &&
    endDate != null;
    bool step4Valid() => cvFile != null && lettreFile != null;

 Future<void> pickFile(bool isCv) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (isCv) {
          cvFile = result.files.first;
        } else {
          lettreFile = result.files.first;
        }
      });

      print("FILE: ${result.files.first.name}");
    }
  } catch (e) {
    print("ERROR: $e");
  }
}

  Widget stepBar() {
    return Row(
      children: List.generate(4, (index) {
        bool active = step > index;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF0A1F44) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        title: const Text("Demande de stage"),
      ),

      body: Column(
        children: [
          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: stepBar(),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: step == 1
                ? step1()
                : step == 2
                    ? step2()
                    : step == 3
                        ? step3()
                        : step4(),
          ),
        ],
      ),
    );
  }

  // ================= STEP 1 =================
 Widget step1() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [

        _box("Spécialité", specialiteController),
        _box("Durée (mois)", dureeController),

        const SizedBox(height: 10),

        // 📅 DATE WITH ICON (FIXED)
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (picked != null) {
              dateController.text =
                  "${picked.day}/${picked.month}/${picked.year}";
              setState(() {});
            }
          },
          child: AbsorbPointer(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: "Date prévue",
                  prefixIcon: const Icon(Icons.calendar_today), // 
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: step1Valid()
              ? () => setState(() => step = 2)
              : null,
          child: const Text("Continuer"),
        )
      ],
    ),
  );
}
  // ================= STEP 2 (FIXED DESIGN REQUEST) =================
  Widget step2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          // ================= ENTREPRISE BLOCK =================
          sectionBlock(
            title: "Informations entreprise",
            children: [
              _box("Nom entreprise", entrepriseController),
              _box("Secteur d'activité", secteurController),
              _box("Adresse", adresseController),

              Row(
                children: [
                  Expanded(child: _box("Téléphone", telController)),
                  const SizedBox(width: 10),
                  Expanded(child: _box("Email", emailController)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ================= ENCADRANT BLOCK =================
          sectionBlock(
            title: "Informations encadrant",
            children: [
              _box("Nom encadrant", encadrantNomController),
              _box("Poste", posteController),

              Row(
                children: [
                  Expanded(child: _box("Téléphone encadrant", telEncadrantController)),
                  const SizedBox(width: 10),
                  Expanded(child: _box("Email encadrant", emailEncadrantController)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => step = 1),
                  child: const Text("Retour"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: step2Valid()
                      ? () => setState(() => step = 3)
                      : null,
                  child: const Text("Continuer"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= STEP 3 =================
Widget step3() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "3/4 Détails du stage",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        // ================= INTITULÉ =================
        _box("Intitulé du poste", titlePosteController),

        const SizedBox(height: 15),

        // ================= MISSION =================
        const Text(
          "Description de la mission",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: missionController,
                maxLines: 5,
                onChanged: (v) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  "${missionController.text.length} / 600",
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 15),

        // ================= SKILLS =================
        const Text(
          "Compétences mises en œuvre",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        _box("Séparez les technologies par des virgules", skillsController),

        const SizedBox(height: 15),

        // ================= DATES =================
        Row(
          children: [
            dateBox(
              "Date début",
              startDate,
              () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );

                if (picked != null) {
                  setState(() => startDate = picked);
                }
              },
            ),

            const SizedBox(width: 10),

            dateBox(
              "Date fin",
              endDate,
              () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );

                if (picked != null) {
                  setState(() => endDate = picked);
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 15),

        // ================= REMUNERATION =================
        _box(
          "Rémunération (TND / mois - 0 si non rémunéré)",
          remunerationController,
        ),

        const SizedBox(height: 15),

        // ================= FOUND VIA =================
        const Text(
          "Comment avez-vous trouvé ce stage ?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

       Column(
  children: [
    foundCard("LinkedIn", Icons.work),
    foundCard("Site web", Icons.language),
    foundCard("Recommandation amis", Icons.people),
    foundCard("Salon emploi", Icons.event),
    foundCard("Autre", Icons.more_horiz),
    foundCard("Candidature spontanée", Icons.send),
  ],
),

        const SizedBox(height: 15),

        // ================= NOTE =================
        _box("Note supplémentaire (optionnel)", noteController),

        const SizedBox(height: 25),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => step = 2),
                child: const Text("Retour"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: step3Valid()
                    ? () => setState(() => step = 4)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                ),
                child: const Text("Continuer"),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget foundCard(String value, IconData icon) {
  bool selected = foundVia == value;

  return GestureDetector(
    onTap: () {
      setState(() {
        foundVia = value;
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0A1F44) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF0A1F44) : Colors.grey.shade300,
        ),
        boxShadow: [
          if (selected)
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
            )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.grey),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
  // ================= STEP 4 (DOCUMENTS) =================
Widget step4() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [

        const Text(
          "Étape 4/4 - Documents",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        docCard(
          title: "Lettre d'acceptation",
          desc: "PDF obligatoire",
          file: lettreFile,
          onTap: () => pickFile(false),
        ),

        const SizedBox(height: 15),

        docCard(
          title: "CV",
          desc: "PDF obligatoire",
          file: cvFile,
          onTap: () => pickFile(true),
        ),

        const SizedBox(height: 25),

ElevatedButton(
  onPressed: step4Valid()
      ? () async {
          try {
           await api.createDemande(
  studentId: 1,
  titre: titlePosteController.text,
  mission: missionController.text,
  specialite: specialiteController.text,
  duree: dureeController.text,
  date: dateController.text,

  entreprise: entrepriseController.text,
  secteur: secteurController.text,
  adresse: adresseController.text,
  tel: telController.text,
  email: emailController.text,

  encadrant: encadrantNomController.text,
  poste: posteController.text,
  telEncadrant: telEncadrantController.text,
  emailEncadrant: emailEncadrantController.text,

  skills: skillsController.text,
  startDate: startDate.toString(),
  endDate: endDate.toString(),
  foundVia: foundVia,

  cvBytes: cvFile!.bytes!,
  cvName: cvFile!.name,
  lettreBytes: lettreFile!.bytes!,
  lettreName: lettreFile!.name,
);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Demande envoyée ")),
            );

            setState(() => step = 1); // reset
          } catch (e) {
            print(e);
          }
        }
      : null,
  child: const Text("Envoyer"),
),
      ],
    ),
  );
}

  // ================= SECTION BLOCK (NEW DESIGN REQUEST) =================
  Widget sectionBlock({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1F44),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  // ================= DOC CARD =================
Widget docCard({
  required String title,
  required String desc,
  required VoidCallback onTap,
  PlatformFile? file,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(desc),

          const SizedBox(height: 10),

          if (file != null)
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(file.name)),
              ],
            )
          else
            const Text("Clique pour choisir PDF"),
        ],
      ),
    ),
  );
}
  // ================= INPUT =================
  Widget _box(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  Widget choice(String value) {
  bool selected = foundVia == value;

  return GestureDetector(
    onTap: () => setState(() => foundVia = value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0A1F44) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    ),
  );
}
Widget dateBox(String label, DateTime? date, VoidCallback onTap) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 10),
            Text(
              date == null
                  ? label
                  : "${date.day}/${date.month}/${date.year}",
            ),
          ],
        ),
      ),
    ),
  );
}
}