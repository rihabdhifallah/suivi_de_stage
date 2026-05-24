import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/admin_theme.dart';

class ArchivedActorsPage extends StatefulWidget {
  final int initialTab;
  const ArchivedActorsPage({super.key, this.initialTab = 0});

  @override
  State<ArchivedActorsPage> createState() => _ArchivedActorsPageState();
}

class _ArchivedActorsPageState extends State<ArchivedActorsPage> with SingleTickerProviderStateMixin {
  final api = ApiService();
  late TabController _tabController;

  List archivedStudents = [];
  List archivedAcademiques = [];
  List archivedCompanies = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadAllArchived();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllArchived() async {
    setState(() => loading = true);
    try {
      final students = await api.getStudents();
      final academiques = await api.getAcademiques();
      final companies = await api.getCompanies2();

      setState(() {
        archivedStudents = students.where((s) => s['status'] == 'archived').toList();
        archivedAcademiques = academiques.where((a) => a['status'] == 'archived').toList();
        archivedCompanies = companies.where((c) => c['status'] == 'archived').toList();
      });
    } catch (e) {
      AdminTheme.snack(context, "Erreur lors du chargement: $e", error: true);
    }
    setState(() => loading = false);
  }

  void _confirmRestore(Map item, String type) {
    final String name = type == 'company' 
        ? (item['nom'] ?? 'Entreprise') 
        : '${item['prenom'] ?? ''} ${item['name'] ?? ''}'.trim();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusLg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AdminTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.unarchive_outlined, color: AdminTheme.success, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Désarchiver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Voulez-vous restaurer "$name" ? Cet acteur pourra à nouveau se connecter au système.', style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
              side: const BorderSide(color: AdminTheme.border),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusMd)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              _restoreActor(item['id'], type, name);
            },
            child: const Text('Restaurer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreActor(int id, String type, String name) async {
    setState(() => loading = true);
    try {
      if (type == 'company') {
        await api.archiveCompany(id);
      } else {
        await api.archiveUser(id);
      }
      AdminTheme.snack(context, "✅ $name restauré avec succès!");
      _loadAllArchived();
    } catch (e) {
      AdminTheme.snack(context, "Erreur lors de la restauration: $e", error: true);
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      appBar: AdminTheme.appBar(
        title: 'Acteurs Archivés',
        subtitle: 'Restaurer les étudiants, encadrants ou entreprises',
        showBack: true,
        context: context,
      ),
      body: Column(
        children: [
          Container(
            color: AdminTheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.school_outlined, size: 20),
                  text: 'Étudiants (${archivedStudents.length})',
                ),
                Tab(
                  icon: const Icon(Icons.person_outlined, size: 20),
                  text: 'Académiques (${archivedAcademiques.length})',
                ),
                Tab(
                  icon: const Icon(Icons.business_outlined, size: 20),
                  text: 'Entreprises (${archivedCompanies.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildArchivedList(archivedStudents, 'student'),
                      _buildArchivedList(archivedAcademiques, 'academique'),
                      _buildArchivedList(archivedCompanies, 'company'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedList(List items, String type) {
    if (items.isEmpty) {
      IconData icon = Icons.archive_outlined;
      String msg = 'Aucun élément archivé';
      if (type == 'student') {
        icon = Icons.school_outlined;
        msg = 'Aucun étudiant archivé';
      } else if (type == 'academique') {
        icon = Icons.person_outlined;
        msg = 'Aucun encadrant académique archivé';
      } else if (type == 'company') {
        icon = Icons.business_outlined;
        msg = 'Aucune entreprise archivée';
      }
      return AdminTheme.emptyState(
        icon: icon,
        message: msg,
        sub: 'Tous les acteurs de cette catégorie sont actifs.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllArchived,
      color: AdminTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final String name = type == 'company' 
              ? (item['nom'] ?? 'Entreprise') 
              : '${item['prenom'] ?? ''} ${item['name'] ?? ''}'.trim();
          final String email = item['email'] ?? '';
          
          String subtext = '';
          IconData leadingIcon = Icons.person;
          Color accentColor = AdminTheme.primary;

          if (type == 'student') {
            final level = item['niveau']?.toString() ?? '';
            final spec = item['specialite']?.toString() ?? '';
            subtext = [level, spec].where((e) => e.isNotEmpty).join(' · ');
            leadingIcon = Icons.school_outlined;
            accentColor = AdminTheme.primary;
          } else if (type == 'academique') {
            final dept = item['departement']?.toString() ?? '';
            final spec = item['specialite']?.toString() ?? '';
            subtext = [dept, spec].where((e) => e.isNotEmpty).join(' · ');
            leadingIcon = Icons.assignment_ind_outlined;
            accentColor = AdminTheme.warning;
          } else if (type == 'company') {
            subtext = item['secteurActivite']?.toString() ?? '';
            leadingIcon = Icons.business_outlined;
            accentColor = AdminTheme.teal;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AdminTheme.cardBg,
              borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
              border: Border.all(color: AdminTheme.divider),
              boxShadow: AdminTheme.cardShadow,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: accentColor.withOpacity(0.1),
                child: Icon(leadingIcon, color: accentColor, size: 20),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AdminTheme.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(email, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary)),
                  if (subtext.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtext, style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary, fontWeight: FontWeight.w500)),
                  ]
                ],
              ),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.success.withOpacity(0.1),
                  foregroundColor: AdminTheme.success,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                    side: BorderSide(color: AdminTheme.success.withOpacity(0.3)),
                  ),
                ),
                onPressed: () => _confirmRestore(item, type),
                icon: const Icon(Icons.unarchive_outlined, size: 14),
                label: const Text(
                  'Restaurer',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
