import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class JournalCreatePage extends StatefulWidget {
  final Map? journal;

  const JournalCreatePage({super.key, this.journal});
  @override
  State<JournalCreatePage> createState() => _JournalCreatePageState();
}

class _JournalCreatePageState extends State<JournalCreatePage> {

  String severity = "mineur";
  String mood = "🙂";
  List<Map<String, String>> difficulties = [];
  List<String> tags = [];

  final tagCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final doneCtrl = TextEditingController();
  final learnedCtrl = TextEditingController();
  final solutionCtrl = TextEditingController();
  final planCtrl = TextEditingController();

  final diffTitleCtrl = TextEditingController();
  final diffDescCtrl = TextEditingController();

 @override
void initState() {
  super.initState();

  if (widget.journal != null) {
    final j = widget.journal!;

    titleCtrl.text = j["title"] ?? "";
    doneCtrl.text = j["tasksDone"] ?? "";
    learnedCtrl.text = j["learned"] ?? "";
    solutionCtrl.text = j["solution"] ?? "";
    planCtrl.text = j["plan"] ?? "";

    mood = j["mood"] ?? "🙂";
    severity = j["severity"] ?? "mineur";

    tags = List<String>.from(j["tags"] ?? []);
    difficulties = List<Map<String, String>>.from(j["difficulties"] ?? []);
  }
}

void addDifficulty() {
  final title = diffTitleCtrl.text.trim();
  final desc = diffDescCtrl.text.trim();

  if (title.isEmpty && desc.isEmpty) return;

  setState(() {
    difficulties.add({
      "title": title,
      "desc": desc,
    });
  });

  print("DIFFICULTIES => $difficulties"); // 

  diffTitleCtrl.clear();
  diffDescCtrl.clear();
}
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
  void addTag() {
  final tag = tagCtrl.text.trim();

  if (tag.isEmpty) return;

  setState(() {
    tags.add(tag);
  });

  tagCtrl.clear();
}

  Widget _input(TextEditingController c, String hint, {int max = 3}) {
    return TextField(
      controller: c,
      maxLines: max,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
      ),
    );
  }

 Widget _emoji(String e, String label) {
  bool selected = mood == e;

  return GestureDetector(
    onTap: () => setState(() => mood = e),
    child: Container(
      width: 85,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Colors.blue : Colors.grey.shade300,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _severityBtn(String value, String label, Color color) {
    bool selected = severity == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => severity = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
Future save() async {
  final body = {
    "mood": mood,
    "title": titleCtrl.text.trim(),
    "tasksDone": doneCtrl.text.trim(),
    "learned": learnedCtrl.text.trim(),
    "solution": solutionCtrl.text.trim(),
    "plan": planCtrl.text.trim(),
    "severity": severity,
    "tags": tags,
    "difficulties": difficulties,
  };

  try {
    if (widget.journal == null) {
      await ApiService().sendJournal(body);
    } else {
      final id = widget.journal!["id"] ?? widget.journal!["_id"];
      await ApiService().updateJournal(id, body);
    }

    Navigator.pop(context, true);
  } catch (e) {
    print("ERROR SAVE: $e");
  }
}
@override
Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      appBar: AppBar(
        title: const Text("Journal de bord"),
        backgroundColor: const Color(0xFF0A1F44),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= EMOJIS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _emoji("🙂", "Bien"),
                _emoji("😐", "Moyen"),
                _emoji("😫", "Difficile"),
                _emoji("😄", "Excellent"),
              ],
            ),

            const SizedBox(height: 15),

            // ================= TITLE =================
            const Text("Titre de la journée",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _card(child: _input(titleCtrl, "Ex: Module login")),

            const SizedBox(height: 15),

            // ================= TASKS =================
            const Text("Ce que j'ai fait aujourd'hui",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _card(child: _input(doneCtrl, "Tâches...", max: 4)),

            Align(
              alignment: Alignment.centerRight,
              child: Text("${doneCtrl.text.length}/600",
                  style: const TextStyle(color: Colors.grey)),
            ),

            const SizedBox(height: 15),

            // ================= LEARNED =================
            const Text("Ce que j'ai appris",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _card(child: _input(learnedCtrl, "Apprentissages")),

          // ================= DIFFICULTÉS SECTION =================
const SizedBox(height: 20),

const Text(
  "Difficultés rencontrées",
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),

const SizedBox(height: 12),

// ========== CARD 1: TITLE ==========
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Titre du problème",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
_input(diffTitleCtrl, "Ex: Bug API login", max: 2),
    ],
  ),
),

const SizedBox(height: 12),

// ========== CARD 2: DESCRIPTION ==========
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Description du problème",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
_input(diffDescCtrl, "Décris le problème...", max: 4),    ],
  ),
),

const SizedBox(height: 12),

// ========== SEVERITY ==========
const Text(
  "Niveau de gravité",
  style: TextStyle(fontWeight: FontWeight.bold),
),

const SizedBox(height: 10),

Row(
  children: [
    _severityBtn("mineur", "Mineur", Colors.green),
    _severityBtn("moyen", "Moyen", Colors.orange),
    _severityBtn("bloquant", "Bloquant", Colors.red),
  ],
),

const SizedBox(height: 12),

// ========== ADD BUTTON ==========
GestureDetector(
  onTap: addDifficulty, // 👈 هذا المهم
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add, color: Colors.blue),
        SizedBox(width: 6),
        Text(
          "Ajouter une difficulté",
          style: TextStyle(color: Colors.blue),
        ),
      ],
    ),
  ),
),

            const SizedBox(height: 15),

            // ================= SOLUTION =================
            const Text("Solution"),
            const SizedBox(height: 8),
            _card(child: _input(solutionCtrl, "Solution")),

            const SizedBox(height: 15),

            // ================= PLAN =================
            const Text("Plan demain"),
            const SizedBox(height: 8),
            _card(child: _input(planCtrl, "Plan")),

            const SizedBox(height: 20),

const Text(
  "Tags",
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),

const SizedBox(height: 10),

_card(
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: tagCtrl,
          decoration: const InputDecoration(
            hintText: "Ex: Flutter, API...",
            border: InputBorder.none,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add, color: Colors.blue),
        onPressed: addTag,
      )
    ],
  ),
),
const SizedBox(height: 10),

Wrap(
  spacing: 8,
  children: tags.map((tag) {
    return Chip(
      label: Text(tag),
      deleteIcon: const Icon(Icons.close),
      onDeleted: () {
        setState(() {
          tags.remove(tag);
        });
      },
    );
  }).toList(),
),

            const SizedBox(height: 20),

            // ================= SAVE =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}