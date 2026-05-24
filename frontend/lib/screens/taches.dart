import 'package:flutter/material.dart';
import 'package:frontend/screens/create_tache_page.dart';
import 'package:frontend/services/api_service.dart';

// ── Kanban column definition ──
class KanbanColumn {
  final String status;
  final String label;
  final Color color;
  final Color bg;
  final Color headerBg;
  final IconData icon;
  const KanbanColumn({
    required this.status,
    required this.label,
    required this.color,
    required this.bg,
    required this.headerBg,
    required this.icon,
  });
}

const List<KanbanColumn> kColumns = [
  KanbanColumn(
    status: 'en attente',
    label: 'À faire',
    color: Color(0xFFD97706),   // amber-600
    bg: Color(0xFFFEF3C7),      // amber-100
    headerBg: Color(0xFFFFFBEB),
    icon: Icons.radio_button_unchecked_rounded,
  ),
  KanbanColumn(
    status: 'en cours',
    label: 'En cours',
    color: Color(0xFF2563EB),   // blue-600
    bg: Color(0xFFDBEAFE),      // blue-100
    headerBg: Color(0xFFEFF6FF),
    icon: Icons.timelapse_rounded,
  ),
  KanbanColumn(
    status: 'a tester',
    label: 'À tester',
    color: Color(0xFF0891B2),   // cyan-600
    bg: Color(0xFFCFFAFE),      // cyan-100
    headerBg: Color(0xFFECFEFF),
    icon: Icons.biotech_rounded,
  ),
  KanbanColumn(
    status: 'terminee',
    label: 'Terminé',
    color: Color(0xFF059669),   // emerald-600
    bg: Color(0xFFD1FAE5),      // emerald-100
    headerBg: Color(0xFFECFDF5),
    icon: Icons.check_circle_rounded,
  ),
];

class TachesPage extends StatefulWidget {
  const TachesPage({super.key});
  @override
  State<TachesPage> createState() => _TachesPageState();
}

class _TachesPageState extends State<TachesPage> {
  final ApiService _api = ApiService();
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String _userRole = 'student';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfoAndTasks();
  }

  Future<void> _loadUserInfoAndTasks() async {
    setState(() => _isLoading = true);
    try {
      final role = await _api.storage.read(key: "role") ?? 'student';
      final email = await _api.storage.read(key: "email") ?? '';
      setState(() { _userRole = role; _userEmail = email; });
      await _fetchTasks();
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTasks() async {
    try {
      List<dynamic> list = _userRole == 'student'
          ? await _api.getTasksBySender(_userEmail)
          : await _api.getTasksByReceiver(_userEmail);
      setState(() { _tasks = list; _isLoading = false; });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moveTask(dynamic task, String newStatus) async {
    if (task['status'] == newStatus) return;
    setState(() { task['status'] = newStatus; });
    try {
      await _api.updateTaskStatus(task['id'], newStatus);
      _showSnack('Déplacé vers "${_labelFor(newStatus)}"', const Color(0xFF059669));
    } catch (e) {
      _showSnack("Erreur lors du déplacement", const Color(0xFFDC2626));
      await _fetchTasks();
    }
  }

  String _labelFor(String status) {
    for (final c in kColumns) { if (c.status == status) return c.label; }
    return status;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Group tasks by status ──
  Map<String, List<dynamic>> _groupTasks() {
    final Map<String, List<dynamic>> grouped = { for (final c in kColumns) c.status: [] };
    for (final t in _tasks) {
      final s = (t['status'] ?? 'en attente').toString().toLowerCase().trim();
      if (grouped.containsKey(s)) {
        grouped[s]!.add(t);
      } else if (s == 'terminée' || s == 'validee' || s == 'validée' || s == 'rejetee' || s == 'rejetée') {
        grouped['terminee']!.add(t);
      } else if (s == 'à tester') {
        grouped['a tester']!.add(t);
      } else {
        grouped['en attente']!.add(t);
      }
    }
    return grouped;
  }

  // ── Move dialog — FIXED overflow ──
  void _showMoveDialog(dynamic task) {
    final bool isStudent = _userRole == 'student';
    final currentStatus = task['status']?.toString() ?? 'en attente';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,          // ← fix overflow
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 10),
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
              )),
              const SizedBox(height: 14),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Icon(Icons.drag_indicator_rounded, color: Color(0xFF0A1F44), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['titre'] ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0A1F44)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text("Choisissez la colonne de destination",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              // Scrollable list of columns
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...kColumns.map((col) {
                        final bool isCurrent = currentStatus == col.status;
                        return GestureDetector(
                          onTap: isCurrent ? null : () {
                            Navigator.pop(context);
                            _moveTask(task, col.status);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isCurrent ? col.bg : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent ? col.color : Colors.grey.shade200,
                                width: isCurrent ? 2 : 1,
                              ),
                              boxShadow: isCurrent ? [] : [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: col.bg, borderRadius: BorderRadius.circular(10)),
                                child: Icon(col.icon, color: col.color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(col.label,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isCurrent ? col.color : const Color(0xFF1E293B)))),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: col.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20)),
                                  child: Text("Actuel",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col.color)),
                                )
                              else
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                            ]),
                          ),
                        );
                      }),
                      if (!isStudent) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () { Navigator.pop(context); _openEvalSheet(task); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                            ),
                            child: const Row(children: [
                              Icon(Icons.rate_review_rounded, color: Color(0xFF2563EB), size: 20),
                              SizedBox(width: 12),
                              Text("Évaluer & Commenter",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                            ]),
                          ),
                        ),
                      ],                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Encadrant evaluation sheet — full featured ──
  void _openEvalSheet(dynamic task) {
    final commentCtrl = TextEditingController(text: task['comment'] ?? '');
    final currentStatus = (task['status'] ?? 'en attente').toString().toLowerCase();
    String sel = currentStatus;
    // Pre-select validee if task is terminee
    if (sel == 'terminee' || sel == 'terminée') sel = 'validee';
    // Keep en cours if already en cours
    if (sel != 'validee' && sel != 'rejetee' && sel != 'en cours') sel = 'en cours';

    // Find column for current status display
    KanbanColumn? currentCol;
    for (final c in kColumns) {
      if (c.status == currentStatus) { currentCol = c; break; }
    }
    currentCol ??= kColumns[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  const SizedBox(height: 10),
                  Center(child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10)),
                  )),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.rate_review_rounded,
                          color: Color(0xFF2563EB), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Évaluation de la tâche",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1F44))),
                          Text("Encadrant professionnel",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      )),
                      // Current status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: currentCol!.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: currentCol.color.withValues(alpha: 0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(currentCol.icon, size: 11, color: currentCol.color),
                          const SizedBox(width: 4),
                          Text(currentCol.label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                              color: currentCol.color)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Task info card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task['titre'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                          if ((task['message'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(task['message'].toString(),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                              maxLines: 3, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 5),
                            Text("Étudiant : ${task['sender'] ?? ''}",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                          if ((task['fac_name'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.event_rounded, size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 5),
                              Text("Échéance : ${task['fac_name']}",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Decision buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Décision",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44))),
                        const SizedBox(height: 10),
                        Row(children: [
                          // En cours
                          Expanded(child: _decisionBtn(
                            icon: Icons.timelapse_rounded,
                            label: "En cours",
                            color: const Color(0xFF2563EB),
                            bg: const Color(0xFFDBEAFE),
                            selected: sel == 'en cours',
                            onTap: () => setS(() => sel = 'en cours'),
                          )),
                          const SizedBox(width: 8),
                          // Valider
                          Expanded(child: _decisionBtn(
                            icon: Icons.check_circle_rounded,
                            label: "Valider",
                            color: const Color(0xFF059669),
                            bg: const Color(0xFFD1FAE5),
                            selected: sel == 'validee',
                            onTap: () => setS(() => sel = 'validee'),
                          )),
                          const SizedBox(width: 8),
                          // Rejeter
                          Expanded(child: _decisionBtn(
                            icon: Icons.cancel_rounded,
                            label: "Rejeter",
                            color: const Color(0xFFDC2626),
                            bg: const Color(0xFFFEE2E2),
                            selected: sel == 'rejetee',
                            onTap: () => setS(() => sel = 'rejetee'),
                          )),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comment field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                            size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          const Text("Commentaire pour l'étudiant",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1F44))),
                          const SizedBox(width: 6),
                          Text("(optionnel)",
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ]),
                        const SizedBox(height: 8),
                        TextField(
                          controller: commentCtrl,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Ex: Bon travail, mais vérifiez la partie authentification...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(children: [
                      // Cancel
                      Expanded(child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Annuler",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      )),
                      const SizedBox(width: 12),
                      // Confirm
                      Expanded(flex: 2, child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sel == 'validee'
                              ? const Color(0xFF059669)
                              : sel == 'rejetee'
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          try {
                            await _api.updateTaskStatus(
                              task['id'], sel,
                              comment: commentCtrl.text.trim().isEmpty
                                  ? null
                                  : commentCtrl.text.trim(),
                            );
                            final msg = sel == 'validee'
                                ? "✅ Tâche validée avec succès !"
                                : sel == 'rejetee'
                                    ? "❌ Tâche rejetée."
                                    : "🔄 Tâche mise en cours.";
                            _showSnack(msg,
                              sel == 'validee'
                                  ? const Color(0xFF059669)
                                  : sel == 'rejetee'
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF2563EB));
                            _fetchTasks();
                          } catch (e) {
                            _showSnack("Erreur lors de la mise à jour", const Color(0xFFDC2626));
                            setState(() => _isLoading = false);
                          }
                        },
                        icon: Icon(
                          sel == 'validee'
                              ? Icons.check_circle_rounded
                              : sel == 'rejetee'
                                  ? Icons.cancel_rounded
                                  : Icons.timelapse_rounded,
                          size: 18),
                        label: Text(
                          sel == 'validee' ? "Valider"
                              : sel == 'rejetee' ? "Rejeter"
                              : "Confirmer",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      )),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _decisionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? bg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade400, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? color : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  // ── Kanban card ──
  Widget _kanbanCard(dynamic task, KanbanColumn col) {
    final bool isStudent = _userRole == 'student';
    final String comment = task['comment']?.toString() ?? '';
    final String message = task['message']?.toString() ?? '';
    final String deadline = task['fac_name']?.toString() ?? '';
    final String peer = isStudent
        ? (task['receiver']?.toString() ?? '')
        : (task['sender']?.toString() ?? '');

    return GestureDetector(
      // Étudiant → dialog déplacement | Encadrant → panel évaluation
      onTap: () => isStudent ? _showMoveDialog(task) : _openEvalSheet(task),
      onLongPress: () => isStudent ? null : _showMoveDialog(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top color bar
              Container(height: 3, color: col.color),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + move icon
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(task['titre'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      Icon(Icons.open_with_rounded, size: 13, color: Colors.grey.shade300),
                    ]),
                    // Description
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(message,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    // Deadline
                    if (deadline.isNotEmpty)
                      Row(children: [
                        Icon(Icons.event_rounded, size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(deadline,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ]),
                    const SizedBox(height: 4),
                    // Peer
                    Row(children: [
                      Icon(Icons.person_outline_rounded, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(child: Text(
                        isStudent ? "→ $peer" : "← $peer",
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                        overflow: TextOverflow.ellipsis)),
                    ]),
                    // Comment bubble
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.15)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 11, color: Color(0xFF2563EB)),
                          const SizedBox(width: 5),
                          Expanded(child: Text(comment,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontStyle: FontStyle.italic),
                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Status badge + action hint
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: col.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: col.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(col.icon, size: 10, color: col.color),
                          const SizedBox(width: 4),
                          Text(col.label,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: col.color)),
                        ]),
                      ),
                      // Action hint
                      if (!isStudent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.rate_review_rounded, size: 10, color: Color(0xFF2563EB)),
                            SizedBox(width: 3),
                            Text("Évaluer", style: TextStyle(fontSize: 9,
                              fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ]),
                        )
                      else
                        Icon(Icons.open_with_rounded, size: 13, color: Colors.grey.shade300),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Kanban column widget ──
  Widget _kanbanColumnWidget(KanbanColumn col, List<dynamic> tasks) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: col.headerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: col.color.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: col.bg, borderRadius: BorderRadius.circular(8)),
                child: Icon(col.icon, color: col.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(col.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: col.color))),
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: col.color, shape: BoxShape.circle),
                child: Center(child: Text('${tasks.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          // Empty state
          if (tasks.isEmpty)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 22, color: Colors.grey.shade300),
                  const SizedBox(height: 4),
                  Text("Vide", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              )),
            )
          else
            ...tasks.map((t) => _kanbanCard(t, col)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTasks();
    final int total = _tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
            const Text("Mes Tâches",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            Text("$total tâche${total != 1 ? 's' : ''} au total",
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchTasks,
            tooltip: "Actualiser",
          ),
        ],
      ),

      floatingActionButton: _userRole == 'student'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateTachePage()));
                if (result == true) _fetchTasks();
              },
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text("Nouvelle tâche", style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB))))
          : RefreshIndicator(
              onRefresh: _fetchTasks,
              color: const Color(0xFF2563EB),
              child: Column(
                children: [
                  // ── Legend bar — separated from AppBar with white bg ──
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: kColumns.map((col) {
                          final count = grouped[col.status]?.length ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: col.bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: col.color.withValues(alpha: 0.35)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(col.icon, size: 13, color: col.color),
                              const SizedBox(width: 6),
                              Text("${col.label}  $count",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: col.color)),
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Thin separator
                  Container(height: 1, color: const Color(0xFFE2E8F0)),

                  // ── Kanban board ──
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 4, 100),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: kColumns.map((col) {
                          final colTasks = grouped[col.status] ?? [];
                          return _kanbanColumnWidget(col, colTasks);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
