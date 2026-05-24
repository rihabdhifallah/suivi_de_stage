import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
//  PAGE SOUMISSION  (PresentationsPage)
// ─────────────────────────────────────────────────────────────
class PresentationsPage extends StatefulWidget {
  const PresentationsPage({super.key});

  @override
  State<PresentationsPage> createState() => _PresentationsPageState();
}

class _PresentationsPageState extends State<PresentationsPage> {
  final titreCtrl = TextEditingController();

  String resultName = "";
  String? selectedType;
  DateTime? selectedDate;
  PlatformFile? file;

  String encadrant = "";
  String encadrantEmail = "";
  String etablissement = "";

  @override
  void initState() {
    super.initState();
    loadAdvisor();
  }

  Future loadAdvisor() async {
    try {
      final token = await ApiService().storage.read(key: "token");
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${Config.baseUrl}/encadrements/my'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final e = list.first;
          setState(() {
            encadrant = "${e["encadrant"]?["name"] ?? ''} ${e["encadrant"]?["prenom"] ?? ''}".trim();
            encadrantEmail = e["encadrant"]?["email"] ?? '';
            etablissement = e["encadrant"]?["etablissement"] ?? e["niveau"] ?? 'Académique';
          });
        }
      }
    } catch (e) {
      print("Erreur chargement encadrant: $e");
    }
  }

  List<String> types = [
    "Présentation mi-stage",
    "Finale PFE",
    "Soutenance",
    "Hebdomadaire"
  ];

  Future pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx'],
      allowMultiple: false,
      withData: true,
    );

    if (result != null) {
      final pickedFile = result.files.first;
      final fileName = pickedFile.name;
      final sizeBytes = pickedFile.size;
      final sizeMB = sizeBytes / (1024 * 1024);

      if (sizeMB > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Max 20MB")),
        );
        return;
      }

      setState(() {
        file = pickedFile;
        resultName = fileName;
      });
    }
  }

  Future pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() { selectedDate = date; });
    }
  }

  bool get isFormValid {
    return titreCtrl.text.isNotEmpty &&
        selectedType != null &&
        file != null &&
        selectedDate != null;
  }

  void submit() async {
    if (!isFormValid) return;
    try {
      await ApiService().sendPresentation(
        titre: titreCtrl.text,
        type: selectedType!,
        date: selectedDate!,
        file: file!,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PresentationDetailPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Présentation envoyée ✅"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        titreCtrl.clear();
        selectedType = null;
        selectedDate = null;
        file = null;
        resultName = "";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Soumettre présentation",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "Historique des présentations",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PresentationDetailPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encadrant card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: encadrant.isEmpty
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, color: Colors.orange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Chargement de votre encadrant...",
                            style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFF97316).withOpacity(0.1),
                          child: Text(
                            encadrant.isNotEmpty
                                ? encadrant.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
                                : 'EA',
                            style: const TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ENCADRANT ACADÉMIQUE",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                encadrant,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
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
                                      encadrantEmail,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
            ),

            const SizedBox(height: 20),

            const Text("Titre", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: titreCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Titre de présentation",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text("Choisir type"),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() { selectedType = v; }),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Fichier présentation", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: file == null ? Colors.white.withOpacity(0.7) : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: file == null ? Colors.grey.shade300 : Colors.green),
                ),
                child: Column(
                  children: [
                    Icon(
                      file == null ? Icons.computer : Icons.check_circle,
                      size: 55,
                      color: file == null ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      resultName.isEmpty ? "Importer présentation" : resultName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: resultName.isEmpty ? Colors.black : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "PDF / PPT / PPTX • max 20MB",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Date de soutenance", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? "Choisir une date"
                          : DateFormat("yyyy-MM-dd").format(selectedDate!),
                    ),
                    const Icon(Icons.calendar_month),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFormValid ? submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Envoyer", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAGE DETAIL PRÉSENTATIONS  (PresentationDetailPage)
// ─────────────────────────────────────────────────────────────
class PresentationDetailPage extends StatefulWidget {
  const PresentationDetailPage({super.key});

  @override
  State<PresentationDetailPage> createState() => _PresentationDetailPageState();
}

class _PresentationDetailPageState extends State<PresentationDetailPage> {
  final api = ApiService();
  List presentations = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future load() async {
    setState(() => loading = true);
    try {
      final data = await api.getMyPresentations();
      setState(() { presentations = data; loading = false; });
    } catch (e) {
      setState(() { presentations = []; loading = false; });
    }
  }

  // ── Status config ──
  Map<String, dynamic> _statusInfo(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'valide':
      case 'accepted':
        return {
          'label': 'Validé',
          'color': const Color(0xFF16A34A),
          'bg': const Color(0xFFF0FDF4),
          'border': const Color(0xFFBBF7D0),
          'icon': Icons.check_circle_rounded,
          'bar': const Color(0xFF16A34A),
          'msg': "Félicitations ! Votre présentation a été validée par votre encadrant.",
        };
      case 'refuse':
      case 'refusé':
        return {
          'label': 'Refusé',
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEF2F2),
          'border': const Color(0xFFFECACA),
          'icon': Icons.cancel_rounded,
          'bar': const Color(0xFFDC2626),
          'msg': "Votre présentation a été refusée. Consultez le commentaire de votre encadrant ci-dessous.",
        };
      case 'revision':
        return {
          'label': 'En révision',
          'color': const Color(0xFF2563EB),
          'bg': const Color(0xFFEFF6FF),
          'border': const Color(0xFFBFDBFE),
          'icon': Icons.autorenew_rounded,
          'bar': const Color(0xFF2563EB),
          'msg': "Des modifications sont demandées. Veuillez revoir votre présentation selon les remarques de votre encadrant.",
        };
      default:
        return {
          'label': 'En attente',
          'color': const Color(0xFFF97316),
          'bg': const Color(0xFFFFF7ED),
          'border': const Color(0xFFFED7AA),
          'icon': Icons.schedule_rounded,
          'bar': const Color(0xFFF97316),
          'msg': "Votre présentation est en cours d'examen par votre encadrant.",
        };
    }
  }

  // ── Stats banner ──
  Widget _buildSummaryBanner() {
    final total = presentations.length;
    final valide = presentations.where((p) => p['status'] == 'valide').length;
    final revision = presentations.where((p) => p['status'] == 'revision').length;
    final refuse = presentations.where((p) => p['status'] == 'refuse').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1F44), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1F44).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(total.toString(), "Total", Colors.white),
          _vDiv(),
          _statItem(valide.toString(), "Validé", const Color(0xFF4ADE80)),
          _vDiv(),
          _statItem(revision.toString(), "Révision", const Color(0xFF60A5FA)),
          _vDiv(),
          _statItem(refuse.toString(), "Refusé", const Color(0xFFF87171)),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _vDiv() => Container(height: 36, width: 1, color: Colors.white.withOpacity(0.2));

  // ── Card ──
  Widget _buildCard(dynamic p) {
    final fileStr = (p["file"] ?? "").toString();
    final lowerFile = fileStr.toLowerCase();
    final bool hasFile = fileStr.isNotEmpty && fileStr != "no-file";
    final bool isPdf = lowerFile.endsWith(".pdf");
    final bool isPpt = lowerFile.endsWith(".ppt") || lowerFile.endsWith(".pptx");
    final String displayFileName = fileStr.contains('-')
        ? fileStr.substring(fileStr.indexOf('-') + 1)
        : fileStr;

    final status = (p["status"] ?? "en_attente").toString();
    final info = _statusInfo(status);
    final Color statusColor = info['color'] as Color;
    final Color statusBg = info['bg'] as Color;
    final Color statusBorder = info['border'] as Color;
    final IconData statusIcon = info['icon'] as IconData;
    final String statusLabel = info['label'] as String;
    final Color barColor = info['bar'] as Color;
    final String statusMsg = info['msg'] as String;

    final String rawComment = (p["comment"] ?? "").toString().trim();
    final String? comment = rawComment.isEmpty ? null : rawComment;

    final String dateStr = (p["date"] ?? "").toString();
    final String dateDisplay = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored top bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type + Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p["type"] ?? "Présentation",
                        style: const TextStyle(
                          color: Color(0xFF0A1F44),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title
                Text(
                  p["titre"] ?? "Sans titre",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Soutenance : $dateDisplay",
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Status message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusMsg,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Encadrant comment
                if (comment != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_rounded, size: 13, color: Color(0xFFB45309)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Commentaire de l'encadrant",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            comment,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF78350F),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // File
                if (hasFile) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse("${Config.baseUrl}/uploads/$fileStr");
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(url);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Impossible d'ouvrir : $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isPdf
                            ? const Color(0xFFFEF2F2)
                            : isPpt
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPdf
                              ? const Color(0xFFFECACA)
                              : isPpt
                                  ? const Color(0xFFFED7AA)
                                  : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPdf
                                  ? Colors.red.withOpacity(0.1)
                                  : isPpt
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf_rounded
                                  : isPpt
                                      ? Icons.slideshow_rounded
                                      : Icons.insert_drive_file_rounded,
                              color: isPdf
                                  ? Colors.red.shade700
                                  : isPpt
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayFileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isPdf
                                        ? Colors.red.shade800
                                        : isPpt
                                            ? Colors.orange.shade800
                                            : Colors.blue.shade800,
                                  ),
                                ),
                                Text(
                                  isPdf ? "Document PDF" : isPpt ? "Diaporama" : "Fichier",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: isPdf
                                ? Colors.red.shade600
                                : isPpt
                                    ? Colors.orange.shade600
                                    : Colors.blue.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/student-dashboard');
            }
          },
        ),
        title: const Text(
          "Mes Présentations",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: load,
            tooltip: "Actualiser",
          ),
        ],
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0A1F44)),
                  const SizedBox(height: 16),
                  Text("Chargement...", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : presentations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1F44).withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.slideshow_rounded, size: 64, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Aucune présentation",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Vos présentations apparaîtront ici\naprès soumission.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text("Soumettre une présentation"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1F44),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSummaryBanner()),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildCard(presentations[i]),
                          childCount: presentations.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}