import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config.dart';
import 'package:frontend/screens/company_profile.dart';
import 'package:frontend/screens/offre_page.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final storage = const FlutterSecureStorage();

  String name = "";
  String email = "";
  bool loading = true;

  int index = 0;

  List<Map<String, dynamic>> offres = [];
  List<Map<String, dynamic>> applications = [];

  final String baseUrl = Config.baseUrl;

  @override
  void initState() {
    super.initState();
    loadData();
    loadOffres();
    loadApplications();
  }

  Future<void> loadData() async {
    name = await storage.read(key: "name") ?? "";
    email = await storage.read(key: "email") ?? "";

    setState(() {
      loading = false;
    });
  }

  Future<void> loadOffres() async {
    final email = await storage.read(key: "email");

    final data = await ApiService().getOffres(email!);

    setState(() {
      offres = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> loadApplications() async {
    final email = await storage.read(key: "email");

    final res = await http.get(
      Uri.parse('$baseUrl/applications/company/$email'),
    );

    if (res.statusCode == 200) {
      setState(() {
        applications = List<Map<String, dynamic>>.from(
          jsonDecode(res.body),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002366), Color(0xFF0A1F44)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard Entreprise",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Bonjour $name 👋",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // PROFILE
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.person_rounded,
                size: 22,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyProfile(),
                  ),
                );
              },
            ),
          ),
          // LOGOUT
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                size: 22,
                color: Colors.white,
              ),
              onPressed: () async {
                await storage.deleteAll();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _body(),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.white,
          currentIndex: index,
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            setState(() {
              index = i;
            });
          },
          selectedItemColor: const Color(0xFF002366),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: "Accueil",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: "Candidats",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: "Offres",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_rounded),
              activeIcon: Icon(Icons.school_rounded),
              label: "Stagiaires",
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _body() {
    switch (index) {
      case 0:
        return accueil();

      case 1:
        return candidatesView();

     case 2:
  return const CompanyOffresPage();

      case 3:
        return stagesView();

      default:
        return accueil();
    }
  }


  Widget _buildSmallBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget activeOffreCard(Map<String, dynamic> o) {
    final title = o['titre'] ?? "";
    final domain = o['domaine'] ?? "Général";
    final duration = o['duree'] ?? "N/A";
    final city = o['city'] ?? "N/A";
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1F44).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Active",
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallBadge(Icons.business_rounded, domain, const Color(0xFF3B82F6)),
              _buildSmallBadge(Icons.location_on_rounded, city, const Color(0xFF64748B)),
              _buildSmallBadge(Icons.schedule_rounded, duration, const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget dashboardItem(
    IconData icon,
    String count,
    String title,
    Color tintColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1F44).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tintColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: tintColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget actionCard(
    String title,
    String subtitle,
    IconData icon,
    Color tintColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1F44).withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tintColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: tintColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget accueil() {
    final activeOffres =
        offres.where((o) => o['active'] == true).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // GRID OF 4 STATS CARDS
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              dashboardItem(
                Icons.work_rounded,
                offres.length.toString(),
                "Offres",
                const Color(0xFF3B82F6),
              ),
              dashboardItem(
                Icons.people_alt_rounded,
                applications.where((a) => a['status'] == 'pending' || a['status'] == null).length.toString(),
                "Candidats",
                const Color(0xFFF59E0B),
              ),
              dashboardItem(
                Icons.school_rounded,
                applications.where((a) {
                  final s = (a['status'] ?? "").toString().toLowerCase();
                  return s == 'accepted' || s == 'signed_by_company' || s == 'fully_signed';
                }).length.toString(),
                "Stagiaires",
                const Color(0xFF10B981),
              ),
              dashboardItem(
                Icons.description_rounded,
                applications.where((a) {
                  final s = (a['status'] ?? "").toString().toLowerCase();
                  return s == 'signed_by_company' || s == 'fully_signed';
                }).length.toString(),
                "Conventions",
                const Color(0xFF8B5CF6),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            "Offres actives",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 12),

          activeOffres.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.work_outline_rounded, size: 36, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        "Aucune offre active",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: activeOffres.map((o) => activeOffreCard(o)).toList(),
                ),

          const SizedBox(height: 28),

          const Text(
            "Conventions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.description_outlined, size: 36, color: Colors.grey[400]),
                const SizedBox(height: 10),
                Text(
                  "Aucune convention pour le moment",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            "Actions rapides",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              actionCard(
                "Publier Offre",
                "Créer une offre de stage",
                Icons.add_business_rounded,
                const Color(0xFF3B82F6),
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OffresPage(),
                    ),
                  );
                  loadOffres();
                },
              ),
              actionCard(
                "Voir Candidats",
                "Gérer les candidatures",
                Icons.people_alt_rounded,
                const Color(0xFFF59E0B),
                () {
                  setState(() {
                    index = 1;
                  });
                },
              ),
              actionCard(
                "Signer Convention",
                "Contrats de stage",
                Icons.draw_rounded,
                const Color(0xFF8B5CF6),
                () {},
              ),
              actionCard(
                "Encadrants",
                "Gérer vos collaborateurs",
                Icons.badge_rounded,
                const Color(0xFF10B981),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GestionEncadrantsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  void _showCandidateDetailsDialog(BuildContext context, Map<String, dynamic> a) {
    final String studentName = (a['studentName'] ?? a['studentEmail'] ?? "Étudiant").toString();
    final String studentEmail = (a['studentEmail'] ?? "").toString();
    final String phone = (a['phone'] ?? "Non spécifié").toString();
    final String niveau = (a['niveau'] ?? "Non spécifié").toString();
    final String address = (a['city'] ?? "Non spécifié").toString();
    final String university = (a['etablissement'] ?? "Non spécifiée").toString();
    final String duree = (a['duree'] ?? "Non spécifiée").toString();
    final String note = (a['note'] ?? "Aucune note").toString();
    final String typeStage = (a['typeStage'] ?? "Présentiel").toString();
    final String? studentPhoto = a['studentPhoto'];
    final String status = (a['status'] ?? "pending").toString().toLowerCase();
    final String offreTitre = (a['offre']?['titre'] ?? a['offreTitre'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6F9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF002366).withOpacity(0.1),
                          backgroundImage: studentPhoto != null && studentPhoto.isNotEmpty
                              ? NetworkImage("${ApiService.baseUrl}/uploads/$studentPhoto")
                              : null,
                          child: (studentPhoto == null || studentPhoto.isEmpty)
                              ? Text(
                                  studentName.isNotEmpty ? (studentName.length >= 2 ? studentName.substring(0, 2) : studentName).toUpperCase() : "ET",
                                  style: const TextStyle(
                                    color: Color(0xFF002366),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A1F44),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                studentEmail,
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Badge titre de l'offre
                  if (offreTitre.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF002366).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF002366).withOpacity(0.15)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002366).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.work_outline_rounded, size: 18, color: Color(0xFF002366)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Offre postulée",
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(offreTitre,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF002366)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        )),
                      ]),
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    "Informations Étudiant",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Information Details Grid / List
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.phone, "Téléphone", phone),
                        const Divider(),
                        _detailRow(Icons.school, "Université", university),
                        const Divider(),
                        _detailRow(Icons.history_edu, "Niveau", niveau),
                        const Divider(),
                        _detailRow(Icons.location_on, "Adresse", address),
                        const Divider(),
                        _detailRow(Icons.hourglass_bottom, "Durée", duree),
                        const Divider(),
                        _detailRow(Icons.online_prediction, "Type de stage", typeStage),
                        const Divider(),
                        _detailRow(Icons.notes, "Note supplémentaire", note),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Documents joints",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Documents Row
                  Row(
                    children: [
                      if (a['cv'] != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF002366),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                            label: const Text("Voir CV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final cvUrl = "$baseUrl/uploads/${a['cv']}";
                              _launchUrl(cvUrl);
                            },
                          ),
                        ),
                      if (a['cv'] != null && a['motivation'] != null)
                        const SizedBox(width: 12),
                      if (a['motivation'] != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD6B38A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.description, color: Colors.white),
                            label: const Text("Lettre de Mot.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final motUrl = "$baseUrl/uploads/${a['motivation']}";
                              _launchUrl(motUrl);
                            },
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Actions Buttons (Accept / Refuse) - only show if status is pending
                  if (status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              // Call Refuse API
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );
                              try {
                                await http.post(Uri.parse('$baseUrl/applications/${a['id']}/refuse'));
                                if (!context.mounted) return;
                                Navigator.pop(context); // close loader
                                Navigator.pop(context); // close modal details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Candidature refusée")),
                                );
                                loadApplications(); // reload list
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context); // close loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Erreur de réseau")),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Refuser",
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              // Call Accept API
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(child: CircularProgressIndicator()),
                              );
                              try {
                                final res = await http.post(Uri.parse('$baseUrl/applications/${a['id']}/accept'));
                                final body = jsonDecode(res.body);

                                if (!context.mounted) return;

                                if (res.statusCode != 200 && res.statusCode != 201) {
                                  Navigator.pop(context); // close loader
                                  String msg = "Erreur lors de l'acceptation";
                                  if (body is Map && body.containsKey("message")) {
                                    msg = body["message"].toString();
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(msg), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                Navigator.pop(context); // close loader
                                Navigator.pop(context); // close modal details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Candidature acceptée !"), backgroundColor: Colors.green),
                                );
                                loadApplications(); // reload list
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context); // close loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Erreur de réseau")),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Accepter",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF002366)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0A1F44)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget candidatesView() {
    final pendingApps = applications.where((a) {
      final s = (a['status'] ?? "pending").toString().toLowerCase();
      return s == 'pending';
    }).toList();

    if (pendingApps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),
              const Text(
                "Aucun candidat en attente",
                style: TextStyle(fontSize: 18, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Les candidatures en attente de traitement apparaîtront ici.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: pendingApps.length,
      itemBuilder: (context, i) {
        final a = pendingApps[i];
        final String studentName = (a['studentName'] ?? a['studentEmail'] ?? "Étudiant").toString();
        final String studentEmail = (a['studentEmail'] ?? "").toString();
        final String status = (a['status'] ?? "pending").toString().toLowerCase();
        final String offreTitre = (a['offre']?['titre'] ?? a['offreTitre'] ?? '').toString();
        final String? studentPhoto = a['studentPhoto'];

        Color statusColor;
        String statusText;
        switch (status) {
          case 'accepted':
            statusColor = Colors.green;
            statusText = "Accepté";
            break;
          case 'refused':
            statusColor = Colors.red;
            statusText = "Refusé";
            break;
          case 'signed_by_company':
            statusColor = Colors.blue;
            statusText = "Signé Ent.";
            break;
          case 'fully_signed':
            statusColor = Colors.teal;
            statusText = "Signé Étd.";
            break;
          default:
            statusColor = Colors.orange;
            statusText = "En attente";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1F44).withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF002366).withOpacity(0.06),
                backgroundImage: studentPhoto != null && studentPhoto.isNotEmpty
                    ? NetworkImage("${ApiService.baseUrl}/uploads/$studentPhoto")
                    : null,
                child: (studentPhoto == null || studentPhoto.isEmpty)
                    ? Text(
                        studentName.isNotEmpty ? studentName.substring(0, 2).toUpperCase() : "ET",
                        style: const TextStyle(
                          color: Color(0xFF002366),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
            title: Text(
              studentName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  studentEmail,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                // Badge titre de l'offre
                if (offreTitre.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002366).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF002366).withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.work_outline_rounded, size: 12, color: Color(0xFF002366)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            offreTitre,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002366),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
            ),
            onTap: () {
              _showCandidateDetailsDialog(context, a);
            },
          ),
        );
      },
    );
  }

  Widget stagesView() {
    final acceptedApps = applications.where((a) {
      final s = (a['status'] ?? "").toString().toLowerCase();
      return s == 'accepted' || s == 'signed_by_company' || s == 'fully_signed';
    }).toList();

    if (acceptedApps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_outlined, size: 56, color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),
              const Text(
                "Aucun stagiaire actif",
                style: TextStyle(fontSize: 18, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Les étudiants acceptés apparaîtront ici en tant que stagiaires.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: acceptedApps.length,
      itemBuilder: (context, i) {
        final a = acceptedApps[i];
        final String studentName = (a['studentName'] ?? a['studentEmail'] ?? "Stagiaire").toString();
        final String studentEmail = (a['studentEmail'] ?? "").toString();
        final String offerTitle = (a['offre'] != null ? a['offre']['titre'] : a['duree']).toString();
        final String? studentPhoto = a['studentPhoto'];
        final String duration = (a['duree'] ?? "Non spécifiée").toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1F44).withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.06),
                backgroundImage: studentPhoto != null && studentPhoto.isNotEmpty
                    ? NetworkImage("${ApiService.baseUrl}/uploads/$studentPhoto")
                    : null,
                child: (studentPhoto == null || studentPhoto.isEmpty)
                    ? const Icon(
                        Icons.school,
                        color: Color(0xFF10B981),
                        size: 26,
                      )
                    : null,
              ),
            ),
            title: Text(
              studentName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  studentEmail,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.work_outline_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                duration,
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            onTap: () {
              _showCandidateDetailsDialog(context, a);
            },
          ),
        );
      },
    );
  }
}



class AjouterEncadrantPage extends StatefulWidget {
  final int offreId;

  const AjouterEncadrantPage({
    super.key,
    required this.offreId,
  });

  @override
  State<AjouterEncadrantPage> createState() =>
      _AjouterEncadrantPageState();
}

class _AjouterEncadrantPageState
    extends State<AjouterEncadrantPage> {

  final nomController = TextEditingController();
  final emailController = TextEditingController();
  final departementController = TextEditingController();
  final telephoneController = TextEditingController();
  final adresseController = TextEditingController();
  final storage = const FlutterSecureStorage();

  List<String> availablePosts = [];
  String? selectedPoste;
  bool loadingPosts = true;

  // Nom de l'entreprise connectée (affiché en lecture seule)
  String entrepriseName = '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadEntrepriseName();
  }

  Future<void> _loadEntrepriseName() async {
    final name = await storage.read(key: "name") ?? '';
    setState(() {
      entrepriseName = name;
    });
  }

  Future<void> _loadPosts() async {
    try {
      final stored = await storage.read(key: "custom_posts");
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        setState(() {
          availablePosts = decoded.map((e) => e.toString()).toList();
          loadingPosts = false;
        });
      } else {
        final List<String> defaultPosts = [
          "Développeur Logiciel",
          "Chef de Projet",
          "Tech Lead",
          "Architecte",
          "RH / Recruteur",
          "Manager",
          "Ingénieur DevOps",
          "Data Scientist",
          "Designer UX/UI"
        ];
        setState(() {
          availablePosts = defaultPosts;
          loadingPosts = false;
        });
        await _savePosts();
      }
    } catch (e) {
      print("Error loading posts: $e");
      setState(() {
        loadingPosts = false;
      });
    }
  }

  Future<void> _savePosts() async {
    try {
      await storage.write(key: "custom_posts", value: jsonEncode(availablePosts));
    } catch (e) {
      print("Error saving posts: $e");
    }
  }

  void _showManagePostsDialog() {
    final addController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002366).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_outlined, color: Color(0xFF002366), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Gérer les Postes",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: availablePosts.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  "Aucun poste disponible. Ajoutez-en un !",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: availablePosts.length,
                                separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                                itemBuilder: (context, index) {
                                  final post = availablePosts[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                    title: Text(
                                      post,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            availablePosts.removeAt(index);
                                          });
                                          setState(() {
                                            if (selectedPoste == post) {
                                              selectedPoste = null;
                                            }
                                          });
                                          _savePosts();
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addController,
                      decoration: InputDecoration(
                        hintText: "Nouveau poste...",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF002366),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002366),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final text = addController.text.trim();
                          if (text.isEmpty) return;
                          if (availablePosts.contains(text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Ce poste existe déjà"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setDialogState(() {
                            availablePosts.add(text);
                          });
                          setState(() {});
                          _savePosts();
                          addController.clear();
                        },
                        child: const Text(
                          "Ajouter",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 20, right: 20),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Fermer",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildDropdownField(
    String hint,
    IconData icon,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
    VoidCallback onManage,
  ) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF002366),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF002366),
                  width: 2,
                ),
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF002366)),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF002366)),
            onPressed: onManage,
            tooltip: "Gérer les postes",
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002366), Color(0xFF0A1F44)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        title: const Text(
          "Ajouter Encadrant",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1F44).withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informations Encadrant Professionnel",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              // ENTREPRISE (lecture seule - pré-rempli automatiquement)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business_rounded, color: Color(0xFF002366), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Entreprise",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entrepriseName.isNotEmpty ? entrepriseName : '—',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF002366),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF002366).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Auto",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF002366),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // NOM COMPLET
              buildField(
                "Nom complet *",
                Icons.person_outline,
                nomController,
              ),
              const SizedBox(height: 16),
              // EMAIL
              buildField(
                "Email Encadrant * (Gmail obligatoire)",
                Icons.email_outlined,
                emailController,
              ),
              const SizedBox(height: 16),
              // DEPARTEMENT
              buildField(
                "Département *",
                Icons.apartment_outlined,
                departementController,
              ),
              const SizedBox(height: 16),
              // TELEPHONE
              buildField(
                "Téléphone * (8 chiffres)",
                Icons.phone_outlined,
                telephoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
              ),
              const SizedBox(height: 16),
              // ADRESSE
              buildField(
                "Adresse *",
                Icons.location_on_outlined,
                adresseController,
              ),
              const SizedBox(height: 16),
              // POSTE
              loadingPosts
                  ? const Center(child: CircularProgressIndicator())
                  : buildDropdownField(
                      "Poste *",
                      Icons.work_outline,
                      selectedPoste,
                      availablePosts,
                      (val) {
                        setState(() {
                          selectedPoste = val;
                        });
                      },
                      _showManagePostsDialog,
                    ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002366),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
  final userId = await storage.read(key: "userId");
  final role = await storage.read(key: "role");

  print("DEBUG userId = $userId");
  print("DEBUG role = $role");
  if (role != "company") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Only company can add encadrant")),
    );
    return;
  }

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("userId null - login problem")),
    );
    return;
  }

  final nom = nomController.text.trim();
  final email = emailController.text.trim();
  final dept = departementController.text.trim();
  final tel = telephoneController.text.trim();
  final adresse = adresseController.text.trim();
  final poste = selectedPoste;

  if (nom.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Le nom complet est obligatoire"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("L'email est obligatoire"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (!email.toLowerCase().endsWith("@gmail.com")) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("L'email doit obligatoirement être une adresse Gmail (ex: exemple@gmail.com)"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (dept.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Le département est obligatoire"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (tel.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Le téléphone est obligatoire"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (tel.length != 8) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Le téléphone doit être composé de 8 chiffres"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (adresse.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("L'adresse est obligatoire"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (poste == null || poste.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Veuillez sélectionner un poste"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  try {
    final res = await ApiService().createEncadrant({
      "nomComplet": nom,
      "email": email,
      "departement": dept,
      "telephone": tel,
      "adresse": adresse,
      "poste": poste,
      "companyId": int.parse(userId),
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CredentialDialog(
          nomComplet: nom,
          email: res['email'] ?? email,
          password: res['password'] ?? '',
          onClosed: () {
            Navigator.pop(context); // close dialog
            Navigator.pop(context, true); // close AjouterEncadrantPage and notify success
          },
        ),
      );
    }

  } catch (e) {
    print("ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur ajout encadrant")),
    );
  }
},

                  child: const Text(
                    "Envoyer",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool showCounter = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        counterText: showCounter ? null : "",
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF002366),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF002366),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class CredentialDialog extends StatelessWidget {
  final String nomComplet;
  final String email;
  final String password;
  final VoidCallback onClosed;

  const CredentialDialog({
    super.key,
    required this.nomComplet,
    required this.email,
    required this.password,
    required this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF002366).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                size: 40,
                color: Color(0xFF002366),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Compte Créé !",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002366),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Les accès pour $nomComplet ont été générés.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            // Credential Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // EMAIL ROW
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Email de connexion",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20, color: Color(0xFFD6B38A)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Email copié !")),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // PASSWORD ROW
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Mot de passe temporaire",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              password,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002366),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20, color: Color(0xFFD6B38A)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: password));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Mot de passe copié !")),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // WARNING CARD
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Ce mot de passe ne sera affiché qu'une seule fois. Veuillez le copier pour le transmettre à l'encadrant.",
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002366),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onClosed,
                child: const Text(
                  "Terminer",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GestionEncadrantsPage extends StatefulWidget {
  const GestionEncadrantsPage({super.key});

  @override
  State<GestionEncadrantsPage> createState() => _GestionEncadrantsPageState();
}

class _GestionEncadrantsPageState extends State<GestionEncadrantsPage> {
  final storage = const FlutterSecureStorage();
  final searchController = TextEditingController();

  List encadrants = [];
  List filteredEncadrants = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchEncadrants();
  }

  Future<void> fetchEncadrants() async {
    setState(() {
      loading = true;
    });
    try {
      final userId = await storage.read(key: "userId");
      if (userId != null) {
        final list = await ApiService().getEncadrantsProfessionnelsByCompany(userId);
        setState(() {
          encadrants = list;
          filteredEncadrants = list;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement: $e")),
      );
    }
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredEncadrants = encadrants;
      });
      return;
    }
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      filteredEncadrants = encadrants.where((enc) {
        final nom = (enc['nomComplet'] ?? '').toString().toLowerCase();
        final email = (enc['email'] ?? '').toString().toLowerCase();
        final poste = (enc['poste'] ?? '').toString().toLowerCase();
        final dept = (enc['departement'] ?? '').toString().toLowerCase();
        return nom.contains(lowercaseQuery) ||
            email.contains(lowercaseQuery) ||
            poste.contains(lowercaseQuery) ||
            dept.contains(lowercaseQuery);
      }).toList();
    });
  }

  String getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(" ").where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> confirmDelete(Map enc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer l'encadrant", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002366))),
        content: Text("Êtes-vous sûr de vouloir supprimer l'encadrant professionnel ${enc['nomComplet']} ? Son compte d'accès sera également supprimé."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().deleteEncadrantProfessionnel(enc['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Encadrant professionnel supprimé")),
        );
        fetchEncadrants();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de suppression: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002366), Color(0xFF0A1F44)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        title: const Text(
          "Gestion des Encadrants",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: fetchEncadrants,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF002366),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Ajouter Encadrant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AjouterEncadrantPage(offreId: 1),
            ),
          );
          if (result == true) {
            fetchEncadrants();
          }
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SEARCH BAR
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A1F44).withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: filterSearch,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: "Rechercher par nom, email, poste...",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                                onPressed: () {
                                  searchController.clear();
                                  filterSearch("");
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF002366), width: 2),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Encadrants Professionnels",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002366),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // LIST OF SUPERVISORS
                  Expanded(
                    child: filteredEncadrants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  "Aucun encadrant trouvé",
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Ajoutez un encadrant professionnel pour commencer.",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredEncadrants.length,
                            itemBuilder: (context, idx) {
                              final enc = filteredEncadrants[idx];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Circle Avatar with Gradient
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF002366), Color(0xFF0F172A)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF002366).withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            getInitials(enc['nomComplet'] ?? ''),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Info details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              enc['nomComplet'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              enc['poste'] ?? 'Encadrant Professionnel',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (enc['departement'] != null && enc['departement'].toString().isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      enc['departement'],
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF475569),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                if (enc['departement'] != null && enc['departement'].toString().isNotEmpty)
                                                  const SizedBox(width: 8),
                                                Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    enc['email'] ?? '',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Delete/Copy buttons
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Color(0xFFD6B38A), size: 20),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: enc['email'] ?? ''));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Email copié !")),
                                              );
                                            },
                                            tooltip: "Copier l'email",
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            onPressed: () => confirmDelete(enc),
                                            tooltip: "Supprimer l'encadrant",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class CompanyOffresPage extends StatefulWidget {
  const CompanyOffresPage({super.key});

  @override
  State<CompanyOffresPage> createState() => _CompanyOffresPageState();
}

class _CompanyOffresPageState extends State<CompanyOffresPage> {
  final storage = const FlutterSecureStorage();

  List offres = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOffres();
  }

  // ================= LOAD =================
  Future<void> loadOffres() async {
    final email = await storage.read(key: "email");

    final data = await ApiService().getOffres(email!);

    setState(() {
      offres = data;
      loading = false;
    });
  }

  // ================= DELETE =================
  Future<void> deleteOffre(int id) async {
    await ApiService().deleteOffre(id);
    await loadOffres();
  }

  // ================= TOGGLE ACTIVE =================
  Future<void> toggleActive(Map offre) async {
    final id = offre['id'];
    final newValue = !(offre['active'] == true);

    await ApiService().updateStatus(id, newValue);

    setState(() {
      offre['active'] = newValue;
    });
  }

  // ================= UPDATE =================
  Future<void> updateOffre(int id, Map data) async {
    await ApiService().updateOffre(id, data);
    await loadOffres();
  }



  // ================= DECO HELPER =================
  InputDecoration _dialogInputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF002366), width: 2),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================= EDIT DIALOG =================
  void showEditDialog(Map offre) {
    final titre = TextEditingController(text: offre['titre']);
    final domaine = TextEditingController(text: offre['domaine']);
    final ville = TextEditingController(text: offre['city']);
    final duree = TextEditingController(text: offre['duree']);
    
    // Skills
    List<String> skillsList = List<String>.from(offre["skills"] ?? offre["competence"] ?? []);
    final skills = TextEditingController(text: skillsList.join(", "));

    // Niveau
    String selectedNiveau = offre['niveau'] ?? "3 eme licence";
    final List<String> niveaux = ["3 eme licence", "2 master professionnel", "2eme master de recherche"];
    if (!niveaux.contains(selectedNiveau)) selectedNiveau = niveaux[0];

    // Places
    int placesCount = offre['places'] ?? 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002366).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF002366), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Modifier l'Offre",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    TextField(controller: titre, decoration: _dialogInputDeco("Titre")),
                    const SizedBox(height: 12),
                    TextField(controller: domaine, decoration: _dialogInputDeco("Domaine")),
                    const SizedBox(height: 12),
                    TextField(controller: ville, decoration: _dialogInputDeco("Ville")),
                    const SizedBox(height: 12),
                    TextField(controller: duree, decoration: _dialogInputDeco("Durée")),
                    const SizedBox(height: 12),
                    TextField(controller: skills, decoration: _dialogInputDeco("Compétences (séparées par virgules)")),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedNiveau,
                      dropdownColor: Colors.white,
                      decoration: _dialogInputDeco("Niveau requis"),
                      items: niveaux.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setStateDialog(() => selectedNiveau = v!),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Nombre de places",
                            style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF002366)),
                                onPressed: () => setStateDialog(() {
                                  if (placesCount > 1) placesCount--;
                                }),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  placesCount.toString(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF002366)),
                                onPressed: () => setStateDialog(() {
                                  placesCount++;
                                }),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002366),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await updateOffre(offre['id'], {
                      "titre": titre.text,
                      "domaine": domaine.text,
                      "city": ville.text,
                      "duree": duree.text,
                      "niveau": selectedNiveau,
                      "places": placesCount,
                      "skills": skills.text.split(",").map((e) => e.trim()).toList(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Sauvegarder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF002366),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OffresPage()),
          );
          loadOffres();
        },
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : offres.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A1F44).withOpacity(0.02),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(Icons.work_outline_rounded, size: 56, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Aucune offre publiée",
                          style: TextStyle(fontSize: 18, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Cliquez sur le bouton + pour publier votre première offre de stage.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offres.length,
                  itemBuilder: (context, i) {
                    final offre = offres[i];
                    final encadrant = (offre["invitations"] is List &&
                            offre["invitations"].isNotEmpty &&
                            offre["invitations"][0]["encadrant"] != null)
                        ? offre["invitations"][0]["encadrant"]
                        : null;
                    final title = offre['titre'] ?? "";
                    final domain = offre['domaine'] ?? "Général";
                    final duration = offre['duree'] ?? "N/A";
                    final city = offre['city'] ?? "N/A";
                    final level = offre['niveau'] ?? "Tous";
                    final places = offre['places'] ?? 1;
                    final isActive = offre['active'] == true;
                    final typeStage = (offre['typeStage'] ?? '').toString();
                    final remuneration = (offre['remuneration'] ?? '').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A1F44).withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => toggleActive(offre),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isActive ? "Active" : "Inactive",
                                        style: TextStyle(
                                          color: isActive ? const Color(0xFF065F46) : const Color(0xFF475569),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBadge(Icons.business_rounded, domain, const Color(0xFF3B82F6)),
                              _buildBadge(Icons.location_on_rounded, city, const Color(0xFF64748B)),
                              _buildBadge(Icons.schedule_rounded, duration, const Color(0xFF10B981)),
                              _buildBadge(Icons.school_rounded, level, const Color(0xFF8B5CF6)),
                              _buildBadge(Icons.people_rounded, "$places place${places > 1 ? 's' : ''}", const Color(0xFFF59E0B)),
                              if (typeStage.isNotEmpty)
                                _buildBadge(
                                  typeStage == "En ligne" ? Icons.laptop_rounded : Icons.business_center_rounded,
                                  typeStage,
                                  const Color(0xFF6366F1),
                                ),
                              if (remuneration.isNotEmpty)
                                _buildBadge(Icons.payments_rounded, "$remuneration DT/mois", const Color(0xFF059669)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                "Période : ${offre['dateDebut'] ?? '--'}  →  ${offre['dateFin'] ?? '--'}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: encadrant != null
                                    ? Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF002366).withOpacity(0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF002366)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Encadrant professionnel",
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  encadrant["nomComplet"] ?? "",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF334155),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Aucun encadrant assigné",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    hoverColor: const Color(0xFFF1F5F9),
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit_rounded, color: Color(0xFF0F172A), size: 18),
                                    ),
                                    onPressed: () => showEditDialog(offre),
                                  ),
                                  IconButton(
                                    hoverColor: const Color(0xFFFEE2E2),
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 18),
                                    ),
                                    onPressed: () => deleteOffre(offre['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
 Widget _lineIcon(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF002366)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text.isEmpty ? "-" : text,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ],
  );
}

Widget _infoItem(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF002366)),
        const SizedBox(width: 6),
        Text(
          text.isEmpty ? "-" : text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
}