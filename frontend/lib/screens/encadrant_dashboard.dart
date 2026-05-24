import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/screens/rapports/rapport_detail_page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class EncadrantDashboard extends StatefulWidget {
  const EncadrantDashboard({super.key});

  @override
  State<EncadrantDashboard> createState() => _EncadrantDashboardState();
}

class _EncadrantDashboardState extends State<EncadrantDashboard> {
  final api = ApiService();

  String name = "";
  String etablissement = "";
  String specialite = "";
  String email = "";

  String view = "home";

  int nbEtudiants = 0;
  int nbRapports = 0;
  int nbEncadrements = 0;
  List encadrements = [];
  List rapports = [];
  List presentationsList = [];
  List notifications = [];
  List invitations = [];
  int invitationsCount = 0;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadStats();
    loadRapports();
    loadEncadrementsEncadrant();
    loadInvitations();
  }
 Color _statusColor(String? status) {
  switch (status) {
    case "valide":
      return Colors.green;

    case "refuse":
      return Colors.red;

    case "revision":
      return Colors.blue;

    case "en_attente":
      return Colors.orange;

    default:
      return Colors.orange;
  }
}

String _statusText(String? status) {
  switch (status) {
    case "valide":
      return "Validé";

    case "refuse":
      return "Refusé";

    case "revision":
      return "Révision";

    case "en_attente":
      return "En attente";

    default:
      return "En attente";
  }
}
void showCommentDialog(int reportId) {
  final TextEditingController ctrl = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Commentaire"),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Écrire un commentaire...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),

          ElevatedButton(
            onPressed: () async {
              try {
                await api.reviewRapport(reportId, {
                  "commentaire": ctrl.text.trim(),
                });

                Navigator.pop(dialogContext);

                await loadRapports();

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Commentaire envoyé"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Erreur API"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Envoyer"),
          ),
        ],
      );
    },
  );
}
void showStatusDialog(
  int reportId,
  String currentStatus,
) {

  String status = currentStatus;

  showDialog(
    context: context,

    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) {

        return AlertDialog(

          title: const Text("Changer le statut"),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              RadioListTile(
                value: "valide",
                groupValue: status,
                title: const Text("Validé"),

                onChanged: (v) {
                  setStateDialog(() {
                    status = v!;
                  });
                },
              ),

              RadioListTile(
                value: "revision",
                groupValue: status,
                title: const Text("Révision"),

                onChanged: (v) {
                  setStateDialog(() {
                    status = v!;
                  });
                },
              ),

              RadioListTile(
                value: "en_attente",
                groupValue: status,
                title: const Text("En attente"),

                onChanged: (v) {
                  setStateDialog(() {
                    status = v!;
                  });
                },
              ),

              RadioListTile(
                value: "refuse",
                groupValue: status,
                title: const Text("Refusé"),

                onChanged: (v) {
                  setStateDialog(() {
                    status = v!;
                  });
                },
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Annuler"),
            ),

            ElevatedButton(
              onPressed: () async {

                await api.reviewRapport(
                  reportId,
                  {
                    "status": status,
                  },
                );

                Navigator.pop(context);

                await loadRapports();

                setState(() {});
              },

              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    ),
  );
}
 Future loadEncadrementsEncadrant() async {
  final token = await api.storage.read(key: "token");

  final res = await http.get(
    Uri.parse('${Config.baseUrl}/encadrements/encadrant/my'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    setState(() {
      encadrements = data;
    });
  } else {
    print("ERROR encadrements: ${res.body}");
  }
}

Future loadInvitations() async {
  try {
    final token = await api.storage.read(key: "token");
    final userId = await api.storage.read(key: "userId");
    if (userId == null) return;

    final res = await http.get(
      Uri.parse('${Config.baseUrl}/invitations/encadrant/$userId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        invitations = data is List ? data : [];
        invitationsCount = invitations.where((inv) => inv['status'] == 'pending').length;
      });
    }
  } catch (e) {
    print("ERROR invitations: $e");
  }
}
Future loadRapports() async {
  final data = await api.getEncadrantRapports();

  setState(() {
    rapports = data;
  });
}

Future loadPresentationsEncadrant() async {
  final token = await api.storage.read(key: "token");

  final res = await http.get(
    Uri.parse('${Config.baseUrl}/presentations/encadrant'),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    setState(() {
      presentationsList = data;
    });
  } else {
    print("ERROR presentations: ${res.body}");
  }
}
  // ================= PROFILE =================
  Future loadProfile() async {
    try {
      final data = await api.getProfile();

      setState(() {
        name = data["name"] ?? "";
        etablissement = data["etablissement"] ?? "";
        specialite = data["specialite"] ?? "";
        email = data["email"] ?? "";
      });

      await loadNotifications();
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  // ================= NOTIFICATIONS =================
  Future loadNotifications() async {
    try {
      // 1. Fetch reports
      final reportsData = await api.getEncadrantRapports();
      
      // 2. Fetch presentations
      final token = await api.storage.read(key: "token");
      final resPres = await http.get(
        Uri.parse('${Config.baseUrl}/presentations/encadrant'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      List presData = [];
      if (resPres.statusCode == 200) {
        presData = jsonDecode(resPres.body);
      }

      List tempNotifs = [];

      // Filter rapports en attente
      for (var r in reportsData) {
        if (r["status"] == "en_attente") {
          tempNotifs.add({
            "id": r["id"],
            "type": "rapport",
            "title": r["title"] ?? "Sans titre",
            "student": "${r["student"]?["name"] ?? ''} ${r["student"]?["prenom"] ?? ''}".trim(),
            "date": r["createdAt"] ?? "",
            "message": "Nouveau rapport à évaluer pour l'étudiant : ${r["student"]?["name"] ?? 'Étudiant'}",
            "raw": r,
          });
        }
      }

      // Filter presentations en attente
      for (var p in presData) {
        if (p["status"] == "en_attente") {
          tempNotifs.add({
            "id": p["id"],
            "type": "presentation",
            "title": p["titre"] ?? "Sans titre",
            "student": "${p["student"]?["name"] ?? ''} ${p["student"]?["prenom"] ?? ''}".trim(),
            "date": p["date"] ?? "",
            "message": "Nouvelle présentation à valider pour l'étudiant : ${p["student"]?["name"] ?? 'Étudiant'}",
            "raw": p,
          });
        }
      }

      // Sort notifications descending by date
      tempNotifs.sort((a, b) {
        String dateA = a["date"] ?? "";
        String dateB = b["date"] ?? "";
        return dateB.compareTo(dateA);
      });

      setState(() {
        notifications = tempNotifs;
        unreadCount = tempNotifs.length;
      });
    } catch (e) {
      print("Error loading notifications: $e");
    }
  }

  // ================= STATS =================
  Future loadStats() async {
    final data = await api.getEncadrantStats();

    setState(() {
      nbEtudiants = data["etudiants"] ?? 0;
      nbRapports = data["rapports"] ?? 0;
      nbEncadrements = data["encadrements"] ?? 0;
    });
  }

  // ================= NOTIFICATIONS BOTTOM SHEET =================
  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: Color(0xFF0A1F44), size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            "Actions en attente",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1F44),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Text(
                                "$unreadCount nouvelles",
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 20),
                  notifications.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          width: double.infinity,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF16A34A).withOpacity(0.08),
                                child: const Icon(Icons.done_all_rounded, color: Color(0xFF16A34A), size: 30),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Tout est à jour !",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Aucune tâche en attente de validation.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notif = notifications[index];
                              final isRapport = notif["type"] == "rapport";
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isRapport 
                                        ? Colors.blue.shade50 
                                        : Colors.purple.shade50,
                                    child: Icon(
                                      isRapport ? Icons.description_rounded : Icons.slideshow_rounded,
                                      color: isRapport ? Colors.blue.shade800 : Colors.purple.shade800,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif["student"] ?? "Étudiant",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF0A1F44),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (notif["date"].toString().isNotEmpty)
                                        Text(
                                          notif["date"].toString().substring(0, 10),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        notif["message"] ?? "",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Titre: ${notif["title"]}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (isRapport) {
                                      setState(() {
                                        view = "rapports";
                                      });
                                    } else {
                                      setState(() {
                                        view = "presentations";
                                      });
                                    }
                                  },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // ================= APPBAR =================
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge rôle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7DD3FC), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text("Encadrant Académique",
                  style: TextStyle(color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ]),
            ),
            const SizedBox(height: 4),
            Text(
              name.isNotEmpty ? "Dr. $name" : "Encadrant",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: -0.3),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            if (etablissement.isNotEmpty)
              Text(etablissement,
                style: const TextStyle(fontSize: 11, color: Color(0xFF93C5FD),
                  fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
                ),
                onPressed: _showNotificationsBottomSheet,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626), shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text("$unreadCount",
                      style: const TextStyle(color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () async {
              await api.storage.deleteAll();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ================= BODY =================
      body: view == "home"
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileCard(),
                  const SizedBox(height: 20),
                  actionsCard(),
                  const SizedBox(height: 16),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (view == "rapports") ...[
                    Expanded(child: buildRapports()),
                  ],
                  if (view == "encadrements") ...[
                    Expanded(child: buildEncadrements()),
                  ],
                  if (view == "presentations") ...[
                    Expanded(child: buildPresentations()),
                  ],
                  if (view == "invitations") ...[
                    Expanded(child: buildInvitations()),
                  ],
                ],
              ),
            ),
    );
  }

Widget buildEncadrements() {
  return Column(
    children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() => view = "home"),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0A1F44)),
            ),
            const Text(
              "Mes Étudiants",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1F44),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () async {
                await loadEncadrementsEncadrant();
              },
              icon: const Icon(Icons.refresh, color: Color(0xFF0A1F44)),
              tooltip: "Actualiser",
            ),
          ],
        ),
      ),
      Expanded(
        child: encadrements.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Aucun encadrement",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Vos attributions d'encadrement apparaîtront ici.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                itemCount: encadrements.length,
                itemBuilder: (context, i) {
                  final e = encadrements[i];
                  return _encadrementCard(e);
                },
              ),
      ),
    ],
  );
}

  Future<void> _makePhoneCall(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw "canLaunchUrl returned false";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible de lancer l'appel : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Suivi de stage - Contact Encadrant Académique',
      },
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw "canLaunchUrl returned false";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible de lancer le client e-mail : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDashboardMessageDialog(dynamic student) async {
    final TextEditingController msgCtrl = TextEditingController();
    bool loading = false;
    final studentId = student["id"];
    final studentName = "${student["name"] ?? ""} ${student["prenom"] ?? ""}".trim();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.dashboard_outlined, color: Color(0xFF0A1F44)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Message à $studentName",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A1F44)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ce message sera directement visible sur le tableau de bord de l'étudiant.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Saisissez votre message...",
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0A1F44), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final text = msgCtrl.text.trim();
                      if (text.isEmpty) return;

                      setD(() => loading = true);
                      try {
                        await api.sendDashboardNotification(
                          recipientId: studentId,
                          title: "Message de votre encadrant académique",
                          message: text,
                          type: "comment",
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Message envoyé avec succès au tableau de bord ! 🚀"),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        }
                      } catch (e) {
                        setD(() => loading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erreur lors de l'envoi : $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Envoyer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encadrementCard(dynamic e) {
    final studentName = "${e["student"]?["name"] ?? ''} ${e["student"]?["prenom"] ?? ''}".trim();
    final studentEmail = e["student"]?["email"] ?? "Non renseigné";
    final studentPhone = e["student"]?["phone"] ?? "";
    final annee = e["annee"] ?? "Non renseignée";
    final niveau = e["niveau"] ?? "Non renseigné";
    final specialite = e["specialite"] ?? "Non renseignée";
    final encadrantName = "${e["encadrant"]?["name"] ?? ''} ${e["encadrant"]?["prenom"] ?? ''}".trim();
    final encadrantEmail = e["encadrant"]?["email"] ?? "";
    
    // -------- card UI --------
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Accent bar ──
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF0A1F44),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF0A1F44).withOpacity(0.08),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : "E",
                        style: const TextStyle(
                          color: Color(0xFF0A1F44),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                studentName.isNotEmpty ? studentName : "Étudiant",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A1F44),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Academic Year chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Text(
                                  annee,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            studentEmail,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          if (studentPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              studentPhone,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Supervision details (Level & Speciality)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Niveau",
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            niveau,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
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
                            "Spécialité",
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialite,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Encadrant Info Section
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      "Encadrant: ",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      encadrantName.isNotEmpty ? encadrantName : "Non assigné",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    if (encadrantEmail.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        "($encadrantEmail)",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }
  // ================= PROFILE CARD =================
  Widget profileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A1F44), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A1F44).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty
                      ? (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase()
                      : "DR",
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dr. $name",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      etablissement,
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Text(
                  "Académique",
                  style: TextStyle(
                    color: Color(0xFF0369A1),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _statCard("Étudiants", nbEtudiants, Icons.people_rounded, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("Rapports", nbRapports, Icons.description_rounded, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _statCard("Mes Étudiants", nbEncadrements, Icons.school_rounded, Colors.indigo)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            "$value",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ================= ACTIONS =================
  Widget actionsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            "Espace de Travail",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1F44),
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _actionCard(
              icon: Icons.people_rounded,
              title: "Mes étudiants",
              subtitle: "Suivi individuel",
              color: Colors.blue.shade700,
              onTap: () async {
                await loadEncadrementsEncadrant();
                setState(() {
                  view = "encadrements";
                });
              },
            ),
            _actionCard(
              icon: Icons.description_rounded,
              title: "Rapports",
              subtitle: "Évaluation & Avis",
              color: Colors.teal.shade700,
              onTap: () async {
                final data = await api.getEncadrantRapports();
                setState(() {
                  rapports = data;
                  view = "rapports";
                });
              },
            ),
            _actionCard(
              icon: Icons.school_rounded,
              title: "Mes Étudiants",
              subtitle: "Fiches académiques",
              color: Colors.indigo.shade700,
              onTap: () async {
                await loadEncadrementsEncadrant();
                setState(() {
                  view = "encadrements";
                });
              },
            ),
            _actionCard(
              icon: Icons.event_rounded,
              title: "Réunions",
              subtitle: "Planifier & Joindre",
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.pushNamed(context, '/reunions');
              },
            ),
            _actionCard(
              icon: Icons.slideshow_rounded,
              title: "Présentations",
              subtitle: "Soutenances & Slides",
              color: Colors.purple.shade700,
              onTap: () async {
                await loadPresentationsEncadrant();
                setState(() {
                  view = "presentations";
                });
              },
            ),
            _actionCard(
              icon: Icons.mail_rounded,
              title: "Invitations",
              subtitle: "Offres de stage reçues",
              color: Colors.red.shade700,
              badge: invitationsCount,
              onTap: () async {
                await loadInvitations();
                setState(() {
                  view = "invitations";
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            "$badge",
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade300, size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= INVITATIONS =================
  Widget buildInvitations() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => view = "home"),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0A1F44)),
              ),
              const Text(
                "Mes Invitations",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async { await loadInvitations(); },
                icon: const Icon(Icons.refresh, color: Color(0xFF0A1F44)),
                tooltip: "Actualiser",
              ),
            ],
          ),
        ),
        Expanded(
          child: invitations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mail_outline_rounded, size: 64, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucune invitation",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Les invitations à encadrer des offres de stage apparaîtront ici.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  itemCount: invitations.length,
                  itemBuilder: (context, i) {
                    final inv = invitations[i];
                    return _invitationCard(inv);
                  },
                ),
        ),
      ],
    );
  }

  Widget _invitationCard(dynamic inv) {
    final offre = inv['offre'] ?? {};
    final status = inv['status'] ?? 'pending';
    final titre = offre['titre'] ?? 'Offre sans titre';
    final domaine = offre['domaine'] ?? '';
    final duree = offre['duree'] ?? '';
    final city = offre['city'] ?? '';
    final niveau = offre['niveau'] ?? '';
    final places = offre['places'] ?? 1;
    final dateDebut = offre['dateDebut'] ?? '';
    final dateFin = offre['dateFin'] ?? '';
    final skills = offre['skills'];
    final skillList = skills is List ? skills : (skills is String ? skills.split(',') : []);
    final companyName = offre['companyName'] ?? '';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusLabel = 'Acceptée';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'refused':
        statusColor = Colors.red;
        statusLabel = 'Refusée';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'En attente';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == 'pending' ? Colors.orange.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header gradient bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF002366).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work_rounded, color: Color(0xFF002366), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1F44),
                            ),
                          ),
                          if (companyName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              companyName,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Details chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (domaine.isNotEmpty) _invBadge(Icons.business_rounded, domaine, const Color(0xFF3B82F6)),
                    if (city.isNotEmpty) _invBadge(Icons.location_on_rounded, city, const Color(0xFF64748B)),
                    if (duree.isNotEmpty) _invBadge(Icons.schedule_rounded, duree, const Color(0xFF10B981)),
                    if (niveau.isNotEmpty) _invBadge(Icons.school_rounded, niveau, const Color(0xFF8B5CF6)),
                    _invBadge(Icons.people_rounded, '$places place${places > 1 ? "s" : ""}', const Color(0xFFF59E0B)),
                  ],
                ),

                if (dateDebut.isNotEmpty || dateFin.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'Période : $dateDebut  →  $dateFin',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],

                if (skillList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Compétences requises :',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skillList.map<Widget>((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF002366).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.toString().trim(),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF002366), fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ],

                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
                          label: const Text('Refuser', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            await _respondToInvitation(inv['id'], 'refused');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002366),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          label: const Text('Accepter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            await _respondToInvitation(inv['id'], 'accepted');
                          },
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
    );
  }

  Widget _invBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _respondToInvitation(dynamic invId, String newStatus) async {
    try {
      final token = await api.storage.read(key: "token");
      final res = await http.patch(
        Uri.parse('${Config.baseUrl}/invitations/$invId/status'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"status": newStatus}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        await loadInvitations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus == 'accepted' ? 'Invitation acceptée !' : 'Invitation refusée.'),
              backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        throw Exception(res.body);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // ================= RAPPORTS =================
// ================= RAPPORTS =================
Widget buildRapports() {
  return Column(
    children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() => view = "home"),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0A1F44)),
            ),
            const Text(
              "Rapports reçus",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1F44),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () async {
                await loadRapports();
              },
              icon: const Icon(Icons.refresh, color: Color(0xFF0A1F44)),
              tooltip: "Actualiser",
            ),
          ],
        ),
      ),
      Expanded(
        child: rapports.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.description_rounded, size: 64, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Aucun rapport reçu",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Les rapports soumis par vos étudiants apparaîtront ici.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                itemCount: rapports.length,
                itemBuilder: (context, i) {
                  final r = rapports[i];
                  return _rapportCard(r);
                },
              ),
      ),
    ],
  );
}

Widget _rapportCard(dynamic r) {
  final title = r["title"] ?? "Sans titre";
  final studentName = "${r["student"]?["name"] ?? ''} ${r["student"]?["prenom"] ?? ''}".trim();
  final studentEmail = r["student"]?["email"] ?? "";
  final date = r["createdAt"] ?? "";
  final status = r["status"] ?? "en_attente";
  final file = r["file"] ?? "";
  final type = r["type"] ?? "Rapport";
  final commentaire = r["commentaire"] ?? "";

  Color statusColor = _statusColor(status);
  String statusText = _statusText(status);

  IconData statusIcon;
  switch (status) {
    case "valide":
      statusIcon = Icons.check_circle;
      break;
    case "refuse":
      statusIcon = Icons.cancel;
      break;
    case "revision":
      statusIcon = Icons.refresh_rounded;
      break;
    default:
      statusIcon = Icons.schedule;
  }

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top accent bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student info
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0A1F44).withOpacity(0.08),
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : "E",
                      style: const TextStyle(
                        color: Color(0xFF0A1F44),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName.isNotEmpty ? studentName : "Étudiant",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                        if (studentEmail.isNotEmpty)
                          Text(
                            studentEmail,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),

              // Rapport Type badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F44).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1F44),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 5),
                  Text(
                    date.toString().length >= 10 ? date.toString().substring(0, 10) : date.toString(),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Comment display
              if (commentaire.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.comment_rounded, size: 13, color: Color(0xFFF97316)),
                          SizedBox(width: 5),
                          Text(
                            "Commentaire",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF97316),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        commentaire.toString(),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ],

              // File Download
              if (file.toString().isNotEmpty) ...[
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final url = "${Config.baseUrl}/uploads/rapports/$file";
                    try {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Impossible d'ouvrir: $e"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "Ouvrir PDF",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Actions buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentaireEncadrantPage(rapport: r),
                          ),
                        ).then((val) {
                          if (val != null) {
                            loadRapports();
                          }
                        });
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 15),
                      label: const Text("Commenter", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0A1F44),
                        side: const BorderSide(color: Color(0xFF0A1F44)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => showStatusDialog(r["id"], r["status"] ?? "en_attente"),
                      icon: const Icon(Icons.check_circle_outline, size: 15),
                      label: const Text("Statut", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1F44),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
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
}
  // ================= WIDGETS =================
  Widget _stat(String title, int value) {
    return Column(
      children: [
        Text("$value",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _action(IconData icon, String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: const Color(0xFF0A1F44)),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0A1F44),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPresentations() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => view = "home"),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0A1F44)),
              ),
              const Text(
                "Présentations reçues",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await loadPresentationsEncadrant();
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF0A1F44)),
                tooltip: "Actualiser",
              ),
            ],
          ),
        ),
        Expanded(
          child: presentationsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1F44).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.slideshow, size: 64, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucune présentation reçue",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Les présentations soumises par vos étudiants apparaîtront ici.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: presentationsList.length,
                  itemBuilder: (context, i) {
                    final p = presentationsList[i];
                    return _presentationEncadrantCard(p);
                  },
                ),
        ),
      ],
    );
  }

  Widget _presentationEncadrantCard(dynamic p) {
    final studentName = p["student"]?["name"] ?? "Étudiant";
    final studentEmail = p["student"]?["email"] ?? "";
    final title = p["titre"] ?? "Sans titre";
    final type = p["type"] ?? "Autre";
    final date = p["date"] ?? "";
    final file = p["file"] ?? "";
    final status = p["status"] ?? "en_attente";
    final existingComment = p["comment"] ?? "";

    final isPdf = file.toString().toLowerCase().endsWith(".pdf");
    final isPpt = file.toString().toLowerCase().endsWith(".ppt") ||
        file.toString().toLowerCase().endsWith(".pptx");

    String displayFileName = file;
    if (file.contains("-")) {
      final parts = file.split("-");
      if (parts.length > 1) displayFileName = parts.sublist(1).join("-");
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case "valide":
        statusColor = const Color(0xFF16A34A);
        statusText = "Validé";
        statusIcon = Icons.check_circle;
        break;
      case "refuse":
        statusColor = const Color(0xFFDC2626);
        statusText = "Refusé";
        statusIcon = Icons.cancel;
        break;
      case "revision":
        statusColor = const Color(0xFF2563EB);
        statusText = "En révision";
        statusIcon = Icons.refresh_rounded;
        break;
      default:
        statusColor = const Color(0xFFF97316);
        statusText = "En attente";
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top colored accent bar ───
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Student info + status ───
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF0A1F44).withOpacity(0.08),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : "E",
                        style: const TextStyle(
                          color: Color(0xFF0A1F44),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1F44),
                            ),
                          ),
                          if (studentEmail.isNotEmpty)
                            Text(
                              studentEmail,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // ─── Title + Type + Date ───
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1F44),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Text(
                      date.toString().length >= 10 ? date.toString().substring(0, 10) : date.toString(),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),

                // ─── Existing comment display ───
                if (existingComment.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.comment_rounded, size: 13, color: Color(0xFFF97316)),
                            SizedBox(width: 5),
                            Text(
                              "Commentaire",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          existingComment.toString(),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                ],

                // ─── File ───
                if (file.toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse("${Config.baseUrl}/uploads/$file");
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(url);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Impossible d'ouvrir: $e"), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isPdf
                            ? Colors.red.withOpacity(0.06)
                            : isPpt
                                ? Colors.orange.withOpacity(0.06)
                                : Colors.blue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPdf
                              ? Colors.red.withOpacity(0.2)
                              : isPpt
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf : isPpt ? Icons.slideshow : Icons.insert_drive_file,
                            color: isPdf ? Colors.red : isPpt ? Colors.orange : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayFileName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isPdf ? Colors.red.shade900 : isPpt ? Colors.orange.shade900 : Colors.blue.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            isPdf ? "Ouvrir PDF" : isPpt ? "Ouvrir PPT" : "Télécharger",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPdf ? Colors.red.shade700 : isPpt ? Colors.orange.shade700 : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // ─── Action buttons ───
                Row(
                  children: [
                    // Comment button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPresentationCommentDialog(p),
                        icon: const Icon(Icons.chat_bubble_outline, size: 15),
                        label: const Text("Commenter", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0A1F44),
                          side: const BorderSide(color: Color(0xFF0A1F44)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPresentationStatusDialog(p),
                        icon: const Icon(Icons.check_circle_outline, size: 15),
                        label: const Text("Statut", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A1F44),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
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
  }

  void _showPresentationCommentDialog(dynamic p) {
    final ctrl = TextEditingController(text: p["comment"] ?? "");
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.chat_bubble_outline, color: Color(0xFF0A1F44)),
              SizedBox(width: 8),
              Text("Commentaire encadrant", style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p["titre"] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1F44)),
              ),
              Text(
                "Étudiant : ${p["student"]?["name"] ?? ""}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Écrire votre commentaire...",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      setD(() => sending = true);
                      try {
                        await api.reviewPresentation(
                          p["id"],
                          status: p["status"] ?? "en_attente",
                          comment: ctrl.text.trim(),
                        );
                        await loadPresentationsEncadrant();
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Commentaire envoyé à l'étudiant ✅"),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        }
                      } catch (e) {
                        setD(() => sending = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Envoyer"),
            ),
          ],
        ),
      ),
    );
  }

  void _showPresentationStatusDialog(dynamic p) {
    String selectedStatus = p["status"] ?? "en_attente";
    bool sending = false;

    final statuses = [
      {"value": "valide", "label": "Validé", "icon": Icons.check_circle, "color": const Color(0xFF16A34A)},
      {"value": "revision", "label": "En révision", "icon": Icons.refresh_rounded, "color": const Color(0xFF2563EB)},
      {"value": "refuse", "label": "Refusé", "icon": Icons.cancel, "color": const Color(0xFFDC2626)},
      {"value": "en_attente", "label": "En attente", "icon": Icons.schedule, "color": const Color(0xFFF97316)},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF0A1F44)),
              SizedBox(width: 8),
              Text("Changer le statut", style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((s) {
              final isSelected = selectedStatus == s["value"];
              final color = s["color"] as Color;
              return GestureDetector(
                onTap: () => setD(() => selectedStatus = s["value"] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(s["icon"] as IconData, color: color, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        s["label"] as String,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : const Color(0xFF374151),
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(Icons.check, color: color, size: 18),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      setD(() => sending = true);
                      try {
                        await api.reviewPresentation(
                          p["id"],
                          status: selectedStatus,
                          comment: p["comment"],
                        );
                        await loadPresentationsEncadrant();
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Statut mis à jour et notifié à l'étudiant ✅"),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        }
                      } catch (e) {
                        setD(() => sending = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }
}


class CommentaireEncadrantPage extends StatefulWidget {
  final Map rapport;

  const CommentaireEncadrantPage({
    super.key,
    required this.rapport,
  });

  @override
  State<CommentaireEncadrantPage> createState() =>
      _CommentaireEncadrantPageState();
}

class _CommentaireEncadrantPageState
    extends State<CommentaireEncadrantPage> {

  final ApiService api = ApiService();
  final TextEditingController commentCtrl = TextEditingController();

  bool loading = false;

  Future<void> sendComment() async {
    final text = commentCtrl.text.trim();

    if (text.isEmpty) return;

    setState(() => loading = true);

    try {
      await api.reviewRapport(
        widget.rapport["id"],
        {
          "commentaire": text,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Commentaire envoyé"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'envoi"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    final r = widget.rapport;
    final commentaire = r["commentaire"] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),

      appBar: AppBar(
        title: const Text("Commentaire encadrant"),
        backgroundColor: const Color(0xFF0A1F44),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              r["title"] ?? "",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Étudiant: ${r["student"]?["name"] ?? ""}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // ================= OLD COMMENT =================
            if (commentaire.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  commentaire,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),

            // ================= INPUT =================
            TextField(
              controller: commentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Écrire le commentaire de l'encadrant...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // ================= BUTTON =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : sendComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  padding: const EdgeInsets.all(14),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Envoyer",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}