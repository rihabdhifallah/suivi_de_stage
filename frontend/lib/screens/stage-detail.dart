import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class StageDetail extends StatefulWidget {
  const StageDetail({super.key});

  @override
  State<StageDetail> createState() => _StageDetailState();
}
 class _StageDetailState extends State<StageDetail> {
  final ApiService api = ApiService();

  List saved = [];

  @override
  Widget build(BuildContext context) {
    final stage = ModalRoute.of(context)!.settings.arguments as Map;
    final String companyName = (stage["companyName"] ?? stage["companyEmail"] ?? "Entreprise").toString();
    final String companyInitial = companyName.isNotEmpty ? companyName.substring(0, 2).toUpperCase() : "CO";
    final List<dynamic> skills = stage["skills"] ?? stage["competence"] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        elevation: 0,
        title: const Text("Détail du stage", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0A1F44),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage["titre"] ?? "Offre de stage",
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.domain, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              stage["domaine"] ?? "Domaine",
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              stage["city"] ?? "Ville",
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Overlapping Content
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFE3EAF2),
                          child: Text(
                            companyInitial,
                            style: const TextStyle(
                              color: Color(0xFF0A1F44),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          companyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          stage["companyEmail"] ?? "",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        trailing: const Icon(Icons.business_center, color: Colors.grey),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Info Grid
                    Row(
                      children: [
                        Expanded(child: _smallCard("Durée", stage["duree"] ?? "-", Icons.timer, Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _smallCard("Date", "${stage['dateDebut'] ?? ''}\n${stage['dateFin'] ?? ''}", Icons.calendar_today, Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _smallCard("Niveau", stage["niveau"] ?? "-", Icons.school, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _smallCard("Places", "${stage["places"] ?? "1"}", Icons.people, Colors.purple)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _smallCard(
                          "Type de stage",
                          stage["typeStage"] ?? "Présentiel",
                          (stage["typeStage"] ?? "Présentiel") == "En ligne"
                              ? Icons.laptop_rounded
                              : Icons.business_rounded,
                          Colors.indigo,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _smallCard(
                          "Rémunération",
                          (stage["remuneration"] != null && stage["remuneration"].toString().isNotEmpty)
                              ? "${stage["remuneration"]} DT/mois"
                              : "Non rémunéré",
                          Icons.payments_outlined,
                          (stage["remuneration"] != null && stage["remuneration"].toString().isNotEmpty)
                              ? Colors.green
                              : Colors.grey,
                        )),
                      ],
                    ),
                    
                    const SizedBox(height: 25),
                    
                    const Text(
                      "Compétences Requises",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    skills.isEmpty || (skills.length == 1 && skills[0].toString().trim().isEmpty)
                        ? const Text("Aucune compétence spécifique requise.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.map((s) => Chip(
                              label: Text(s.toString().trim(), style: const TextStyle(color: Color(0xFF0A1F44), fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFFE3EAF2),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            )).toList(),
                          ),
                          
                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A1F44),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
                            ),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                final check = await api.checkPlaces(stage["id"]);
                                
                                if (!context.mounted) return;
                                Navigator.pop(context); // close loader dialog

                                if (check["isFull"] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Le nombre maximal de places pour cette offre a été atteint."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  Navigator.pushNamed(context, '/apply-stage', arguments: stage);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context); // close loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Erreur de connexion")),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Postuler Maintenant",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (saved.contains(stage)) saved.remove(stage);
                              else saved.add(stage);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved.contains(stage) ? "Stage enregistré" : "Stage retiré")));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: saved.contains(stage) ? const Color(0xFF0A1F44) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF0A1F44), width: 2),
                            ),
                            child: Icon(
                              saved.contains(stage) ? Icons.bookmark : Icons.bookmark_border,
                              color: saved.contains(stage) ? Colors.white : const Color(0xFF0A1F44),
                              size: 26,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0A1F44),
            ),
          ),
        ],
      ),
    );
  }
}