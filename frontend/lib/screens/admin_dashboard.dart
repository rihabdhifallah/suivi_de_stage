import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

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
  List tasks = [];

  bool loading = true;
  int index = 0;

 @override
void initState() {
  super.initState();
  loadData();

  // 🔥 AUTO refresh every 5 seconds
  Future.doWhile(() async {
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      await loadTasks();
    }
    return true;
  });
}
  // ================= LOAD =================
  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      users = await api.getUsers();
      companies = await api.getCompanies();
      filteredCompanies = companies;
      await loadTasks();
    } catch (e) {
      print(e);
    }

    setState(() => loading = false);
  }

  // ================= TASKS =================
  Future<void> loadTasks() async {
    final res = await http.get(Uri.parse('$baseUrl/tasks'));

    if (res.statusCode == 200) {
      tasks = jsonDecode(res.body);
      setState(() {});
    } else {
      print("ERROR loading tasks");
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
              await loadTasks();
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
Widget tasksView() {
  return ListView(
    children: tasks.map((t) {
      return ListTile(
        title: Text(t['titre'] ?? ""),
        subtitle: Text("${t['receiver']} - ${t['status']}"),
        trailing: Icon(
          t['status'] == "accepté"
              ? Icons.check
              : t['status'] == "refusé"
                  ? Icons.close
                  : Icons.hourglass_empty,
        ),
      );
    }).toList(),
  );
}
  // ================= USERS =================
 Widget usersView() {
  return ListView(
    children: users.map((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();

      Color roleColor;
      IconData roleIcon;

      if (role.contains('Etudiant')) {
        roleColor = Colors.blue;
        roleIcon = Icons.school;
      } else if (role.contains('Entrprise') || role.contains('entreprise')) {
        roleColor = Colors.green;
        roleIcon = Icons.business;
      } else {
        roleColor = Colors.grey;
        roleIcon = Icons.person;
      }

      return Card(
        child: ListTile(
          leading: Icon(Icons.person),

          title: Text(u['name'] ?? ''),

          subtitle: Row(
            children: [
              Text("${u['email']} • "),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(roleIcon, size: 14, color: roleColor),
                    const SizedBox(width: 4),
                    Text(
                      role,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

  // ================= COMPANIES =================
  Widget home() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            onChanged: filterCompanies,
            decoration: const InputDecoration(
              hintText: "Rechercher...",
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),

        ...filteredCompanies.map((c) => Card(
              child: ListTile(
                leading: const Icon(Icons.business),
                title: Text(c['name'] ?? ''),
                subtitle: Text(c['email'] ?? ''),
                trailing: ElevatedButton(
                  onPressed: () => contactCompany(c),
                  child: const Text("Contacter"),
                ),
              ),
            )),
      ],
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
        return tasksView();
      default:
        return home();
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  backgroundColor: const Color(0xFF002366),
  toolbarHeight: 95,

  title: Row(
    children: [

      // 🌟 LOGO
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.school, // 
          color: Color(0xFF002366),
        ),
      ),

      const SizedBox(width: 10),

      // TEXTS
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [

          Text(
            "StageTrack Admin",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 2),

          Text(
            "Bienvenue sur votre tableau de bord",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ],
  ),

  // 🌟 AVATAR ADMIN
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.person,
              color: Color(0xFF002366),
            ),
          ),

          const SizedBox(width: 10),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
    ),
  ],
),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : body(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          setState(() => index = i);
          if (i == 2) loadTasks();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Aceuill"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Utilisateurs"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Taches"),
        ],
      ),
    );
  }
}