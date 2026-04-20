import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.100.30:3001';
  final storage = const FlutterSecureStorage();

  // ================= AUTH =================

  Future login({required String email, required String password}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {"email": email, "password": password},
  );

  final data = jsonDecode(res.body);

  await storage.write(key: "token", value: data["access_token"]);
  await storage.write(key: "role", value: data["role"]);
  await storage.write(key: "name", value: data["name"]);
  await storage.write(key: "email", value: email);
await storage.write(key: "phone", value: data["phone"] ?? "");
await storage.write(key: "country", value: data["country"] ?? "");
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
Future changePassword(String oldPass, String newPass) async {
  final token = await storage.read(key: "token");

  await http.patch(
    Uri.parse("$baseUrl/auth/change-password"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "oldPassword": oldPass,
      "newPassword": newPass,
    }),
  );
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
    final res = await http.get(Uri.parse('$baseUrl/users'));
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

  Future applyStage(int id) async {
    await http.post(Uri.parse('$baseUrl/stages/$id/apply'));
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

  Future sendJournal(Map body) async {
    await http.post(
      Uri.parse('$baseUrl/journal'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

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

 Future createOffre(Map data) async {
  final res = await http.post(
    Uri.parse("$baseUrl/offres"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Erreur création offre");
  }

  return jsonDecode(res.body);
}

Future<List> getOffres(String email) async {
  final res = await http.get(
    Uri.parse("$baseUrl/offres/$email"),
  );

  if (res.statusCode != 200) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body);
}


Future updateOffre(int id, Map data) async {
  final res = await http.patch(
    Uri.parse("$baseUrl/offres/$id"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  if (res.statusCode != 200) {
    throw Exception("Erreur update offre");
  }

  return jsonDecode(res.body);
}


Future updateStatus(int id, bool active) async {
  final res = await http.patch(
    Uri.parse("$baseUrl/offres/$id/status"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"active": active}),
  );

  if (res.statusCode != 200) {
    throw Exception("Erreur status offre");
  }

  return jsonDecode(res.body);
}





}
