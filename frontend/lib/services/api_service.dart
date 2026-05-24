import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  String? token;

  void setToken(String t) {
    token = t;
  }
static const String baseUrl = Config.baseUrl;
  final storage = const FlutterSecureStorage();


Future applyStage(int stageId) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
Uri.parse("$baseUrl/applications/apply/$stageId"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  return jsonDecode(res.body);
}
  // ================= AUTH =================
Future login({required String email, required String password}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "email": email.trim().toLowerCase(),
      "password": password,
    }),
  );

  print("STATUS = ${res.statusCode}");
  print("BODY = ${res.body}");

  final data = jsonDecode(res.body);

  if ((res.statusCode == 401 || res.statusCode == 400) && data is Map && data['message'] == 'Email incorrect') {
    print("Email incorrect on standard login, trying company login...");
    final resComp = await http.post(
      Uri.parse('$baseUrl/companies/login'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email.trim().toLowerCase(),
        "password": password,
      }),
    );
    print("COMPANY LOGIN STATUS = ${resComp.statusCode}");
    print("COMPANY LOGIN BODY = ${resComp.body}");
    return jsonDecode(resComp.body);
  }

  return data;
}


Future getProfile() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse('$baseUrl/auth/profile'),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to load profile");
  }

  return jsonDecode(res.body);
}


Future updateProfile(Map data) async {
  final token = await storage.read(key: "token");

  await http.patch(
    Uri.parse("$baseUrl/auth/profile"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(data),
  );
}

Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/auth/change-password"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "currentPassword": currentPassword,
      "newPassword": newPassword,
    }),
  );
  if (res.statusCode != 200) {
    final body = jsonDecode(res.body);
    throw Exception(body["message"] ?? "Erreur changement mot de passe");
  }
  return jsonDecode(res.body);
}


Future<List> getStudents() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("$baseUrl/auth/admin/students"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  return jsonDecode(res.body);
}

Future createStudent(Map<String, dynamic> body) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/auth/admin/create-student"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(body),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body);
}

Future createAcademique(Map<String, dynamic> body) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/auth/admin/create-academique"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(body),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body);
}



  Future signup({required Map<String, dynamic> body}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(res.body);
    }

    return jsonDecode(res.body);
  }

  Future signupAndLogin({required Map<String, dynamic> body}) async {
    await signup(body: body);
    return login(email: body['email'], password: body['password']);
  }

  // ================= USERS =================

Future<List> getUsers() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse('$baseUrl/users'),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  print("STATUS => ${res.statusCode}");
  print("BODY => ${res.body}");

  final data = jsonDecode(res.body);

  if (data is List) return data;
  if (data['data'] != null) return data['data'];

  return [];
}

  Future<List> getCompanies() async {
    final res = await http.get(Uri.parse('$baseUrl/users/companies'));
    return List.from(jsonDecode(res.body));
  }

  // ================= STAGES =================

  Future<List> getStages() async {
    final res = await http.get(Uri.parse('$baseUrl/stages'));
    final data = jsonDecode(res.body);

    if (data is List) return data;
    if (data['data'] != null) return data['data'];
    return [];
  }

  Future proposeStage(Map data) async {
    await http.post(
      Uri.parse('$baseUrl/stages/propose'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({...data, "status": "pending"}),
    );
  }


  Future deleteStage(int id) async {
    await http.delete(Uri.parse('$baseUrl/stages/$id'));
  }

  Future updateStage(int id, Map data) async {
    await http.patch(
      Uri.parse('$baseUrl/stages/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  // ================= CONVENTIONS =================

  Future sendConvention(Map data) async {
    await http.post(
      Uri.parse('$baseUrl/conventions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  Future<List> getConventions() async {
    final res = await http.get(Uri.parse('$baseUrl/conventions'));
    final data = jsonDecode(res.body);

    if (data is List) return data;
    if (data['data'] != null) return data['data'];
    return [];
  }

  Future updateConvention(int id, String status) async {
    await http.patch(
      Uri.parse('$baseUrl/conventions/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
  }

  Future publishConvention(int id) async {
    await http.patch(Uri.parse('$baseUrl/conventions/$id/publish'));
  }

  // ================= JOURNAL / RAPPORT =================

 

  Future sendRapport(Map body) async {
    await http.post(
      Uri.parse('$baseUrl/rapport'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  // ================= PDF =================

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

  // ================= NOTIFICATIONS =================

  Future sendNotification({
    required String email,
    required String message,
    required String pdfBase64, 
    int? taskId, // ✔ add this

  }) async {
    await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "message": message,
        "pdf": pdfBase64,
      }),
    );
  }

 Future<List> getNotifications(String email) async {
   final url = '$baseUrl/notifications/$email';
   print("GET NOTIF URL: $url");

   final res = await http.get(Uri.parse(url));

   print("STATUS: ${res.statusCode}");
   print("BODY: ${res.body}");

   return jsonDecode(res.body);
 }

  Future<List> getMyNotifications() async {
    final token = await storage.read(key: "token");

    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load notifications: ${res.body}");
    }

    return jsonDecode(res.body);
  }

  Future sendDashboardNotification({
    required int recipientId,
    required String title,
    required String message,
    String type = "comment",
  }) async {
    final token = await storage.read(key: "token");

    final res = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "recipientId": recipientId,
        "title": title,
        "message": message,
        "type": type,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to send notification: ${res.body}");
    }

    return jsonDecode(res.body);
  }

  Future markAsRead(int id) async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
    );
  }

  // ================= FORGOT PASSWORD =================

  Future<void> forgotPassword({required String email}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email}),
    );

    if (res.statusCode != 200) {
      throw Exception("Erreur reset password");
    }
  }
Future assignReportToEncadrant(int reportId, String email) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/rapports/share"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "rapportId": reportId,
      "email": email,
    }),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Share failed: ${res.body}");
  }

  return jsonDecode(res.body);
}
  // ================= COMPANY REQUESTS =================

  Future<List> getCompanyRequests() async {
    final token = await storage.read(key: "token");

    final response = await http.get(
      Uri.parse("$baseUrl/requests"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (data is List) return data;
    if (data['data'] != null) return data['data'];

    return [];
  }

 
 Future<List> getOffres(String email) async {
  final res = await http.get(
    Uri.parse("$baseUrl/offres/company/$email"),
  );

  final data = jsonDecode(res.body);

  if (data is List) return data;
  if (data['data'] != null) return data['data'];

  return [];
}



Future<List> searchCompanies(String query) async {
  final res = await http.get(
    Uri.parse("$baseUrl/organizations/search?q=$query"),
  );

  return jsonDecode(res.body);
}


Future sendToAdmin(Map data) async {
  final res = await http.post(
    Uri.parse('$baseUrl/tasks'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "titre": data['titre'],
      "domaine": data['domaine'],
      "duree": data['duree'],
      "niveau": data['niveau'],
      "places": data['places'],
      "sender": data['companyEmail'],
      "receiver": "admin",
      "status": "en attente"
    }),
  );

  return jsonDecode(res.body);
}

Future<void> sendOffreToAdmin(int offreId) async {
  final url = Uri.parse('$baseUrl/offres/send-to-admin/$offreId');

  final res = await http.post(url);

  if (res.statusCode != 200) {
    throw Exception("Erreur envoi offre admin");
  }
}
Future<List> searchOrganizations(String query) async {
  final res = await http.get(
    Uri.parse('$baseUrl/organizations/search?q=$query'),
  );

  if (res.statusCode != 200) {
    throw Exception("Search error");
  }

  return List.from(jsonDecode(res.body));
}

Future createOffre(Map data) async {
  final res = await http.post(
    Uri.parse('$baseUrl/offres'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body); 
}

Future<Map<String, dynamic>> checkPlaces(int stageId) async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/applications/check-places/$stageId"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to check places");
  }

  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future getMyApplications() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("${Config.baseUrl}/applications/me"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  print(res.body);

  return jsonDecode(res.body);
}




Future<List> getAdminOffres() async {
  final res = await http.get(
    Uri.parse("${Config.baseUrl}/offres/admin/all"),
  );

  if (res.statusCode != 200) {
    throw Exception("Erreur loading admin offres");
  }

  return jsonDecode(res.body);
}
Future updateActive(int id, bool active) async {
  final res = await http.patch(
    Uri.parse("${Config.baseUrl}/offres/$id/active"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"active": active}),
  );

  if (res.statusCode != 200) {
    throw Exception("Erreur update active");
  }

  return jsonDecode(res.body);
}
 Future createJournal(Map body, int stageId) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/journal/$stageId"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(body),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body);
}


Future<List> getJournal() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("$baseUrl/journal/me"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  final data = jsonDecode(res.body);

  print("RAW RESPONSE = $data");

  if (data is List) return data;

  if (data["data"] != null) return data["data"];

  if (data["journals"] != null) return data["journals"];

  return [];
}



Future getReports() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("$baseUrl/rapports/me"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );
  print("STATUS API = ${res.statusCode}");
  print("BODY API = ${res.body}");

  return jsonDecode(res.body);
}

Future sendJournal(Map body) async {
  final token = await storage.read(key: "token");

  print("TOKEN = $token"); // 

  final res = await http.post(
    Uri.parse("$baseUrl/journal"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(body),
  );
print("STATUS = ${res.statusCode}");
  print("BODY = ${res.body}");
  print(res.body);

  return jsonDecode(res.body);
}
Future<bool> deleteJournal(int id) async {
  final token = await storage.read(key: "token");

  final res = await http.delete(
    Uri.parse("$baseUrl/journal/$id"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (res.statusCode == 200 || res.statusCode == 204) {
    return true;
  } else {
    throw Exception("Delete failed: ${res.body}");
  }
}
Future updateJournal(int id, Map body) async {
  final token = await storage.read(key: "token");

  final res = await http.put(
    Uri.parse("$baseUrl/journal/$id"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(body),
  );

  if (res.statusCode != 200) {
    throw Exception("Update failed: ${res.body}");
  }

  return jsonDecode(res.body);
}

Future createReport(Map data, Uint8List pdfBytes) async {
  final token = await storage.read(key: "token");

  var request = http.MultipartRequest(
    'POST',
    Uri.parse("${Config.baseUrl}/rapports"),
  );

  request.headers.addAll({
    "Authorization": "Bearer $token",
  });

  request.files.add(
    http.MultipartFile.fromBytes(
      'pdf',
      pdfBytes,
      filename: 'report.pdf',
    ),
  );

  request.fields.addAll({
    'title': data['title'].toString(),
    'type': data['type'].toString(),
    'resume': data['resume'].toString(),
    'difficulty': data['difficulty']?.toString() ?? '',
    'company': data['company']?.toString() ?? '',
    'encadrant': data['encadrant']?.toString() ?? '',
    'periode': data['periode']?.toString() ?? '',
  });

  final response = await request.send();
  final body = await response.stream.bytesToString();

  print("STATUS = ${response.statusCode}");
  print("BODY = $body");

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Upload failed: $body");
  }

  final decoded = jsonDecode(body);

  return decoded;
}
Future shareReport(int rapportId, String email) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/rapports/share"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "rapportId": rapportId,
      "email": email,
    }),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Share failed");
  }

  return jsonDecode(res.body);
}
Future addComment(int id, String comment) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/rapports/$id/comment"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"comment": comment}),
  );

  if (res.statusCode != 200) {
    throw Exception("error");
  }

  return jsonDecode(res.body);
}

Future deleteReport(int id) async {
  final token = await storage.read(key: "token");

  await http.delete(
    Uri.parse("$baseUrl/rapports/$id"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );
}
Future<Map<String, dynamic>> getRapportById(int id) async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("${Config.baseUrl}/rapports/$id"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Erreur chargement rapport");
  }
}
 
Future reviewRapport(int id, Map data) async {
  final token = await storage.read(key: "token");

  final res = await http.patch(
    Uri.parse("$baseUrl/rapports/$id/review"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode(data),
  );

  print(res.body);

  return jsonDecode(res.body);
}
  // ================= GET DEMANDES =================
  Future getDemandes() async {
    final res = await http.get(Uri.parse('$baseUrl/demandes'));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Erreur chargement demandes");
    }
  }

  Future updateDemande(String id, Map data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/demandes/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(res.body);
  }
 Future updateDemandeStatus(int id, String status) async {
  final res = await http.put(
    Uri.parse('$baseUrl/demandes/$id/status'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"status": status}),
  );

  if (res.statusCode != 200) {
    throw Exception("Update failed");
  }

  return jsonDecode(res.body);
}
Future getEncadrantStats() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("${Config.baseUrl}/encadrant/stats"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  return jsonDecode(res.body);
}

Future getEncadrantRapports() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("${Config.baseUrl}/rapports/encadrant/me"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  print(res.body);

  return jsonDecode(res.body);
}

Future getMyEncadrements() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("$baseUrl/encadrements"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  return jsonDecode(res.body);
}

Future<Map<String, dynamic>> createEncadrement(Map data) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/encadrements"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(data),
  );

  print("CREATE STATUS => ${res.statusCode}");
  print("CREATE BODY => ${res.body}");

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future deleteEncadrement(int id) async {
  final token = await storage.read(key: "token");
  return await http.delete(
    Uri.parse("$baseUrl/encadrements/$id"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );
}

Future sendEncadrementMessage(int id) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/encadrements/$id/send"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  print("STATUS => ${res.statusCode}");
  print("BODY => ${res.body}");

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception("Send failed");
  }

  return res.body.isNotEmpty ? jsonDecode(res.body) : {};
}
Future<Map<String, String>> authHeader() async {
  final token = await storage.read(key: "token");

  if (token == null) {
    throw Exception("Not authenticated");
  }

  return {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };
}
Future getEncadrementsEncadrant() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("$baseUrl/encadrements/encadrant/my"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  return jsonDecode(res.body);
}
Future createDemande({
  required int studentId,
  required String titre,
  required String mission,
  required String specialite,
  required String duree,
  required String date,

  required String entreprise,
  required String secteur,
  required String adresse,
  required String tel,
  required String email,

  required String encadrant,
  required String poste,
  required String telEncadrant,
  required String emailEncadrant,

  required String skills,
  required String startDate,
  required String endDate,
  required String foundVia,

  required List<int> cvBytes,
  required String cvName,
  required List<int> lettreBytes,
  required String lettreName,
}) async {
  var request = http.MultipartRequest(
    "POST",
    Uri.parse("http://192.168.100.30:3001/demandes"),
  );

  request.fields['student_id'] = studentId.toString();
  request.fields['titre'] = titre;
  request.fields['mission'] = mission;
  request.fields['specialite'] = specialite;
  request.fields['duree'] = duree;
  request.fields['date'] = date;
  request.fields['entreprise'] = entreprise;
  request.fields['secteur'] = secteur;
  request.fields['adresse'] = adresse;
  request.fields['skills'] = skills;
  request.fields['tel_entreprise'] = tel;
request.fields['email_entreprise'] = email;
request.fields['encadrant_nom'] = encadrant;
request.fields['encadrant_poste'] = poste;
request.fields['encadrant_tel'] = telEncadrant;
request.fields['encadrant_email'] = emailEncadrant;
request.fields['date_debut'] = startDate;
request.fields['date_fin'] = endDate;
request.fields['found_via'] = foundVia;
  request.files.add(
    http.MultipartFile.fromBytes('cv', cvBytes, filename: cvName),
  );

  request.files.add(
    http.MultipartFile.fromBytes('lettre', lettreBytes, filename: lettreName),
  );

  var response = await request.send();

  if (response.statusCode != 201 && response.statusCode != 200) {
    throw Exception("Erreur envoi");
  }
}

 Future sendPresentation({
  required String titre,
  required String type,
  required DateTime date,
  required PlatformFile file,
}) async {

  final token = await storage.read(key: "token");

  var request = http.MultipartRequest(
    'POST',
    Uri.parse("$baseUrl/presentations"),
  );

  request.headers.addAll({
    "Authorization": "Bearer $token",
  });

  request.fields['titre'] = titre;
  request.fields['type'] = type;
  request.fields['date'] = date.toIso8601String();

  request.files.add(
    http.MultipartFile.fromBytes(
    'file',
    file.bytes!,
    filename: file.name,
  ),
);

  final response = await request.send();
  final body = await response.stream.bytesToString();

  print("STATUS = ${response.statusCode}");
  print("BODY = $body");

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception(body);
  }

  return jsonDecode(body);
}

Future<List> getMyPresentations() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("$baseUrl/presentations/my"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    if (data is List) return data;
    if (data["data"] != null) return data["data"];

    return [];
  } else {
    throw Exception("Failed to load presentations");
  }
}

Future reviewPresentation(dynamic id, {String? status, String? comment}) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/presentations/$id/review"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      if (status != null) "status": status,
      if (comment != null) "comment": comment,
    }),
  );
  if (res.statusCode != 200) {
    throw Exception("Erreur review presentation: ${res.body}");
  }
  return jsonDecode(res.body);
}

Future deleteOffre(int id) async {
  final token = await storage.read(key: "token");

  final res = await http.delete(
    Uri.parse("${Config.baseUrl}/offres/$id"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (res.statusCode != 200 && res.statusCode != 204) {
    throw Exception("Delete failed");
  }
}
Future updateOffre(int id, Map data) async {
  final token = await storage.read(key: "token");

  final res = await http.patch(
    Uri.parse("${Config.baseUrl}/offres/$id"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(data),
  );

  if (res.statusCode != 200) {
    throw Exception("Update failed");
  }
}

Future updateStatus(int id, bool active) async {
  final token = await storage.read(key: "token");

  final res = await http.patch(
    Uri.parse("${Config.baseUrl}/offres/$id/status"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"active": active}),
  );

  if (res.statusCode != 200) {
    throw Exception("Status update failed");
  }
}

Future<Map<String, dynamic>> createEncadrant(Map data) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("$baseUrl/encadrants"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(data),
  );

  final body = jsonDecode(res.body);

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Create encadrant failed: $body");
  }

  return body;
}

Future<List<dynamic>> getEncadrantsByCompany(String companyId) async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("${Config.baseUrl}/encadrants/company/$companyId"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  final data = jsonDecode(res.body);

  if (data is List) return data;

  if (data is Map) {
    if (data['data'] is List) return data['data'];
    if (data['encadrants'] is List) return data['encadrants'];
  }

  return [];
}

Future<List<dynamic>> getEncadrantsProfessionnelsByCompany(dynamic companyId) async {
  return getEncadrantsByCompany(companyId.toString());
}

Future<void> deleteEncadrantProfessionnel(dynamic id) async {
  final token = await storage.read(key: "token");
  final res = await http.delete(
    Uri.parse("$baseUrl/encadrants/$id"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );
  if (res.statusCode != 200 && res.statusCode != 204) {
    throw Exception("Delete encadrant failed");
  }
}

Future inviteEncadrant(int encadrantId, int offreId) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse("${Config.baseUrl}/invitations/invite"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "encadrantId": encadrantId,
      "offreId": offreId,
    }),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body);
}
Future getInvitationsByOffre(int id) async {
  final res = await http.get(
    Uri.parse("${Config.baseUrl}/invitations/offre/$id"),
  );

  return jsonDecode(res.body);
}

Future<bool> checkEmailAvailable(String email) async {
  final res = await http.get(
    Uri.parse("$baseUrl/auth/check-email?email=${Uri.encodeComponent(email)}"),
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body)['available'] == true;
  }
  return true; // fail open
}

Future<List> getSpecialitesByDepartement(int departementId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/specialites/by-departement/$departementId"),
  );
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    if (data is List) return data;
  }
  return [];
}

Future<List> getEncadrantInvitations() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("${Config.baseUrl}/offres/invitations/me"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  final data = jsonDecode(res.body);

  if (data is List) return data;
  if (data["data"] != null) return data["data"];

  return [];
}

// --- ADMIN USER MANAGEMENT ----------------------------------------------------

Future<List> getAcademiques() async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/auth/admin/academiques"),
    headers: {"Authorization": "Bearer $token"},
  );
  final data = jsonDecode(res.body);
  if (data is List) return data;
  return [];
}

Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> body) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/auth/admin/users/$id"),
    headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
    body: jsonEncode(body),
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Update failed: ${res.body}");
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<String> archiveUser(int id) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/auth/admin/users/$id/archive"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Archive failed");
  return (jsonDecode(res.body) as Map<String, dynamic>)['status'] as String;
}

// ── Encadrants professionnels (admin) ──
Future<List> getEncadrantsPro() async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/auth/admin/encadrants-pro"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Get encadrants pro failed");
  return jsonDecode(res.body) as List;
}

Future<List> getStagiairesForEncadrantPro() async {
  final token = await storage.read(key: "token");
  final email = await storage.read(key: "email") ?? '';
  final res = await http.get(
    Uri.parse("$baseUrl/applications/encadrant/${Uri.encodeComponent(email)}"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Get stagiaires failed");
  return jsonDecode(res.body) as List;
}

Future<String> archiveEncadrantPro(int id) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/auth/admin/encadrants-pro/$id/archive"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Archive encadrant pro failed");
  return (jsonDecode(res.body) as Map<String, dynamic>)['status'] as String;
}

Future<void> updateEncadrantPro(int id, Map<String, dynamic> data) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/encadrants/$id"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(data),
  );
  if (res.statusCode != 200) throw Exception("Update encadrant pro failed");
}

Future<List> getCompanies2() async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/companies"),
    headers: {"Authorization": "Bearer $token"},
  );
  final data = jsonDecode(res.body);
  if (data is List) return data;
  return [];
}

Future getCompanyById(int id) async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/companies/$id"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) {
    throw Exception("Get company failed: ${res.body}");
  }
  return jsonDecode(res.body);
}

Future updateCompany(int id, Map<String, dynamic> body) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/companies/$id"),
    headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
    body: jsonEncode(body),
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Update failed: ${res.body}");
  }
  return jsonDecode(res.body);
}

Future archiveCompany(int id) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse("$baseUrl/companies/$id/archive"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Archive failed");
  return jsonDecode(res.body);
}

Future<List> getTasksByReceiver(String email) async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse('$baseUrl/tasks/receiver/$email'),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Erreur get tasks by receiver");
  return List.from(jsonDecode(res.body));
}

Future<List> getTasksBySender(String email) async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse('$baseUrl/tasks/sender/$email'),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Erreur get tasks by sender");
  return List.from(jsonDecode(res.body));
}

Future createTask(Map<String, dynamic> data) async {
  final token = await storage.read(key: "token");
  final res = await http.post(
    Uri.parse('$baseUrl/tasks'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(data),
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Erreur create task");
  }
  return jsonDecode(res.body);
}

Future updateTaskStatus(dynamic id, String status, {String? comment}) async {
  final token = await storage.read(key: "token");
  final res = await http.patch(
    Uri.parse('$baseUrl/tasks/$id/status'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "status": status,
      if (comment != null) "comment": comment,
    }),
  );
  if (res.statusCode != 200) {
    throw Exception("Erreur update task status");
  }
  return jsonDecode(res.body);
}

Future<List> getReunions() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse('$baseUrl/reunions'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to load reunions: ${res.body}");
  }

  return jsonDecode(res.body);
}

Future<Map<String, dynamic>> createReunion(Map<String, dynamic> body) async {
  final token = await storage.read(key: "token");

  final res = await http.post(
    Uri.parse('$baseUrl/reunions'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(body),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Failed to create reunion: ${res.body}");
  }

  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future getStudentEncadrements() async {
  final token = await storage.read(key: "token");

  final res = await http.get(
    Uri.parse("$baseUrl/encadrements/my"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to load student encadrements: ${res.body}");
  }

  return jsonDecode(res.body);
}

// ── MESSAGES / CHAT ──────────────────────────────────────────────────────────

Future<List> getConversation(String otherEmail) async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/messages/conversation/${Uri.encodeComponent(otherEmail)}"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Get conversation failed");
  final data = jsonDecode(res.body);
  if (data is List) return data;
  return [];
}

Future<Map<String, dynamic>> sendMessage(String receiverEmail, String content) async {
  final token = await storage.read(key: "token");
  final res = await http.post(
    Uri.parse("$baseUrl/messages/send"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"receiverEmail": receiverEmail, "content": content}),
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Send message failed");
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<List> getConversationList() async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/messages/conversations"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) throw Exception("Get conversations failed");
  final data = jsonDecode(res.body);
  if (data is List) return data;
  return [];
}

Future<int> getUnreadMessagesCount() async {
  final token = await storage.read(key: "token");
  final res = await http.get(
    Uri.parse("$baseUrl/messages/unread-count"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) return 0;
  final data = jsonDecode(res.body);
  return (data is int) ? data : (data['count'] ?? 0);
}
}