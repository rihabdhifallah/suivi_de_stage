import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/company_profile.dart';
import 'package:frontend/screens/offre_page.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final storage = const FlutterSecureStorage();

  String name = "";
  String email = "";

  List tasks = [];
List<Map<String, dynamic>> offres = [];
  bool loading = true;
  int index = 0;

  final String baseUrl = "http://192.168.100.30:3001";

  @override
  void initState() {
    super.initState();
    loadData();
 loadOffres();
  }

  // ================= LOAD =================
  Future<void> loadData() async {
    setState(() => loading = true);

    name = await storage.read(key: "name") ?? "";
    email = await storage.read(key: "email") ?? "";

  print("COMPANY NAME => $name"); // 

    if (email.trim().isEmpty) {
      print(" EMAIL EMPTY");
      setState(() => loading = false);
      return;
    }

    await loadTasks();

    setState(() => loading = false);
  }
  Future<void> loadOffres() async {
  final email = await storage.read(key: "email");
  final data = await ApiService().getOffres(email!);

  setState(() {
    offres = List<Map<String, dynamic>>.from(data);
  });
}

  // ================= LOAD TASKS =================
  Future<void> loadTasks() async {
    try {
final res = await http.get(
  Uri.parse('$baseUrl/tasks/receiver/${email.trim().toLowerCase()}'),
);

      print("RAW RESPONSE => ${res.body}");

      if (res.statusCode != 200) return;

      final List data = jsonDecode(res.body);

      print("ALL TASKS => $data");

     final myEmail = email.trim().toLowerCase();

final filtered = data.where((t) {
  final receiver = (t['receiver'] ?? "")
      .toString()
      .trim()
      .toLowerCase();

  return receiver == myEmail;
}).toList();
      setState(() {
        tasks = filtered;
      });
    } catch (e) {
      print("ERROR => $e");
    }
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatus(int id, String status) async {
    print("TASK ID => $id");
    print("NEW STATUS => $status");

    final res = await http.patch(
      Uri.parse('$baseUrl/tasks/$id/status'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );

    print("UPDATE RESPONSE => ${res.body}");

    await loadTasks();
  }

  // ================= LOGOUT =================
  void logout() async {
    await storage.deleteAll();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  // ================= ACCUEIL =================
Widget accueil() {
final activeOffres =
    offres.where((o) => o['active'] == true).toList();
      return SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ================= STATS =================
       SizedBox(
  height: 100,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
statCard(
  "Offres",
  offres.length.toString(),
  Icons.work,
),    
statCard(
  "Actives",
  activeOffres.length.toString(),
  Icons.check_circle,
),  statCard("Candidats", "", Icons.people),
      statCard("Conventions", "", Icons.description),
      statCard("Stagiaires", "", Icons.school),
    ],
  ),
),
        const SizedBox(height: 20),

        // ================= ACTIONS =================
        const Text(
          "Actions rapides",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        SizedBox(
  height: 100,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
      actionCard("Publier Offre", Icons.add_business),
      actionCard("Convention", Icons.description),
      actionCard("Candidats", Icons.people),
      actionCard("Stagiaires", Icons.school),
    ],
  ),
),

        const SizedBox(height: 20),

        // ================= OFFRES =================
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Offres actives",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),

    TextButton(
      onPressed: () {
        setState(() {
          index = 3; 
        });
      },
      child: const Text(
        "Voir plus",
        style: TextStyle(color: Color.fromARGB(255, 40, 85, 169)),
      ),
    ),
  ],
),

        const SizedBox(height: 10),
Column(
  children: activeOffres.isEmpty
      ? [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text("Aucune offre active"),
          ),
        ]
      : activeOffres.map((o) {
          return Container(
  width: double.infinity,
  margin: const EdgeInsets.only(bottom: 14),
  padding: const EdgeInsets.all(16), // 
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18), // 
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ],
  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

               Text(
  o['titre'],
  style: const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: Color(0xFF002366),
  ),
),
                 

                const SizedBox(height: 8),

                Text("Domaine: ${o['domaine']}"),
                Text("Durée: ${o['duree']}"),
                Text("Niveau: ${o['niveau']}"),
                Text("Places: ${o['places']}"),

                const SizedBox(height: 10),

               Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  ),
  decoration: BoxDecoration(
    color: Colors.green.withOpacity(0.15),
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Text(
    "Active",
    style: TextStyle(
      color: Colors.green,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
  ),
),
              ],
            ),
          );
        }).toList(),
),
       

        const SizedBox(height: 20),

        // ================= STAGIAIRES =================
        const Text(
          "Stagiaires",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text("Aucun stagiaire"),
        ),
      ],
    ),
  );
}
Widget statCard(String title, String count, IconData icon) {
  return Container(
    width: 90, 
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.all(10),
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
        Icon(icon, size: 20, color: Color(0xFF002366)),
        const SizedBox(height: 5),
        Text(
          count,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
Widget actionCard(String title, IconData icon) {
  return GestureDetector(
    onTap: () {

      if (title == "Publier Offre") {
        Navigator.pushNamed(context, '/offre-page');
      }

    },
    child: Container(
      width: 110,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF002366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Color(0xFF002366)),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
Widget smallCard(String title, IconData icon) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: Color(0xFF002366)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
  // ================= SERVICES =================
  Widget services() {
    if (tasks.isEmpty) {
      return const Center(child: Text("Aucune demande reçue"));
    }

    return ListView(
      children: tasks.map((t) {
        final status = t['status'];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(t['titre'] ?? ""),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Faculté: ${t['fac_name'] ?? ""}"),
                Text("Email: ${t['fac_email'] ?? ""}"),
                Text("Téléphone: ${t['fac_phone'] ?? ""}"),
                Text("Message: ${t['message'] ?? ""}"), // 
                
                Text("Status: $status"),
              ],
            ),

            trailing: status == "en attente"
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => updateStatus(t['id'], "accepté"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => updateStatus(t['id'], "refusé"),
                      ),
                    ],
                  )
                : Icon(
                    status == "accepté"
                        ? Icons.check_circle
                        : Icons.cancel,
                    color:
                        status == "accepté" ? Colors.green : Colors.red,
                  ),
          ),
        );
      }).toList(),
    );
  }

  // ================= BODY =================
Widget body() {
  switch (index) {
    case 0:
      return accueil();
    case 1:
      return services();
    case 2:
      return const OffresPage(); // 
    
    
    default:
      return accueil();
  }
}

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  backgroundColor: const Color(0xFF002366),
  toolbarHeight: 140,
  automaticallyImplyLeading: false,

  title: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white,
        child: Text(
          name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C",
          style: const TextStyle(
            color: Color(0xFF002366),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      const SizedBox(width: 12),

      //  TEXTS
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        

            const SizedBox(height: 2),

                        Text(
              "Bonjour, $name 👋",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 2),

            // DASHBOARD TITLE
            const Text(
              "Tableau de bord Entreprise",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 2),

            // DESCRIPTION
            const Text(
              "Gérez vos offres, stagiaires et conventions",
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    ],
  ),

  //  RIGHT ICONS
  actions: [

    //  SEARCH
    IconButton(
      icon: const Icon(Icons.search, color: Colors.white),
      onPressed: () {
        // search logic
      },
    ),

    //  PROFILE
IconButton(
  icon: const Icon(Icons.person, color: Colors.white),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyProfile(),
      ),
    );
  },
),

    //  LOGOUT
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: logout,
    ),
  ],
),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : body(),

      bottomNavigationBar: BottomNavigationBar(
  currentIndex: index,
onTap: (i) {
  if (i == 2) {
    Navigator.pushNamed(context, '/offre-page');
  } else {
    setState(() => index = i);
  }
},
  selectedItemColor: const Color(0xFF002366),
  unselectedItemColor: Colors.grey,

  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Services"),
    BottomNavigationBarItem(icon: Icon(Icons.work), label: "Offres"),
    BottomNavigationBarItem(icon: Icon(Icons.work), label: "Stages"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profiles"),
  ],
),
    );
  }

  Widget dashboardCard(String title, IconData icon, Color color) {
  return Container(
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
}