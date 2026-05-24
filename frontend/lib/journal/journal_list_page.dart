import 'package:flutter/material.dart';
import 'package:frontend/journal/journal_create_page.dart';
import 'package:frontend/journal/journal_detail_page.dart';
import 'package:frontend/services/api_service.dart';

class JournalListPage extends StatefulWidget {
  const JournalListPage({super.key});

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
List<dynamic> journals = [];

  final api = ApiService();

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  
 Future load() async {
  try {
    final data = await api.getJournal();

    setState(() {
      journals = data.where((j) => j != null).toList();
    });
  } catch (e) {
    print("ERROR LOAD JOURNAL: $e");
  }
}
  // ================= CHIP =================
  Widget _chip(String text, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.blue,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ================= MINI INFO =================
  Widget _miniInfo(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  // ================= TOP CARD =================
  Widget _topCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0A1F44)),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        toolbarHeight: 140,
        automaticallyImplyLeading: false,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Journal de bord",
                style: TextStyle(color: Colors.white)),
            SizedBox(height: 6),
            Text("Étudiant: ",
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
  final result = await Navigator.pushNamed(
    context,
    "/journal/create",
  );

  print("RESULT = $result"); //  

  if (result == true) {
    await load(); //  
  }
}
          )
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [

          const SizedBox(height: 12),

          // TOP CARDS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _topCard("Entrer", Icons.edit)),
                const SizedBox(width: 10),
                Expanded(child: _topCard("Difficultés", Icons.warning)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // CHIPS
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip("Toutes", 0),
                _chip("Cette semaine", 1),
                _chip("Difficultés", 2),
                _chip("Résolues", 3),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // NEW ENTRY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/journal/create");
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("➕ Nouvelle entrée",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1F44),
                        )),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // LIST
Expanded(
  child: ListView.builder(
    itemCount: journals.length,
    itemBuilder: (context, i) {
      final j = journals[i];

      return journalCard(j); // 
    },
  ),
),
],
),
);
  }
  
  Widget journalCard(dynamic j) {
  final date = DateTime.parse(j["createdAt"]);

  final List tags = (j["tags"] ?? []) as List;

  final List difficulties = (j["difficulties"] ?? []) as List;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JournalDetailPage(journal: j),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // DATE + MOOD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${date.day}/${date.month}/${date.year}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(j["mood"] ?? "🙂"),
            ],
          ),

          const SizedBox(height: 10),

          // TITLE
          Text(
            (j["title"] ?? "Sans titre").toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // TASKS
          Text(
            (j["tasksDone"] ?? "Aucune tâche").toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 10),

          // TAGS FIXED
          if (tags.isNotEmpty)
            Wrap(
              spacing: 6,
              children: tags.map((t) {
                return Chip(
                  label: Text(t.toString()),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          const Divider(),

          // DIFFICULTIES
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              Text("${difficulties.length} difficulté(s)"),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              // EDIT
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalCreatePage(journal: j),
                    ),
                  );
                },
              ),

              // DELETE
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final ok = await api.deleteJournal(j["id"]);

                  if (ok) {
                    await load();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Journal supprimé")),
                    );
                  }
                },
              ),
            ],
          )
        ],
      ),
    ),
  );
}
}