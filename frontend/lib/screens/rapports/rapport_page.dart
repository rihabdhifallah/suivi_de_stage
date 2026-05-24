import 'package:flutter/material.dart';
import 'package:frontend/screens/rapports/rapport_detail_page.dart';
import '../../services/api_service.dart';
import 'create_rapport_page.dart';

class RapportPage extends StatefulWidget {
  const RapportPage({super.key});

  @override
  State<RapportPage> createState() => _RapportPageState();
}

class _RapportPageState extends State<RapportPage> {
  final api = ApiService();
  List rapports = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future load() async {
    setState(() => loading = true);

    final data = await api.getReports();

    if (!mounted) return;

    setState(() {
      rapports = data is List ? data : [];
      loading = false;
    });
  }

  int countByType(String type) {
    return rapports.where((r) => r["type"] == type).length;
  }

  void openDetails(dynamic r) async {
  final res = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RapportDetailPage(rapport: r),
    ),
  );

  if (res == true) {
    await load();
  }
}

  @override
  Widget build(BuildContext context) {
    final soumis = countByType("mi-stage");
    final finals = countByType("final");

    return Scaffold(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mes Rapports",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            Text("${rapports.length} rapport${rapports.length != 1 ? 's' : ''}",
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () async {
              final res = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => CreateRapportPage(editData: null)));
              if (res == true) await load();
            },
            tooltip: "Nouveau rapport",
          ),
          const SizedBox(width: 4),
        ],
      ),

      backgroundColor: const Color(0xFFF0F4FF),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3C8F)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              children: [
                // ── Stat cards ──
                Row(children: [
                  _statCard("Mi-stage", soumis, const Color(0xFF1A3C8F), Icons.assignment_outlined),
                  const SizedBox(width: 12),
                  _statCard("Final", finals, const Color(0xFF059669), Icons.task_alt_rounded),
                ]),
                const SizedBox(height: 20),

                // ── New rapport button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3C8F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final res = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CreateRapportPage(editData: null)));
                      if (res == true) await load();
                    },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text("Nouveau rapport",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section title ──
                Row(children: [
                  Container(width: 3, height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3C8F),
                      borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 10),
                  const Text("Mes rapports",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B4B))),
                ]),
                const SizedBox(height: 12),

                // ── Rapport cards ──
                if (rapports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A3C8F).withValues(alpha: 0.07),
                            shape: BoxShape.circle),
                          child: const Icon(Icons.description_outlined,
                            size: 48, color: Color(0xFF1A3C8F))),
                        const SizedBox(height: 16),
                        const Text("Aucun rapport",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B4B))),
                        const SizedBox(height: 6),
                        const Text("Créez votre premier rapport de stage",
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7A99))),
                      ],
                    ),
                  )
                else
                  ...rapports.map((r) => RapportCard(
                    r: r,
                    onTap: () => openDetails(r),
                    onEdit: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RapportDetailPage(rapport: r))),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text("Supprimer le rapport ?"),
                          content: const Text("Cette action est irréversible."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false),
                              child: const Text("Annuler")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red, foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Supprimer")),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await api.deleteReport(r["id"]);
                        await load();
                      }
                    },
                  )),
              ],
            ),
    );
  }

  Widget _statCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("$count", style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(
              fontSize: 12, color: Color(0xFF6B7A99))),
          ]),
        ]),
      ),
    );
  }
}



class RapportCard extends StatelessWidget {
  final dynamic r;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RapportCard({
    super.key,
    required this.r,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  // ================= STATUS COLORS =================
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "valide":
        return Colors.green;
      case "refuse":
        return Colors.red;
      case "revision":
        return Colors.blue;
      default:
        return Colors.orange; // en attente
    }
  }

  String formatDate(dynamic date) {
    if (date == null) return "—";
    return date.toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final status = (r["status"] ?? "en_attente").toString();
    final statusColor = getStatusColor(status);
    final statusLabel = _statusLabel(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4EAF8)),
          boxShadow: [BoxShadow(
            color: const Color(0xFF1A3C8F).withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top color bar
            Container(height: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
                  Row(children: [
                    Expanded(child: Text(r["title"] ?? "Sans titre",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B4B)),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                      child: Text(statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                          color: statusColor))),
                  ]),
                  const SizedBox(height: 8),
                  // Type + company
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3C8F).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(r["type"] ?? "—",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3C8F)))),
                    if ((r["company"] ?? "").toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.business_outlined, size: 12, color: Color(0xFF6B7A99)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(r["company"].toString(),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7A99)),
                        overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE4EAF8)),
                  const SizedBox(height: 8),
                  // Date + actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF6B7A99)),
                        const SizedBox(width: 5),
                        Text(formatDate(r["createdAt"]),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A99))),
                      ]),
                      Row(children: [
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A3C8F), size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: "Modifier"),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: "Supprimer"),
                      ]),
                    ],
                  ),
                  // Comment if exists
                  if ((r["commentaire"] ?? "").toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1A3C8F).withValues(alpha: 0.15))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 13,
                          color: Color(0xFF1A3C8F)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r["commentaire"].toString(),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1A3C8F),
                            fontStyle: FontStyle.italic),
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case "valide":   return "Validé";
      case "refuse":   return "Refusé";
      case "revision": return "Révision";
      default:         return "En attente";
    }
  }
}