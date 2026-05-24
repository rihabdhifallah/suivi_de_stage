import 'package:flutter/material.dart';
import 'package:frontend/screens/rapports/rapport_detail_page.dart';

class RapportCard extends StatelessWidget {
  final Map r;

  const RapportCard({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
     onTap: () {
  Navigator.pushNamed(
  context,
  '/rapport-detail',
  arguments: r,
);
},
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🟦 TYPE (GRAND)
            Text(
              r["type"] ?? "",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            // 🟪 COMPANY (SMALL)
            Text(
              r["company"] ?? "Entreprise inconnue",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 10),

            const Divider(),

            // 📅 DATE
            Text(
              r["createdAt"] != null
                  ? r["createdAt"].toString().substring(0, 10)
                  : "No date",
              style: const TextStyle(fontSize: 12),
            ),
            Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [

    // ✏️ EDIT
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.black),
      onPressed: () {
        // TODO: edit
        print("EDIT ${r["id"]}");
      },
    ),

    // 🗑 DELETE
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.black),
      onPressed: () {
        // TODO: delete
        print("DELETE ${r["id"]}");
      },
    ),
  ],
),
          ],
        ),
      ),
    );
  }
  
}