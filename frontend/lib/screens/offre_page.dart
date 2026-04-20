

import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OffresPage extends StatefulWidget {
  const OffresPage({super.key});

  @override
  State<OffresPage> createState() => _OffresPageState();
}
class _OffresPageState extends State<OffresPage> {
    List<Map<String, dynamic>> offres = [];
  int? editingId;
  final _formKey = GlobalKey<FormState>();
final storage = const FlutterSecureStorage();
  final titreController = TextEditingController();
  final domaineController = TextEditingController();
  final dureeController = TextEditingController();
  final niveauController = TextEditingController();
  final placesController = TextEditingController(text: "0");

  List allOffres = [];
  
Future<void> submit() async {
  if (!_formKey.currentState!.validate()) return;

  final email = await storage.read(key: "email");

  final data = {
    "titre": titreController.text,
    "domaine": domaineController.text,
    "duree": dureeController.text,
    "niveau": niveauController.text,
    "places": int.parse(placesController.text),
    "companyEmail": email,
  };

  if (editingId == null) {
  await ApiService().createOffre(data);
} else {
  await ApiService().updateOffre(editingId!, data);
  editingId = null;
}

  await loadOffres();

  titreController.clear();
  domaineController.clear();
  dureeController.clear();
  niveauController.clear();
  placesController.text = "0";
}
  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
 
Future loadOffres() async {
  final email = await storage.read(key: "email");

  final data = await ApiService().getOffres(email!);

  setState(() {
    offres = List.from(data); 
  });
}
void editOffre(Map o) {
  editingId = o['id']; // 

  titreController.text = o['titre'];
  domaineController.text = o['domaine'];
  dureeController.text = o['duree'];
  niveauController.text = o['niveau'];
  placesController.text = o['places'].toString();


  Scrollable.ensureVisible(context);

}
@override
void initState() {
  super.initState();
  loadOffres();
}
  @override
  Widget build(BuildContext context) {
   final activeOffres = offres
      .where((o) => o['active'] == true)
      .toList();

    return Scaffold(

      appBar: AppBar(
        backgroundColor: const Color(0xFF002366),
        title: const Text(
          "Offres",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== CARDS =====
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  statCard("Offres", Icons.work),
                  statCard("Candidats", Icons.people),
                  statCard("Stagiaires", Icons.school),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ===== FORM =====
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    const Text(
                      "Nouvelle Offre",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // TITRE
                    TextFormField(
                      controller: titreController,
                      style: const TextStyle(fontSize: 13),
                      decoration: inputStyle("Titre"),
                      validator: (v) => v!.isEmpty ? "Champ obligatoire" : null,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: domaineController,
                            style: const TextStyle(fontSize: 13),
                            decoration: inputStyle("Domaine"),
                            validator: (v) => v!.isEmpty ? "Champ obligatoire" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: dureeController,
                            style: const TextStyle(fontSize: 13),
                            decoration: inputStyle("Durée"),
                            validator: (v) => v!.isEmpty ? "Champ obligatoire" : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // NIVEAU + PLACES
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: niveauController,
                            style: const TextStyle(fontSize: 13),
                            decoration: inputStyle("Niveau"),
                            validator: (v) => v!.isEmpty ? "Champ obligatoire" : null,
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [

                                // MINUS CHIP
                                ActionChip(
                                  label: const Text("-"),
                                  onPressed: () {
                                    int val = int.tryParse(placesController.text) ?? 0;
                                    if (val > 0) val--;
                                    setState(() {
                                      placesController.text = val.toString();
                                    });
                                  },
                                ),

                                Expanded(
                                  child: TextField(
                                    controller: placesController,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),

                                // PLUS CHIP
                                ActionChip(
                                  label: const Text("+"),
                                  onPressed: () {
                                    int val = int.tryParse(placesController.text) ?? 0;
                                    val++;
                                    setState(() {
                                      placesController.text = val.toString();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: submit,
                        
                        child: const Text(
                          "Publier offre",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== LIST =====
            const Text(
              "Mes offres",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (offres.isEmpty)
              const Text("Aucune offre pour le moment"),
...offres.map((o) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 5),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ===== TOP =====
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // 🔵 TITRE
            Expanded(
              child: Text(
                o['titre'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002366),
                ),
              ),
            ),

            // 🔁 SWITCH ACTIVE
            Switch(
              value: o['active'] ?? true,
             onChanged: (val) async {
  setState(() {
    o['active'] = val;
  });

  await ApiService().updateStatus(o['id'], val);
},

              
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ===== INFOS (RIGHT SIDE) =====
       Row(
  children: [

    // LEFT SIDE
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Domaine: ${o['domaine']}"),
          Text("Durée: ${o['duree']}"),
          Text("Niveau: ${o['niveau']}"),
          Text("Places: ${o['places']}"),
        ],
      ),
    ),

    const SizedBox(width: 20),

    // RIGHT SIDE (status text)
    Text(
      o['active'] == true ? "Active" : "Inactive",
      style: TextStyle(
        color: o['active'] == true ? Colors.green : Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),
        const  SizedBox(height: 10),

        // ===== BUTTON =====
Row(
  children: [

    Expanded(
      child: OutlinedButton(
        onPressed: () {
          editOffre(o);
        },
        child: const Text("Modifier"),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/candidats',
            arguments: o['id'],
          );
        },
        child: const Text("Voir Candidats"),
      ),
    ),
  ],
)
      ],
    ),
  );
}).toList(),
          ],
        ),
      ),
    );
  }

  // ===== CARD =====
  Widget statCard(String title, IconData icon) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF002366), size: 18),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}