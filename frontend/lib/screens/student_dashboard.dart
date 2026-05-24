import 'dart:convert';
import 'package:frontend/config.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/conversations_page.dart';
import 'package:frontend/screens/demande_stage/demande_stage_page.dart';
import 'package:frontend/screens/presention.dart';
import 'package:frontend/screens/rapports/rapport_page.dart';
import 'package:frontend/screens/reunions.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int currentIndex = 0;
String view = "home";
  String name = "";
  String photo = "";
  final TextEditingController search = TextEditingController();
  final api = ApiService();
List notifications = [];
int unreadCount = 0;
  List stages = [];
  List myApplications = [];
List encadrements = [];

  // Advanced filters state
  String filterTitre = "";
  String filterDomaine = "";
  String filterNiveau = "";
  String filterCity = "";
  String filterDuree = "";
  String filterSkills = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadStages();
    loadMyApplications();
    loadEncadrements(); 
    loadNotifications();
    search.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
Future loadNotifications() async {
  List notifs = [];
  int unread = 0;

  // 1. Get reports comments
  try {
    final data = await api.getReports();
    if (data is List) {
      for (var r in data) {
        if (r["commentaire"] != null &&
            r["commentaire"].toString().isNotEmpty) {
          notifs.add({
            "title": "Commentaire sur : ${r['title'] ?? 'Rapport'}",
            "message": r["commentaire"],
            "type": "comment",
            "read": false,
            "createdAt": r["updatedAt"] ?? r["createdAt"],
          });
          unread++;
        }
      }
    }
  } catch (e) {
    print("Error loading report comments: $e");
  }

  // 2. Get database notifications
  try {
    final dbNotifs = await api.getMyNotifications();
    if (dbNotifs is List) {
      for (var n in dbNotifs) {
        final isRead = n["read"] == true;
        notifs.add({
          "id": n["id"],
          "title": n["title"] ?? "Notification",
          "message": n["message"] ?? "",
          "type": n["type"] ?? "dashboard",
          "read": isRead,
          "createdAt": n["createdAt"],
        });
        if (!isRead) {
          unread++;
        }
      }
    }
  } catch (e) {
    print("Error loading database notifications: $e");
  }

  // Sort newest first
  notifs.sort((a, b) {
    final dateA = a["createdAt"] != null ? DateTime.tryParse(a["createdAt"].toString()) : null;
    final dateB = b["createdAt"] != null ? DateTime.tryParse(b["createdAt"].toString()) : null;
    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;
    return dateB.compareTo(dateA);
  });

  setState(() {
    notifications = notifs;
    unreadCount = unread;
  });
}
  List get activeStages {
    // 1. Get only active stages
    List allActive = stages.where((o) => o['active'].toString() == "true").toList();
    
    // 2. Main search bar filter (applies a global search on multiple fields)
    String query = search.text.toLowerCase().trim();
    
    // 3. Filter using all advanced filter fields
    return allActive.where((o) {
      // Global search bar
      if (query.isNotEmpty) {
        final title = (o["titre"] ?? "").toString().toLowerCase();
        final company = (o["companyName"] ?? "").toString().toLowerCase();
        final domain = (o["domaine"] ?? "").toString().toLowerCase();
        final city = (o["city"] ?? "").toString().toLowerCase();
        final level = (o["niveau"] ?? "").toString().toLowerCase();
        final duration = (o["duree"] ?? "").toString().toLowerCase();
        final skillsList = List.from(o["skills"] ?? o["competence"] ?? []);
        final skillsStr = skillsList.join(", ").toLowerCase();
        
        bool matchesGlobal = title.contains(query) ||
            company.contains(query) ||
            domain.contains(query) ||
            city.contains(query) ||
            level.contains(query) ||
            duration.contains(query) ||
            skillsStr.contains(query);
            
        if (!matchesGlobal) return false;
      }
      
      // Advanced Title Filter
      if (filterTitre.isNotEmpty) {
        final title = (o["titre"] ?? "").toString().toLowerCase();
        if (!title.contains(filterTitre.toLowerCase().trim())) return false;
      }
      
      // Advanced Domaine Filter
      if (filterDomaine.isNotEmpty) {
        final domain = (o["domaine"] ?? "").toString().toLowerCase();
        if (!domain.contains(filterDomaine.toLowerCase().trim())) return false;
      }
      
      // Advanced Niveau Filter
      if (filterNiveau.isNotEmpty) {
        final level = (o["niveau"] ?? "").toString().toLowerCase();
        if (!level.contains(filterNiveau.toLowerCase().trim())) return false;
      }
      
      // Advanced City Filter
      if (filterCity.isNotEmpty) {
        final city = (o["city"] ?? "").toString().toLowerCase();
        if (!city.contains(filterCity.toLowerCase().trim())) return false;
      }
      
      // Advanced Duree Filter
      if (filterDuree.isNotEmpty) {
        final duration = (o["duree"] ?? "").toString().toLowerCase();
        if (!duration.contains(filterDuree.toLowerCase().trim())) return false;
      }
      
      // Advanced Skills Filter
      if (filterSkills.isNotEmpty) {
        final skillsList = List.from(o["skills"] ?? o["competence"] ?? []);
        final skillsStr = skillsList.join(", ").toLowerCase();
        if (!skillsStr.contains(filterSkills.toLowerCase().trim())) return false;
      }
      
      return true;
    }).toList();
  }

  List<String> get availableCities {
    final set = stages
        .where((o) => o['active'].toString() == "true")
        .map((o) => (o['city'] ?? "").toString().trim())
        .where((c) => c.isNotEmpty)
        .toSet();
    return set.toList()..sort();
  }

  List<String> get availableLevels {
    final set = stages
        .where((o) => o['active'].toString() == "true")
        .map((o) => (o['niveau'] ?? "").toString().trim())
        .where((l) => l.isNotEmpty)
        .toSet();
    return set.toList()..sort();
  }

  // ================= PAGES =================

Future loadProfile() async {
  final profile = await api.getProfile();

  setState(() {
    name = profile["name"] ?? "";
    photo = profile["photo"] ?? "";
  });
}
Future loadEncadrements() async {
  final token = await api.storage.read(key: "token");

  if (token == null) {
    throw Exception("Token manquant");
  }

  final res = await http.get(
    Uri.parse('${Config.baseUrl}/encadrements/my'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  setState(() {
    encadrements = jsonDecode(res.body);
  });
}

Future getStudentOffres() async {
  final res = await http.get(
    Uri.parse('${Config.baseUrl}/offres/student')
  );

  return jsonDecode(res.body);
}
Future loadStages() async {
  final res = await http.get(
    Uri.parse('${Config.baseUrl}/offres/student')
  );

  print(res.statusCode);
  print(res.body);

  setState(() {
    stages = jsonDecode(res.body);
  });
}
Future loadMyApplications() async {
  final data = await api.getMyApplications();
  setState(() {
    myApplications = data;
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),

    appBar: AppBar(
  backgroundColor: Colors.transparent,
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0D1B4B), Color(0xFF1A3C8F), Color(0xFF2952B3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.55, 1.0],
      ),
    ),
  ),
  elevation: 0,
  toolbarHeight: 80,
  title: Column(
    children: [
      Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              backgroundImage: photo.isNotEmpty
                  ? NetworkImage("${ApiService.baseUrl}/uploads/$photo")
                  : null,
              child: photo.isEmpty
                  ? Text(
                      name.isNotEmpty ? (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase() : "ST",
                      style: const TextStyle(color: Color(0xFF0D1B4B), fontWeight: FontWeight.bold, fontSize: 14),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting() + ", $name 👋",
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7DD3FC), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text(
                      "Étudiant",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
  actions: [
    Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.4,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A1F44).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active_rounded,
                                        color: Color(0xFF0A1F44),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Centre de notifications",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A1F44),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A1F44).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${notifications.length} au total",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0A1F44),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          Expanded(
                            child: notifications.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.notifications_off_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Aucune notification",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0A1F44),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          "Vous êtes à jour ! Tout est calme ici.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    itemCount: notifications.length,
                                    itemBuilder: (context, i) {
                                      final n = notifications[i];
                                      final bool isComment = n["type"] == "comment";
                                      final bool isUnread = n["read"] == false;
                                      
                                      final Color iconColor = isComment ? const Color(0xFF2563EB) : const Color(0xFFD97706);
                                      final Color bgColor = isComment 
                                          ? const Color(0xFFEFF6FF) 
                                          : const Color(0xFFFFF7ED);
                                      final IconData iconData = isComment 
                                          ? Icons.comment_rounded 
                                          : Icons.campaign_rounded;
                                          
                                      String timeStr = "";
                                      if (n["createdAt"] != null) {
                                        try {
                                          final dt = DateTime.parse(n["createdAt"].toString()).toLocal();
                                          timeStr = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                        } catch (_) {}
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isUnread 
                                                ? iconColor.withOpacity(0.3) 
                                                : const Color(0xFFE2E8F0),
                                            width: isUnread ? 1.5 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Stack(
                                            children: [
                                              if (isUnread)
                                                Positioned(
                                                  left: 0,
                                                  top: 0,
                                                  bottom: 0,
                                                  width: 4,
                                                  child: Container(color: iconColor),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: bgColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        iconData,
                                                        color: iconColor,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  n["title"] ?? "",
                                                                  style: TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                                    color: const Color(0xFF0A1F44),
                                                                  ),
                                                                ),
                                                              ),
                                                              if (isUnread)
                                                                Container(
                                                                  margin: const EdgeInsets.only(left: 8, top: 2),
                                                                  width: 8,
                                                                  height: 8,
                                                                  decoration: BoxDecoration(
                                                                    color: iconColor,
                                                                    shape: BoxShape.circle,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            n["message"] ?? n["commentaire"] ?? "",
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              color: Color(0xFF475569),
                                                              height: 1.4,
                                                            ),
                                                          ),
                                                          if (timeStr.isNotEmpty) ...[
                                                            const SizedBox(height: 8),
                                                            Row(
                                                              children: [
                                                                const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  timeStr,
                                                                  style: const TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.grey,
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
                    );
                  }
                );
              },
            );
            
            // Mark all database notifications as read locally and in the backend
            setState(() { unreadCount = 0; });
            for (var n in notifications) {
              if (n["id"] != null && n["read"] == false) {
                api.markAsRead(n["id"]).catchError((e) {
                  print("Error marking notification $n as read: $e");
                });
                n["read"] = true;
              }
            }
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    ),
    IconButton(
      icon: const Icon(Icons.person_rounded, color: Colors.white),
      onPressed: () => Navigator.pushNamed(context, '/profile'),
    ),
    IconButton(
      icon: const Icon(Icons.logout_rounded, color: Colors.white),
      onPressed: () async {
        await api.storage.deleteAll();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      },
    ),
  ],
),

      //  BODY
    body:
    Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0F4F8), Color(0xFFE8EDF5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 8),

          // ── Barre de recherche ──
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A3C8F).withOpacity(0.06),
                  blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: search,
                  style: const TextStyle(color: Color(0xFF0D1B4B), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Rechercher stage, entreprise...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF1A3C8F), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                height: 36, width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3C8F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.tune_rounded,
                    color: Color(0xFF1A3C8F), size: 18),
                  onPressed: showAdvancedFilters,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 18),

          // ── Quick Actions Label ──
          const Text(
            "Accès rapide",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),

          // ── Quick Action Cards (horizontal scroll) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _quickCard(Icons.work_rounded, "Conventions", const Color(0xFF2563EB), const Color(0xFFEFF6FF), '/stages'),
                _quickCard(Icons.task_rounded, "Tâches", const Color(0xFF7C3AED), const Color(0xFFF5F3FF), '/taches'),
                _quickCardCustom(
                  icon: Icons.slideshow_rounded,
                  label: "Présentations",
                  color: const Color(0xFF0891B2),
                  bg: const Color(0xFFECFEFF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresentationsPage())),
                ),
                _quickCardCustom(
                  icon: Icons.groups_rounded,
                  label: "Réunions",
                  color: const Color(0xFF1A3C8F),
                  bg: const Color(0xFFEFF6FF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReunionsPage())),
                ),GestureDetector(
  onTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9), // Light background for nice contrast
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mes encadrements",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: encadrements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1F44).withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                size: 48,
                                color: Color(0xFF0A1F44),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Aucun encadrement",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A1F44),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Vous n'avez pas encore d'encadrement assigné par l'administration.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: encadrements.length,
                        itemBuilder: (context, i) {
                          final e = encadrements[i];
                          
                          // Student Details
                          final studName = "${e["student"]?["name"] ?? ''} ${e["student"]?["prenom"] ?? ''}".trim();
                          final studEmail = e["student"]?["email"] ?? '';
                          final String studInitials = studName.isNotEmpty
                              ? studName.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
                              : 'ET';

                          // Advisor Details
                          final encName = "${e["encadrant"]?["name"] ?? ''} ${e["encadrant"]?["prenom"] ?? ''}".trim();
                          final encEmail = e["encadrant"]?["email"] ?? '';
                          final String encInitials = encName.isNotEmpty
                              ? encName.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
                              : 'EA';

                          final spec = e["specialite"] ?? '';
                          final lvl = e["niveau"] ?? '';
                          final annee = e["annee"] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Card Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF0A1F44)),
                                          const SizedBox(width: 6),
                                          Text(
                                            annee,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFF0A1F44),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.2)),
                                        ),
                                        child: const Text(
                                          'Assigné',
                                          style: TextStyle(
                                            color: Color(0xFF16A34A),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Card Body
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Student Profile Row
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.08),
                                            child: Text(
                                              studInitials,
                                              style: const TextStyle(
                                                color: Color(0xFF3B82F6),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'ÉTUDIANT',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  studName.isNotEmpty ? studName : 'Étudiant',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF0A1F44),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        studEmail,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // 2. Connector line
                                      Padding(
                                        padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
                                        child: Container(
                                          width: 2,
                                          height: 18,
                                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                                        ),
                                      ),

                                      // 3. Encadrant Profile Row
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: const Color(0xFF1A3C8F).withOpacity(0.08),
                                            child: Text(
                                              encInitials,
                                              style: const TextStyle(
                                                color: Color(0xFF1A3C8F),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'ENCADRANT ACADÉMIQUE',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  encName.isNotEmpty ? encName : 'N/A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF0A1F44),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        encEmail,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                      const SizedBox(height: 12),
                                      // Details section
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Niveau',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  lvl.isNotEmpty ? lvl : 'N/A',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0A1F44),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Spécialité',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  spec.isNotEmpty ? spec : 'N/A',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0A1F44),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  },
  child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFBBF7D0)),
      boxShadow: [
        BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
      ],
    ),
    child: Column(
      children: const [
        Icon(Icons.school_rounded, color: Color(0xFF16A34A), size: 24),
        SizedBox(height: 6),
        Text(
          "Encadrement",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
),
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (hasActiveFilters) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  if (filterTitre.isNotEmpty)
                    _filterChip("Titre: $filterTitre", () => setState(() => filterTitre = "")),
                  if (filterDomaine.isNotEmpty)
                    _filterChip("Domaine: $filterDomaine", () => setState(() => filterDomaine = "")),
                  if (filterNiveau.isNotEmpty)
                    _filterChip("Niveau: $filterNiveau", () => setState(() => filterNiveau = "")),
                  if (filterCity.isNotEmpty)
                    _filterChip("Ville: $filterCity", () => setState(() => filterCity = "")),
                  if (filterDuree.isNotEmpty)
                    _filterChip("Durée: $filterDuree", () => setState(() => filterDuree = "")),
                  if (filterSkills.isNotEmpty)
                    _filterChip("Compétences: $filterSkills", () => setState(() => filterSkills = "")),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        filterTitre = "";
                        filterDomaine = "";
                        filterNiveau = "";
                        filterCity = "";
                        filterDuree = "";
                        filterSkills = "";
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16, color: Colors.red),
                    label: const Text("Effacer tout", style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Text(
            "Toutes les offres",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),
            //  LIST
            // LIST

Expanded(
  child: ListView.builder(
    itemCount: activeStages.length,
itemBuilder: (context, index) {
  final s = activeStages[index];
     return GestureDetector(
  onTap: () {
  Navigator.pushNamed(
    context,
    '/stage-detail',
    arguments: s,
  );
},
  child: Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1A3C8F).withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3C8F).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: s["companyPhoto"] != null && s["companyPhoto"].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "${ApiService.baseUrl}/uploads/${s["companyPhoto"]}",
                        fit: BoxFit.cover))
                  : const Icon(Icons.business_rounded,
                      color: Color(0xFF1A3C8F), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s["titre"] ?? "",
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B4B)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s["companyName"] ?? "",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Color(0xFF94A3B8)),
          ],
        ),

        const SizedBox(height: 12),

        // BADGE ROW (domaine + ville)
        Row(
          children: [
            _badge(Icons.work_outline_rounded, s["domaine"] ?? ""),
            const SizedBox(width: 8),
            _badge(Icons.location_on_outlined, s["city"] ?? ""),
          ],
        ),

        const SizedBox(height: 10),

        // INFO ROW 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _info("Durée", s["duree"] ?? ""),
            _info("Niveau", s["niveau"] ?? ""),
            _info("Places", "${s["places"] ?? ""}"),
          ],
        ),

        // TYPE DE STAGE + RÉMUNÉRATION
        if ((s["typeStage"] ?? '').toString().isNotEmpty ||
            (s["remuneration"] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if ((s["typeStage"] ?? '').toString().isNotEmpty)
                _badge(
                  s["typeStage"] == "En ligne"
                      ? Icons.laptop_rounded
                      : Icons.business_center_rounded,
                  s["typeStage"],
                ),
              if ((s["typeStage"] ?? '').toString().isNotEmpty &&
                  (s["remuneration"] ?? '').toString().isNotEmpty)
                const SizedBox(width: 8),
              if ((s["remuneration"] ?? '').toString().isNotEmpty)
                _badge(Icons.payments_rounded, "${s["remuneration"]} DT/mois"),
            ],
          ),
        ],

        const SizedBox(height: 10),

        // SKILLS
        if ((s["skills"] ?? s["competence"] ?? []).isNotEmpty)
          Text(
            "Compétences : ${(s["skills"] ?? s["competence"] ?? []).join(', ')}",
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
  ),
  ),
  );
    },
    
  ),
),
          ],
        ),
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
  currentIndex: currentIndex,
onTap: (index) {
  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RapportPage()),
    );
    return;
  }

  if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DemandeStagePage()),
    );
    return;
  }

  if (index == 3) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesDemandesPage(),
      ),);
  }

  if (index == 4) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConversationsPage()),
    );
    return;
  }

  setState(() {
    currentIndex = index;
  });
},
  selectedItemColor: const Color(0xFF1A3C8F),
  unselectedItemColor: Colors.grey,
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
  unselectedLabelStyle: const TextStyle(fontSize: 11),
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.white,
  elevation: 12,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_rounded),
      label: "Accueil",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      label: "Rapport",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.send_rounded),
      label: "Demandes",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment_turned_in_outlined),
      label: "Mes demandes",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      label: "Messages",
    ),
  ],
),
);
    
    
  }
  Widget cell(dynamic v) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: Text(
      v?.toString() ?? "-",
      style: const TextStyle(fontSize: 11),
    ),
  );
}

  Widget _badge(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blue),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}

Widget _info(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

  //  CARD WIDGETS
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Bonjour";
    if (hour < 18) return "Bon après-midi";
    return "Bonsoir";
  }

  Widget _quickCard(IconData icon, String label, Color color, Color bg, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCardCustom({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallCard(IconData icon, String title, Color color, String route) {
  return Expanded(
    child: GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget homePage() {
  return Container(
    color: const Color.fromARGB(255, 232, 230, 226),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 10),

          Row(
            children: [
              _smallCard(Icons.work, "Offres", Colors.blue, '/stages'),
              _smallCard(Icons.book, "Journal", Colors.indigo, '/journal'),
_smallCard(Icons.slideshow, "Présentations", Colors.orange, '/presentations'),
              Expanded(
  child: GestureDetector(
    onTap: () {
      setState(() {
        currentIndex = 3;
      });
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
      ),
      child: Column(
        children: const [
          Icon(Icons.assignment_turned_in, color: Colors.purple, size: 22),
          SizedBox(height: 6),
          Text("Mes demandes", textAlign: TextAlign.center),
        ],
      ),
    ),
  ),
),
             
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            "Toutes les offres",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: activeStages.length,
              itemBuilder: (context, index) {
                final s = activeStages[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(s["titre"] ?? ""),
                    subtitle: Text(s["companyName"] ?? ""),
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
Widget _getPage(int index) {
  switch (index) {
    case 0:
      return homePage();
    case 1:
      return   RapportPage(); 
case 2:
return DemandeStagePage();
     case 3:
  return MesDemandesPage();
    default:
      return homePage();
  }
}

Widget rapportPage() {
  return const Center(child: Text("📄 RAPPORT PAGE"));
}
Widget demandePage() {
  return const Center(child: Text("📩 DEMANDES PAGE"));
}
Widget profilePage() {
  return const Center(child: Text("👤 PROFILE PAGE"));
}

  bool get hasActiveFilters =>
      filterTitre.isNotEmpty ||
      filterDomaine.isNotEmpty ||
      filterNiveau.isNotEmpty ||
      filterCity.isNotEmpty ||
      filterDuree.isNotEmpty ||
      filterSkills.isNotEmpty;

  void showAdvancedFilters() {
    final titleCtrl = TextEditingController(text: filterTitre);
    final domainCtrl = TextEditingController(text: filterDomaine);
    final dureeCtrl = TextEditingController(text: filterDuree);
    final skillsCtrl = TextEditingController(text: filterSkills);

    String? selectedCity = filterCity.isEmpty ? null : filterCity;
    String? selectedLevel = filterNiveau.isEmpty ? null : filterNiveau;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recherche Avancée",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            titleCtrl.clear();
                            domainCtrl.clear();
                            dureeCtrl.clear();
                            skillsCtrl.clear();
                            setSheetState(() {
                              selectedCity = null;
                              selectedLevel = null;
                            });
                          },
                          child: const Text("Réinitialiser"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Filtrez les offres de stages selon vos besoins spécifiques.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    
                    _filterField("Titre du stage", titleCtrl, Icons.title),
                    _filterField("Domaine / Spécialité", domainCtrl, Icons.work),

                    // Dropdown for Niveau d'étude
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        value: selectedLevel,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: "Niveau d'étude",
                          labelStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(Icons.school, color: Color(0xFF0A1F44), size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0A1F44), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text("Tous les niveaux", style: TextStyle(color: Colors.grey)),
                          ),
                          ...availableLevels.map((l) => DropdownMenuItem<String>(
                            value: l,
                            child: Text(l),
                          )),
                        ],
                        onChanged: (val) {
                          setSheetState(() {
                            selectedLevel = val;
                          });
                        },
                      ),
                    ),

                    // Dropdown for Ville (City)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        value: selectedCity,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: "Ville (City)",
                          labelStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF0A1F44), size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0A1F44), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text("Toutes les villes", style: TextStyle(color: Colors.grey)),
                          ),
                          ...availableCities.map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          )),
                        ],
                        onChanged: (val) {
                          setSheetState(() {
                            selectedCity = val;
                          });
                        },
                      ),
                    ),

                    _filterField("Durée (ex: 3 mois)", dureeCtrl, Icons.timelapse),
                    _filterField("Compétences (ex: flutter)", skillsCtrl, Icons.star),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            filterTitre = titleCtrl.text;
                            filterDomaine = domainCtrl.text;
                            filterNiveau = selectedLevel ?? "";
                            filterCity = selectedCity ?? "";
                            filterDuree = dureeCtrl.text;
                            filterSkills = skillsCtrl.text;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A1F44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Appliquer les filtres",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0A1F44), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0A1F44), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
        backgroundColor: const Color(0xFF0A1F44),
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
        onDeleted: onDeleted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}


class MesDemandesPage extends StatefulWidget {
  @override
  State<MesDemandesPage> createState() => _MesDemandesPageState();
}

class _MesDemandesPageState extends State<MesDemandesPage> {
List applications = [];

  final api = ApiService();
String formatStatus(String status) {
  switch (status) {
    case "pending":
      return "en attente";
    case "accepted":
      return "accepté";
    case "refused":
      return "refusé";
    default:
      return "en attente";
  }
}
  @override
  void initState() {
    super.initState();
    load();
  }

Future load() async {
  try {
    final token = await api.storage.read(key: "token");

    final res = await http.get(
      Uri.parse('${Config.baseUrl}/applications/me'),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    print("STATUS => ${res.statusCode}");
    print("BODY => ${res.body}");

    if (res.statusCode == 200) {
      setState(() {
        applications = jsonDecode(res.body) as List;
      });
    }
  } catch (e) {
    print("LOAD ERROR => $e");
  }
}
 @override
Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: const Color(0xFF0A1F44), // 🔵 bleu

  appBar: AppBar(
    title: const Text("Mes demandes"),
    backgroundColor: const Color(0xFF0A1F44),
    elevation: 0,
  ),

  body: Container(
    padding: const EdgeInsets.only(top: 10), //
    decoration: const BoxDecoration(
      color: Color(0xFF0A1F44),
    ),

    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),

      child: RefreshIndicator(
        onRefresh: load,

        child: applications.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Aucune demande",
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Vos candidatures apparaîtront ici après avoir postulé.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: applications.length,
                itemBuilder: (context, i) {
                  final app = applications[i];

                  final stage = app["stage"] ?? app["offre"] ?? {};
                  final String companyEmail = (stage["companyEmail"] ?? app["companyEmail"] ?? "Email inconnu").toString();
                  final String titre = (stage["titre"] ?? "Sans titre").toString();
                  final String duree = (stage["duree"] ?? app["duree"] ?? "-").toString();
                  final statusRaw = (app["status"] ?? "pending").toString().toLowerCase();

                  final encadrant = (stage["invitations"] is List &&
                          stage["invitations"].isNotEmpty &&
                          stage["invitations"][0]["encadrant"] != null)
                      ? stage["invitations"][0]["encadrant"]
                      : null;

                  Color statusColor;
                  String statusText;
                  switch (statusRaw) {
                    case "accepted":
                      statusColor = Colors.green;
                      statusText = "Accepté";
                      break;
                    case "refused":
                      statusColor = Colors.red;
                      statusText = "Refusé";
                      break;
                    case "signed_by_company":
                      statusColor = Colors.blue;
                      statusText = "Signé Ent.";
                      break;
                    case "fully_signed":
                      statusColor = Colors.teal;
                      statusText = "Validé & Signé";
                      break;
                    default:
                      statusColor = Colors.orange;
                      statusText = "En attente";
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.business, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  companyEmail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            titre,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1F44),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                "Durée: $duree",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (app["typeStage"] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A1F44).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    app["typeStage"].toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF0A1F44),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (statusRaw == "accepted" && encadrant != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_pin, size: 16, color: Color(0xFF002366)),
                                const SizedBox(width: 6),
                                Text(
                                  "Encadrant: ${encadrant["nomComplet"] ?? "Aucun nom"}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002366),
                                  ),
                                ),
                              ],
                            ),
                            if (encadrant["email"] != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 22, top: 2),
                                child: Text(
                                  "Email: ${encadrant["email"]}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    ),
  ),
);}}