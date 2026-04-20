import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class CompanyProfile extends StatefulWidget {
  const CompanyProfile({super.key});

  @override
  State<CompanyProfile> createState() => _CompanyProfileState();
}

class _CompanyProfileState extends State<CompanyProfile> {
  final storage = const FlutterSecureStorage();
final api = ApiService();
  String name = "";
  String email = "";
  String phone = "";
  String country = "";
  
   String getInitials(String text) {
  if (text.trim().isEmpty) return "?";

  List parts = text.trim().split(" ");

  if (parts.length == 1) {
    return parts[0][0].toUpperCase();
  }

  return (parts[0][0] + parts[1][0]).toUpperCase();
}

  @override
void initState() {
  super.initState();
  loadProfile();
}

 Future loadProfile() async {
  final data = await api.getProfile();
  final storedName = await storage.read(key: "name");
  print("PROFILE DATA => $data");  

  setState(() {
    name = data["name"] ?? storedName ?? "";
    phone = data["phone"] ?? "";
    country = data["country"] ?? "";
    email = data["email"] ?? "";
  });
}
  void logout() async {
    await storage.deleteAll();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Widget infoTile(String title, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF002366)),
        title: Text(title),
        subtitle: Text(value.isNotEmpty ? value : "Non défini"),
      ),
    );
  }
Widget profile() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [

        // 👤 AVATAR
        CircleAvatar(
          radius: 40,
          backgroundColor: const Color(0xFF002366),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "C",
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),

        const SizedBox(height: 10),

        Text(name, style: const TextStyle(fontSize: 18)),
        Text(email, style: const TextStyle(color: Colors.grey)),

        const SizedBox(height: 20),

        // 🔥 BUTTON
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF002366),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompanyProfile(),
              ),
            );
          },
          child: const Text("Modifier le profil"),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Entreprise", style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF002366),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            //  Avatar
           CircleAvatar(
  radius: 40,
  backgroundColor: const Color(0xFF002366),
  child: Text(
  getInitials(name),
  style: const TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
  ),
),
),

            const SizedBox(height: 20),

            infoTile("Nom", name, Icons.business),
            infoTile("Email", email, Icons.email),
            infoTile("Téléphone", phone, Icons.phone),
            infoTile("Pays", country, Icons.location_on),

            const Spacer(),

            //  LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text("Se déconnecter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 208, 201, 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}